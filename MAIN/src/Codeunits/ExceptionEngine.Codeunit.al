namespace SupplyChain.ExceptionAgent;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 50301 "SCAExceptionEngine"
{
    Access = Public;
    Permissions =
        tabledata Item = r,
        tabledata "Purchase Header" = r,
        tabledata "Purchase Line" = r,
        tabledata "Sales Header" = r,
        tabledata "Sales Line" = r,
        tabledata "SCAAnalysisHeader" = rim,
        tabledata "SCAExceptionLine" = rim;

    procedure RunFullScan(ShowResult: Boolean): Integer
    var
        AnalysisHeader: Record "SCAAnalysisHeader";
        Setup: Record "SCASetup";
    begin
        SetupMgt.GetSetup(Setup);
        SetupMgt.ValidateSetup(Setup);

        CreateAnalysisHeader(AnalysisHeader, AnalysisHeader.Scope::"Full Scan", '');
        ScanSalesDemand(AnalysisHeader, Setup, '');
        if not AnalysisHeader."Was Truncated" then
            ScanOverduePurchaseSupply(AnalysisHeader, Setup);
        FinalizeAnalysis(AnalysisHeader);

        if ShowResult then
            Page.Run(Page::"SCAAnalysisCard", AnalysisHeader);

        exit(AnalysisHeader."Entry No.");
    end;

    procedure AnalyzeSalesOrder(var SalesHeader: Record "Sales Header"; ShowResult: Boolean): Integer
    var
        AnalysisHeader: Record "SCAAnalysisHeader";
        Setup: Record "SCASetup";
    begin
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Order);
        SetupMgt.GetSetup(Setup);
        SetupMgt.ValidateSetup(Setup);

        CreateAnalysisHeader(AnalysisHeader, AnalysisHeader.Scope::"Sales Order", SalesHeader."No.");
        ScanSalesDemand(AnalysisHeader, Setup, SalesHeader."No.");
        FinalizeAnalysis(AnalysisHeader);

        if ShowResult then
            Page.Run(Page::"SCAAnalysisCard", AnalysisHeader);

        exit(AnalysisHeader."Entry No.");
    end;

    procedure GetLatestAnalysis(Scope: Enum "SCAScanScope"; SourceDocumentNo: Code[20]; var AnalysisHeader: Record "SCAAnalysisHeader"): Boolean
    begin
        AnalysisHeader.Reset();
        AnalysisHeader.SetRange(Scope, Scope);
        if SourceDocumentNo <> '' then
            AnalysisHeader.SetRange("Source Document No.", SourceDocumentNo);
        AnalysisHeader.SetCurrentKey("Entry No.");
        exit(AnalysisHeader.FindLast());
    end;

    local procedure CreateAnalysisHeader(var AnalysisHeader: Record "SCAAnalysisHeader"; Scope: Enum "SCAScanScope"; SourceDocumentNo: Code[20])
    var
        Setup: Record "SCASetup";
    begin
        SetupMgt.GetSetup(Setup);

        AnalysisHeader.Init();
        AnalysisHeader.Scope := Scope;
        AnalysisHeader."Source Document No." := SourceDocumentNo;
        AnalysisHeader."Analysis Date" := WorkDate();
        AnalysisHeader."Horizon End Date" := CalcDate(StrSubstNo(AddDaysDateFormulaLbl, Setup."Horizon Days"), WorkDate());
        AnalysisHeader.Status := AnalysisHeader.Status::Open;
        AnalysisHeader."Highest Risk Level" := AnalysisHeader."Highest Risk Level"::Low;
        AnalysisHeader."Analyzed At" := CurrentDateTime();
        AnalysisHeader."Analyzed By" := UserSecurityId();
        AnalysisHeader.Insert(true);
    end;

    local procedure ScanSalesDemand(var AnalysisHeader: Record "SCAAnalysisHeader"; Setup: Record "SCASetup"; SalesOrderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        IncludeLine: Boolean;
        NeedDate: Date;
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("No.", '<>%1', '');
        SalesLine.SetFilter("Outstanding Qty. (Base)", '>%1', 0);
        if SalesOrderNo <> '' then
            SalesLine.SetRange("Document No.", SalesOrderNo);

        if not SalesLine.FindSet() then
            exit;

        repeat
            if AnalysisHeader."Exception Count" >= Setup."Maximum Exceptions Per Scan" then begin
                AnalysisHeader."Was Truncated" := true;
                exit;
            end;

            if SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
                if IsSalesHeaderIncluded(SalesHeader, Setup) then begin
                    IncludeLine := true;
                    OnShouldIncludeSalesDemand(SalesHeader, SalesLine, IncludeLine);
                    if IncludeLine then begin
                        NeedDate := ResolveDemandDate(SalesHeader, SalesLine);
                        if (NeedDate = 0D) or (NeedDate <= AnalysisHeader."Horizon End Date") then
                            AnalyzeSalesDemandLine(AnalysisHeader, Setup, SalesHeader, SalesLine, NeedDate);
                    end;
                end;
        until SalesLine.Next() = 0;
    end;

    local procedure AnalyzeSalesDemandLine(
        var AnalysisHeader: Record "SCAAnalysisHeader";
        Setup: Record "SCASetup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NeedDate: Date)
    var
        ExceptionLine: Record "SCAExceptionLine";
        HasAnyDatedPurchaseSupply: Boolean;
        HasException: Boolean;
        HasOverduePurchaseSupply: Boolean;
        NextPurchaseOrderNo: Code[20];
        NextVendorNo: Code[20];
        OverduePurchaseOrderNo: Code[20];
        OverdueVendorNo: Code[20];
        NextInboundDate: Date;
        OverdueExpectedReceiptDate: Date;
        AdditionalSupply: Decimal;
        CumulativeDemand: Decimal;
        CurrentInventory: Decimal;
        ProjectedAvailability: Decimal;
        PurchaseSupplyByNeedDate: Decimal;
        ShortagePct: Decimal;
        ShortageQty: Decimal;
        ExceptionType: Enum "SCAExceptionType";
        RiskLevel: Enum "SCARiskLevel";
        DaysPastDue: Integer;
    begin
        CurrentInventory := GetCurrentInventoryBase(SalesLine."No.", SalesLine."Location Code", SalesLine."Variant Code");
        CumulativeDemand := CalculateCumulativeDemandBase(SalesLine, NeedDate, Setup);
        PurchaseSupplyByNeedDate :=
            CalculatePurchaseSupplyBase(
                SalesLine."No.",
                SalesLine."Location Code",
                SalesLine."Variant Code",
                NeedDate,
                Setup,
                NextInboundDate,
                NextPurchaseOrderNo,
                NextVendorNo,
                OverduePurchaseOrderNo,
                OverdueVendorNo,
                OverdueExpectedReceiptDate,
                HasAnyDatedPurchaseSupply,
                HasOverduePurchaseSupply);

        AdditionalSupply := 0;
        OnCalculateAdditionalSupplyBase(SalesHeader, SalesLine, NeedDate, AdditionalSupply);

        ProjectedAvailability := CurrentInventory + PurchaseSupplyByNeedDate + AdditionalSupply - CumulativeDemand;
        if ProjectedAvailability < 0 then
            ShortageQty := -ProjectedAvailability
        else
            ShortageQty := 0;

        DaysPastDue := GetDaysPastDue(NeedDate);
        if CumulativeDemand <> 0 then
            ShortagePct := (ShortageQty / Abs(CumulativeDemand)) * 100;

        HasException :=
            DetermineDemandException(
                Setup,
                NeedDate,
                DaysPastDue,
                ShortageQty,
                ShortagePct,
                NextInboundDate,
                HasAnyDatedPurchaseSupply,
                HasOverduePurchaseSupply,
                ExceptionType,
                RiskLevel);

        if not HasException then
            exit;

        ExceptionLine.Init();
        ExceptionLine."Analysis Entry No." := AnalysisHeader."Entry No.";
        ExceptionLine."Line No." := GetNextLineNo(AnalysisHeader."Entry No.");
        ExceptionLine."Exception Type" := ExceptionType;
        ExceptionLine."Risk Level" := RiskLevel;
        ExceptionLine."Item No." := SalesLine."No.";
        ExceptionLine.Description := CopyStr(SalesLine.Description, 1, MaxStrLen(ExceptionLine.Description));
        ExceptionLine."Location Code" := SalesLine."Location Code";
        ExceptionLine."Variant Code" := SalesLine."Variant Code";
        ExceptionLine."Demand Document No." := SalesLine."Document No.";
        ExceptionLine."Demand Line No." := SalesLine."Line No.";
        ExceptionLine."Customer No." := SalesHeader."Sell-to Customer No.";
        ExceptionLine."Demand Date" := NeedDate;
        ExceptionLine."Outstanding Demand Qty. (Base)" := SalesLine."Outstanding Qty. (Base)";
        ExceptionLine."Cumulative Demand Qty. (Base)" := CumulativeDemand;
        ExceptionLine."Current Inventory (Base)" := CurrentInventory;
        ExceptionLine."PO Supply by Need Date (Base)" := PurchaseSupplyByNeedDate;
        ExceptionLine."Additional Supply (Base)" := AdditionalSupply;
        ExceptionLine."Projected Availability (Base)" := ProjectedAvailability;
        ExceptionLine."Shortage Qty. (Base)" := ShortageQty;
        ExceptionLine."Next Inbound Date" := NextInboundDate;
        ExceptionLine."Source Purchase Order No." := NextPurchaseOrderNo;
        ExceptionLine."Vendor No." := NextVendorNo;
        if (ExceptionType = ExceptionType::"Late Inbound Supply") and
           HasOverduePurchaseSupply and
           (ExceptionLine."Source Purchase Order No." = '')
        then begin
            ExceptionLine."Source Purchase Order No." := OverduePurchaseOrderNo;
            ExceptionLine."Vendor No." := OverdueVendorNo;
            ExceptionLine."Expected Receipt Date" := OverdueExpectedReceiptDate;
        end;
        ExceptionLine."Days Late" := DaysPastDue;
        BuildDemandNarrative(ExceptionLine);
        ExceptionLine.Insert(true);

        UpdateHeaderStatistics(AnalysisHeader, ExceptionLine);
    end;

    local procedure ScanOverduePurchaseSupply(var AnalysisHeader: Record "SCAAnalysisHeader"; Setup: Record "SCASetup")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ExceptionLine: Record "SCAExceptionLine";
        ExpectedReceiptDate: Date;
        RiskLevel: Enum "SCARiskLevel";
        DaysLate: Integer;
        OverduePurchaseReasonLbl: Label 'Purchase order %1 for item %2 is %3 day(s) past its expected receipt date %4 with %5 base units still outstanding.', Comment = '%1 = purchase order number, %2 = item number, %3 = days late, %4 = expected receipt date, %5 = outstanding quantity in base units';
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetFilter("No.", '<>%1', '');
        PurchaseLine.SetFilter("Outstanding Qty. (Base)", '>%1', 0);

        if not PurchaseLine.FindSet() then
            exit;

        repeat
            if AnalysisHeader."Exception Count" >= Setup."Maximum Exceptions Per Scan" then begin
                AnalysisHeader."Was Truncated" := true;
                exit;
            end;

            if PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then
                if IsPurchaseHeaderIncluded(PurchaseHeader, Setup) then begin
                    ExpectedReceiptDate := ResolveExpectedReceiptDate(PurchaseHeader, PurchaseLine);
                    if (ExpectedReceiptDate <> 0D) and (ExpectedReceiptDate < WorkDate()) then begin
                        DaysLate := WorkDate() - ExpectedReceiptDate;
                        RiskLevel := RiskFromPastDueDays(DaysLate, Setup);

                        ExceptionLine.Init();
                        ExceptionLine."Analysis Entry No." := AnalysisHeader."Entry No.";
                        ExceptionLine."Line No." := GetNextLineNo(AnalysisHeader."Entry No.");
                        ExceptionLine."Exception Type" := ExceptionLine."Exception Type"::"Overdue Purchase Supply";
                        ExceptionLine."Risk Level" := RiskLevel;
                        ExceptionLine."Item No." := PurchaseLine."No.";
                        ExceptionLine.Description := CopyStr(PurchaseLine.Description, 1, MaxStrLen(ExceptionLine.Description));
                        ExceptionLine."Location Code" := PurchaseLine."Location Code";
                        ExceptionLine."Variant Code" := PurchaseLine."Variant Code";
                        ExceptionLine."Source Purchase Order No." := PurchaseLine."Document No.";
                        ExceptionLine."Vendor No." := PurchaseHeader."Buy-from Vendor No.";
                        ExceptionLine."Expected Receipt Date" := ExpectedReceiptDate;
                        ExceptionLine."PO Supply by Need Date (Base)" := PurchaseLine."Outstanding Qty. (Base)";
                        ExceptionLine."Days Late" := DaysLate;
                        ExceptionLine.Reason :=
                            CopyStr(
                                StrSubstNo(
                                    OverduePurchaseReasonLbl,
                                    PurchaseLine."Document No.",
                                    PurchaseLine."No.",
                                    DaysLate,
                                    ExpectedReceiptDate,
                                    PurchaseLine."Outstanding Qty. (Base)"),
                                1,
                                MaxStrLen(ExceptionLine.Reason));
                        ExceptionLine.Recommendation :=
                            CopyStr(
                                'Confirm the vendor commitment, update the expected receipt date if needed, and assess whether demand requires expediting or alternate supply. Do not change the purchase order automatically.',
                                1,
                                MaxStrLen(ExceptionLine.Recommendation));
                        ExceptionLine.Insert(true);

                        UpdateHeaderStatistics(AnalysisHeader, ExceptionLine);
                    end;
                end;
        until PurchaseLine.Next() = 0;
    end;

    local procedure DetermineDemandException(
        Setup: Record "SCASetup";
        NeedDate: Date;
        DaysPastDue: Integer;
        ShortageQty: Decimal;
        ShortagePct: Decimal;
        NextInboundDate: Date;
        HasAnyDatedPurchaseSupply: Boolean;
        HasOverduePurchaseSupply: Boolean;
        var ExceptionType: Enum "SCAExceptionType";
        var RiskLevel: Enum "SCARiskLevel"): Boolean
    var
        LateCutoffDate: Date;
    begin
        if (NeedDate <> 0D) and (NeedDate < WorkDate()) then begin
            ExceptionType := ExceptionType::"Past Due Demand";
            RiskLevel := RiskFromPastDueAndShortage(DaysPastDue, ShortagePct, Setup);
            exit(true);
        end;

        if ShortageQty <= Setup."Minimum Shortage Qty. (Base)" then
            exit(false);

        RiskLevel := RiskFromShortagePct(ShortagePct, Setup);

        if HasOverduePurchaseSupply then begin
            ExceptionType := ExceptionType::"Late Inbound Supply";
            if SetupMgt.RiskRank(RiskLevel) < SetupMgt.RiskRank(RiskLevel::High) then
                RiskLevel := RiskLevel::High;
            exit(true);
        end;

        if not HasAnyDatedPurchaseSupply then begin
            ExceptionType := ExceptionType::"No Inbound Supply";
            if SetupMgt.RiskRank(RiskLevel) < SetupMgt.RiskRank(RiskLevel::High) then
                RiskLevel := RiskLevel::High;
            exit(true);
        end;

        LateCutoffDate := NeedDate;
        if LateCutoffDate = 0D then
            LateCutoffDate := WorkDate();
        LateCutoffDate := CalcDate(StrSubstNo(AddDaysDateFormulaLbl, Setup."Late Receipt Grace Days"), LateCutoffDate);

        if NextInboundDate > LateCutoffDate then begin
            ExceptionType := ExceptionType::"Late Inbound Supply";
            if SetupMgt.RiskRank(RiskLevel) < SetupMgt.RiskRank(RiskLevel::High) then
                RiskLevel := RiskLevel::High;
            exit(true);
        end;

        ExceptionType := ExceptionType::"Inventory Shortage";
        exit(true);
    end;

    local procedure RiskFromPastDueAndShortage(DaysPastDue: Integer; ShortagePct: Decimal; Setup: Record "SCASetup"): Enum "SCARiskLevel"
    var
        PastDueRisk: Enum "SCARiskLevel";
        ShortageRisk: Enum "SCARiskLevel";
    begin
        PastDueRisk := RiskFromPastDueDays(DaysPastDue, Setup);
        ShortageRisk := RiskFromShortagePct(ShortagePct, Setup);

        if SetupMgt.RiskRank(ShortageRisk) > SetupMgt.RiskRank(PastDueRisk) then
            exit(ShortageRisk);
        exit(PastDueRisk);
    end;

    local procedure RiskFromPastDueDays(DaysPastDue: Integer; Setup: Record "SCASetup"): Enum "SCARiskLevel"
    begin
        if DaysPastDue >= Setup."Critical Past Due Days" then
            exit(Enum::"SCARiskLevel"::Critical);
        if DaysPastDue >= Setup."High Past Due Days" then
            exit(Enum::"SCARiskLevel"::High);
        exit(Enum::"SCARiskLevel"::Medium);
    end;

    local procedure RiskFromShortagePct(ShortagePct: Decimal; Setup: Record "SCASetup"): Enum "SCARiskLevel"
    begin
        if ShortagePct >= Setup."Critical Shortage %" then
            exit(Enum::"SCARiskLevel"::Critical);
        if ShortagePct >= Setup."High Shortage %" then
            exit(Enum::"SCARiskLevel"::High);
        exit(Enum::"SCARiskLevel"::Medium);
    end;

    local procedure BuildDemandNarrative(var ExceptionLine: Record "SCAExceptionLine")
    var
        InventoryShortageReasonLbl: Label 'Projected availability for item %1 at location %2 is %3 base units by %4, leaving a shortage of %5 base units.', Comment = '%1 = item number, %2 = location code, %3 = projected availability in base units, %4 = demand date, %5 = shortage quantity in base units';
        NextInboundSupplyReasonLbl: Label 'Demand on sales order %1 has a projected shortage of %2 base units by %3. The next identified purchase supply is %4 on purchase order %5.', Comment = '%1 = sales order number, %2 = shortage quantity in base units, %3 = demand date, %4 = next inbound date, %5 = purchase order number';
        NoInboundSupplyReasonLbl: Label 'Demand on sales order %1 creates a projected shortage of %2 base units by %3, and no open purchase supply with an expected date was found.', Comment = '%1 = sales order number, %2 = shortage quantity in base units, %3 = demand date';
        OverdueInboundSupplyReasonLbl: Label 'Demand on sales order %1 has a projected shortage of %2 base units by %3. Purchase order %4 still has outstanding supply with an overdue expected receipt date of %5.', Comment = '%1 = sales order number, %2 = shortage quantity in base units, %3 = demand date, %4 = purchase order number, %5 = expected receipt date';
        PastDueDemandReasonLbl: Label 'Sales order %1 line %2 is %3 day(s) past its demand date %4. Projected availability is %5 base units and shortage is %6 base units.', Comment = '%1 = sales order number, %2 = sales order line number, %3 = days late, %4 = demand date, %5 = projected availability in base units, %6 = shortage quantity in base units';
    begin
        case ExceptionLine."Exception Type" of
            ExceptionLine."Exception Type"::"Past Due Demand":
                begin
                    ExceptionLine.Reason :=
                        CopyStr(
                            StrSubstNo(
                                PastDueDemandReasonLbl,
                                ExceptionLine."Demand Document No.",
                                ExceptionLine."Demand Line No.",
                                ExceptionLine."Days Late",
                                ExceptionLine."Demand Date",
                                ExceptionLine."Projected Availability (Base)",
                                ExceptionLine."Shortage Qty. (Base)"),
                            1,
                            MaxStrLen(ExceptionLine.Reason));
                    ExceptionLine.Recommendation :=
                        CopyStr(
                            'Review the customer promise immediately. Confirm whether stock can ship, whether inbound supply can be expedited, or whether the promise date needs human approval to change.',
                            1,
                            MaxStrLen(ExceptionLine.Recommendation));
                end;
            ExceptionLine."Exception Type"::"No Inbound Supply":
                begin
                    ExceptionLine.Reason :=
                        CopyStr(
                            StrSubstNo(
                                NoInboundSupplyReasonLbl,
                                ExceptionLine."Demand Document No.",
                                ExceptionLine."Shortage Qty. (Base)",
                                ExceptionLine."Demand Date"),
                            1,
                            MaxStrLen(ExceptionLine.Reason));
                    ExceptionLine.Recommendation :=
                        CopyStr(
                            'Review replenishment, alternate locations, transfer possibilities, production supply, or a new purchase order. The agent must not create or change supply documents automatically.',
                            1,
                            MaxStrLen(ExceptionLine.Recommendation));
                end;
            ExceptionLine."Exception Type"::"Late Inbound Supply":
                begin
                    if ExceptionLine."Expected Receipt Date" <> 0D then
                        ExceptionLine.Reason :=
                            CopyStr(
                                StrSubstNo(
                                    OverdueInboundSupplyReasonLbl,
                                    ExceptionLine."Demand Document No.",
                                    ExceptionLine."Shortage Qty. (Base)",
                                    ExceptionLine."Demand Date",
                                    ExceptionLine."Source Purchase Order No.",
                                    ExceptionLine."Expected Receipt Date"),
                                1,
                                MaxStrLen(ExceptionLine.Reason))
                    else
                        ExceptionLine.Reason :=
                            CopyStr(
                                StrSubstNo(
                                    NextInboundSupplyReasonLbl,
                                    ExceptionLine."Demand Document No.",
                                    ExceptionLine."Shortage Qty. (Base)",
                                    ExceptionLine."Demand Date",
                                    ExceptionLine."Next Inbound Date",
                                    ExceptionLine."Source Purchase Order No."),
                                1,
                                MaxStrLen(ExceptionLine.Reason));
                    ExceptionLine.Recommendation :=
                        CopyStr(
                            'Confirm the vendor date, assess expediting or alternate supply, and review the customer promise. Any document or date change requires a human action.',
                            1,
                            MaxStrLen(ExceptionLine.Recommendation));
                end;
            ExceptionLine."Exception Type"::"Inventory Shortage":
                begin
                    ExceptionLine.Reason :=
                        CopyStr(
                            StrSubstNo(
                                InventoryShortageReasonLbl,
                                ExceptionLine."Item No.",
                                ExceptionLine."Location Code",
                                ExceptionLine."Projected Availability (Base)",
                                ExceptionLine."Demand Date",
                                ExceptionLine."Shortage Qty. (Base)"),
                            1,
                            MaxStrLen(ExceptionLine.Reason));
                    ExceptionLine.Recommendation :=
                        CopyStr(
                            'Review allocation, inbound timing, alternate locations and replenishment options. Preserve standard Business Central planning and approval controls.',
                            1,
                            MaxStrLen(ExceptionLine.Recommendation));
                end;
        end;
    end;

    local procedure GetCurrentInventoryBase(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]): Decimal
    var
        Item: Record Item;
    begin
        if not Item.Get(ItemNo) then
            exit(0);

        Item.SetRange("Location Filter", LocationCode);
        Item.SetRange("Variant Filter", VariantCode);
        Item.CalcFields(Inventory);
        exit(Item.Inventory);
    end;

    local procedure CalculateCumulativeDemandBase(SourceSalesLine: Record "Sales Line"; NeedDate: Date; Setup: Record "SCASetup"): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CandidateDate: Date;
        DemandQty: Decimal;
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", SourceSalesLine."No.");
        SalesLine.SetRange("Location Code", SourceSalesLine."Location Code");
        SalesLine.SetRange("Variant Code", SourceSalesLine."Variant Code");
        SalesLine.SetFilter("Outstanding Qty. (Base)", '>%1', 0);

        if not SalesLine.FindSet() then
            exit(0);

        repeat
            if SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
                if IsSalesHeaderIncluded(SalesHeader, Setup) then begin
                    CandidateDate := ResolveDemandDate(SalesHeader, SalesLine);
                    if (NeedDate = 0D) or (CandidateDate = 0D) or (CandidateDate <= NeedDate) then
                        DemandQty += SalesLine."Outstanding Qty. (Base)";
                end;
        until SalesLine.Next() = 0;

        exit(DemandQty);
    end;

    local procedure CalculatePurchaseSupplyBase(
        ItemNo: Code[20];
        LocationCode: Code[10];
        VariantCode: Code[10];
        NeedDate: Date;
        Setup: Record "SCASetup";
        var NextInboundDate: Date;
        var NextPurchaseOrderNo: Code[20];
        var NextVendorNo: Code[20];
        var OverduePurchaseOrderNo: Code[20];
        var OverdueVendorNo: Code[20];
        var OverdueExpectedReceiptDate: Date;
        var HasAnyDatedPurchaseSupply: Boolean;
        var HasOverduePurchaseSupply: Boolean): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EffectiveNeedDate: Date;
        ExpectedReceiptDate: Date;
        SupplyQty: Decimal;
    begin
        Clear(NextInboundDate);
        Clear(NextPurchaseOrderNo);
        Clear(NextVendorNo);
        Clear(OverduePurchaseOrderNo);
        Clear(OverdueVendorNo);
        Clear(OverdueExpectedReceiptDate);
        HasAnyDatedPurchaseSupply := false;
        HasOverduePurchaseSupply := false;

        EffectiveNeedDate := NeedDate;
        if EffectiveNeedDate = 0D then
            EffectiveNeedDate := WorkDate();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.SetRange("Location Code", LocationCode);
        PurchaseLine.SetRange("Variant Code", VariantCode);
        PurchaseLine.SetFilter("Outstanding Qty. (Base)", '>%1', 0);

        if not PurchaseLine.FindSet() then
            exit(0);

        repeat
            if PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then
                if IsPurchaseHeaderIncluded(PurchaseHeader, Setup) then begin
                    ExpectedReceiptDate := ResolveExpectedReceiptDate(PurchaseHeader, PurchaseLine);
                    if ExpectedReceiptDate <> 0D then begin
                        HasAnyDatedPurchaseSupply := true;

                        if ExpectedReceiptDate < WorkDate() then begin
                            HasOverduePurchaseSupply := true;
                            if (OverdueExpectedReceiptDate = 0D) or (ExpectedReceiptDate < OverdueExpectedReceiptDate) then begin
                                OverdueExpectedReceiptDate := ExpectedReceiptDate;
                                OverduePurchaseOrderNo := PurchaseLine."Document No.";
                                OverdueVendorNo := PurchaseHeader."Buy-from Vendor No.";
                            end;
                        end else
                            if ExpectedReceiptDate <= EffectiveNeedDate then
                                SupplyQty += PurchaseLine."Outstanding Qty. (Base)"
                            else
                                if (NextInboundDate = 0D) or (ExpectedReceiptDate < NextInboundDate) then begin
                                    NextInboundDate := ExpectedReceiptDate;
                                    NextPurchaseOrderNo := PurchaseLine."Document No.";
                                    NextVendorNo := PurchaseHeader."Buy-from Vendor No.";
                                end;
                    end;
                end;
        until PurchaseLine.Next() = 0;

        exit(SupplyQty);
    end;

    local procedure ResolveDemandDate(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"): Date
    begin
        if SalesLine."Shipment Date" <> 0D then
            exit(SalesLine."Shipment Date");
        exit(SalesHeader."Shipment Date");
    end;

    local procedure ResolveExpectedReceiptDate(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"): Date
    begin
        if PurchaseLine."Expected Receipt Date" <> 0D then
            exit(PurchaseLine."Expected Receipt Date");
        exit(PurchaseHeader."Expected Receipt Date");
    end;

    local procedure IsSalesHeaderIncluded(SalesHeader: Record "Sales Header"; Setup: Record "SCASetup"): Boolean
    begin
        case SalesHeader.Status of
            SalesHeader.Status::Open:
                exit(Setup."Include Open Sales Orders");
            SalesHeader.Status::Released:
                exit(Setup."Include Released Sales Orders");
        end;
        exit(false);
    end;

    local procedure IsPurchaseHeaderIncluded(PurchaseHeader: Record "Purchase Header"; Setup: Record "SCASetup"): Boolean
    begin
        case PurchaseHeader.Status of
            PurchaseHeader.Status::Open:
                exit(Setup."Include Open Purchase Orders");
            PurchaseHeader.Status::Released:
                exit(Setup."Include Released PO");
        end;
        exit(false);
    end;

    local procedure GetDaysPastDue(NeedDate: Date): Integer
    begin
        if (NeedDate = 0D) or (NeedDate >= WorkDate()) then
            exit(0);
        exit(WorkDate() - NeedDate);
    end;

    local procedure GetNextLineNo(AnalysisEntryNo: Integer): Integer
    var
        ExceptionLine: Record "SCAExceptionLine";
    begin
        ExceptionLine.SetRange("Analysis Entry No.", AnalysisEntryNo);
        if ExceptionLine.FindLast() then
            exit(ExceptionLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure UpdateHeaderStatistics(var AnalysisHeader: Record "SCAAnalysisHeader"; ExceptionLine: Record "SCAExceptionLine")
    var
        PreviousPeakShortage: Decimal;
    begin
        AnalysisHeader."Exception Count" += 1;

        if ExceptionLine."Shortage Qty. (Base)" > 0 then begin
            PreviousPeakShortage := GetPreviousPeakShortage(ExceptionLine);
            if ExceptionLine."Shortage Qty. (Base)" > PreviousPeakShortage then
                AnalysisHeader."Peak Shortage Qty. (Base)" += ExceptionLine."Shortage Qty. (Base)" - PreviousPeakShortage;
        end;

        case ExceptionLine."Risk Level" of
            ExceptionLine."Risk Level"::Critical:
                AnalysisHeader."Critical Count" += 1;
            ExceptionLine."Risk Level"::High:
                AnalysisHeader."High Count" += 1;
            ExceptionLine."Risk Level"::Medium:
                AnalysisHeader."Medium Count" += 1;
            ExceptionLine."Risk Level"::Low:
                AnalysisHeader."Low Count" += 1;
        end;

        if SetupMgt.RiskRank(ExceptionLine."Risk Level") > SetupMgt.RiskRank(AnalysisHeader."Highest Risk Level") then
            AnalysisHeader."Highest Risk Level" := ExceptionLine."Risk Level";

        AnalysisHeader.Modify();
    end;

    local procedure GetPreviousPeakShortage(CurrentExceptionLine: Record "SCAExceptionLine"): Decimal
    var
        ExceptionLine: Record "SCAExceptionLine";
        PeakShortage: Decimal;
    begin
        ExceptionLine.SetRange("Analysis Entry No.", CurrentExceptionLine."Analysis Entry No.");
        ExceptionLine.SetRange("Item No.", CurrentExceptionLine."Item No.");
        ExceptionLine.SetRange("Location Code", CurrentExceptionLine."Location Code");
        ExceptionLine.SetRange("Variant Code", CurrentExceptionLine."Variant Code");
        ExceptionLine.SetFilter("Line No.", '<>%1', CurrentExceptionLine."Line No.");
        PeakShortage := 0;
        if ExceptionLine.FindSet() then
            repeat
                if ExceptionLine."Shortage Qty. (Base)" > PeakShortage then
                    PeakShortage := ExceptionLine."Shortage Qty. (Base)";
            until ExceptionLine.Next() = 0;

        exit(PeakShortage);
    end;

    local procedure FinalizeAnalysis(var AnalysisHeader: Record "SCAAnalysisHeader")
    begin
        AnalysisHeader.Modify();
    end;

    [IntegrationEvent(false, false)]
    procedure OnCalculateAdditionalSupplyBase(
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NeedDate: Date;
        var AdditionalSupplyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnShouldIncludeSalesDemand(
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        var IncludeLine: Boolean)
    begin
    end;

    var
        SetupMgt: Codeunit "SCASetupMgt";
        AddDaysDateFormulaLbl: Label '<+%1D>', Locked = true;
}
