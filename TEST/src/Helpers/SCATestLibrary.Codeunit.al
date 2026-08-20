codeunit 50402 "SCATestLibrary"
{
    procedure Initialize()
    var
        EventSubscriber: Codeunit "SCATestEventSubscriber";
    begin
        EventSubscriber.Reset();
        ResetSetupToDefaults();
    end;

    procedure ResetSetupToDefaults()
    var
        Setup: Record "SCASetup";
        SetupMgt: Codeunit "SCASetupMgt";
    begin
        SetupMgt.GetSetup(Setup);
        Setup."Horizon Days" := 30;
        Setup."High Shortage %" := 20;
        Setup."Critical Shortage %" := 50;
        Setup."High Past Due Days" := 3;
        Setup."Critical Past Due Days" := 7;
        Setup."Minimum Shortage Qty. (Base)" := 0.00001;
        Setup."Late Receipt Grace Days" := 0;
        Setup."Maximum Exceptions Per Scan" := 500;
        Setup."Agent Top Exceptions" := 20;
        Setup."Include Open Sales Orders" := true;
        Setup."Include Released Sales Orders" := true;
        Setup."Include Open Purchase Orders" := true;
        Setup."Include Released PO" := true;
        Setup.Modify(false);
    end;

    procedure CreateItem(var Item: Record Item)
    begin
        Item.Init();
        Item."No." := NewCode('SCTI');
        Item.Description := CopyStr('Supply Chain Test Item ' + Item."No.", 1, MaxStrLen(Item.Description));
        Item.Insert(false);
    end;

    procedure AddInventory(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; QuantityBase: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        EntryNo: Integer;
    begin
        ItemLedgerEntry.LockTable();
        if ItemLedgerEntry.FindLast() then
            EntryNo := ItemLedgerEntry."Entry No." + 1
        else
            EntryNo := 1;

        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := EntryNo;
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Posting Date" := WorkDate();
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::"Positive Adjmt.";
        ItemLedgerEntry."Document No." := 'SCA-TEST';
        ItemLedgerEntry."Location Code" := LocationCode;
        ItemLedgerEntry."Variant Code" := VariantCode;
        ItemLedgerEntry.Quantity := QuantityBase;
        ItemLedgerEntry."Remaining Quantity" := QuantityBase;
        ItemLedgerEntry.Open := QuantityBase <> 0;
        ItemLedgerEntry.Insert(false);
    end;

    procedure CreateSalesOrder(
        var SalesHeader: Record "Sales Header";
        var SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        QuantityBase: Decimal;
        ShipmentDate: Date;
        LocationCode: Code[10];
        VariantCode: Code[10])
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := NewCode('SCTS');
        SalesHeader."Sell-to Customer No." := 'SCA-TEST';
        SalesHeader."Shipment Date" := ShipmentDate;
        SalesHeader.Status := SalesHeader.Status::Open;
        SalesHeader.Insert(false);

        AddSalesLine(SalesHeader, SalesLine, 10000, ItemNo, QuantityBase, ShipmentDate, LocationCode, VariantCode);
    end;

    procedure AddSalesLine(
        SalesHeader: Record "Sales Header";
        var SalesLine: Record "Sales Line";
        LineNo: Integer;
        ItemNo: Code[20];
        QuantityBase: Decimal;
        ShipmentDate: Date;
        LocationCode: Code[10];
        VariantCode: Code[10])
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemNo;
        SalesLine.Description := ItemNo;
        SalesLine.Quantity := QuantityBase;
        SalesLine."Quantity (Base)" := QuantityBase;
        SalesLine."Outstanding Quantity" := QuantityBase;
        SalesLine."Outstanding Qty. (Base)" := QuantityBase;
        SalesLine."Shipment Date" := ShipmentDate;
        SalesLine."Location Code" := LocationCode;
        SalesLine."Variant Code" := VariantCode;
        SalesLine.Insert(false);
    end;

    procedure SetSalesOrderReleased(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Status := SalesHeader.Status::Released;
        SalesHeader.Modify(false);
    end;

    procedure CreatePurchaseOrder(
        var PurchaseHeader: Record "Purchase Header";
        var PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
        QuantityBase: Decimal;
        ExpectedReceiptDate: Date;
        LocationCode: Code[10];
        VariantCode: Code[10])
    begin
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := NewCode('SCTP');
        PurchaseHeader."Buy-from Vendor No." := 'SCA-VENDOR';
        PurchaseHeader."Expected Receipt Date" := ExpectedReceiptDate;
        PurchaseHeader.Status := PurchaseHeader.Status::Open;
        PurchaseHeader.Insert(false);

        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := ItemNo;
        PurchaseLine.Description := ItemNo;
        PurchaseLine.Quantity := QuantityBase;
        PurchaseLine."Quantity (Base)" := QuantityBase;
        PurchaseLine."Outstanding Quantity" := QuantityBase;
        PurchaseLine."Outstanding Qty. (Base)" := QuantityBase;
        PurchaseLine."Expected Receipt Date" := ExpectedReceiptDate;
        PurchaseLine."Location Code" := LocationCode;
        PurchaseLine."Variant Code" := VariantCode;
        PurchaseLine.Insert(false);
    end;

    procedure SetPurchaseOrderReleased(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Status := PurchaseHeader.Status::Released;
        PurchaseHeader.Modify(false);
    end;

    procedure AnalyzeSalesOrder(
        var SalesHeader: Record "Sales Header";
        var AnalysisHeader: Record "SCAAnalysisHeader"): Integer
    var
        Engine: Codeunit "SCAExceptionEngine";
        EntryNo: Integer;
    begin
        EntryNo := Engine.AnalyzeSalesOrder(SalesHeader, false);
        AnalysisHeader.Get(EntryNo);
        exit(EntryNo);
    end;

    procedure GetDemandException(
        AnalysisEntryNo: Integer;
        SalesDocumentNo: Code[20];
        var ExceptionLine: Record "SCAExceptionLine"): Boolean
    begin
        ExceptionLine.Reset();
        ExceptionLine.SetRange("Analysis Entry No.", AnalysisEntryNo);
        ExceptionLine.SetRange("Demand Document No.", SalesDocumentNo);
        exit(ExceptionLine.FindFirst());
    end;

    procedure GetExceptionByPurchaseOrder(
        AnalysisEntryNo: Integer;
        PurchaseOrderNo: Code[20];
        var ExceptionLine: Record "SCAExceptionLine"): Boolean
    begin
        ExceptionLine.Reset();
        ExceptionLine.SetRange("Analysis Entry No.", AnalysisEntryNo);
        ExceptionLine.SetRange("Source Purchase Order No.", PurchaseOrderNo);
        exit(ExceptionLine.FindFirst());
    end;

    procedure NewCode(Prefix: Text): Code[20]
    var
        GuidText: Text;
    begin
        GuidText := DelChr(Format(CreateGuid()), '=', '{}-');
        exit(CopyStr(Prefix + GuidText, 1, 20));
    end;
}
