codeunit 50401 "SCATestEventSubscriber"
{
    SingleInstance = true;

    procedure Reset()
    begin
        AdditionalSupplyEnabled := false;
        AdditionalSupplyBase := 0;
        FilterSalesDemandToTestItems := false;
        Clear(IncludedSalesItemNo);
        ExcludeAllSalesDemand := false;
    end;

    procedure EnableAdditionalSupply(QuantityBase: Decimal)
    begin
        AdditionalSupplyEnabled := true;
        AdditionalSupplyBase := QuantityBase;
    end;

    procedure SetFilterSalesDemandToTestItems(Enabled: Boolean)
    begin
        FilterSalesDemandToTestItems := Enabled;
        Clear(IncludedSalesItemNo);
    end;

    procedure SetSalesDemandItemFilter(ItemNo: Code[20])
    begin
        FilterSalesDemandToTestItems := false;
        IncludedSalesItemNo := ItemNo;
    end;

    procedure SetExcludeAllSalesDemand(Enabled: Boolean)
    begin
        ExcludeAllSalesDemand := Enabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SCAExceptionEngine", 'OnCalculateAdditionalSupplyBase', '', false, false)]
    local procedure AddTestSupply(
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NeedDate: Date;
        var AdditionalSupply: Decimal)
    begin
        if not AdditionalSupplyEnabled then
            exit;
        if CopyStr(SalesLine."No.", 1, 4) <> 'SCTI' then
            exit;

        AdditionalSupply += AdditionalSupplyBase;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SCAExceptionEngine", 'OnShouldIncludeSalesDemand', '', false, false)]
    local procedure FilterTestSalesDemand(
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        var IncludeLine: Boolean)
    begin
        if ExcludeAllSalesDemand then begin
            IncludeLine := false;
            exit;
        end;

        if IncludedSalesItemNo <> '' then begin
            IncludeLine := SalesLine."No." = IncludedSalesItemNo;
            exit;
        end;

        if FilterSalesDemandToTestItems then
            IncludeLine := CopyStr(SalesLine."No.", 1, 4) = 'SCTI';
    end;

    var
        AdditionalSupplyEnabled: Boolean;
        ExcludeAllSalesDemand: Boolean;
        FilterSalesDemandToTestItems: Boolean;
        IncludedSalesItemNo: Code[20];
        AdditionalSupplyBase: Decimal;
}
