namespace SupplyChain.ExceptionAgent.Tests;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using SupplyChain.ExceptionAgent;

codeunit 50412 "SCAExtensibilityTests"
{
    Subtype = Test;
    RequiredTestIsolation = Function;
    TestType = IntegrationTest;

    [Test]
    procedure AdditionalSupplyEventCanCoverShortage()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        EventSubscriber: Codeunit "SCATestEventSubscriber";
    begin
        Library.Initialize();
        EventSubscriber.EnableAdditionalSupply(100);
        Library.CreateItem(Item);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.AreEqualInteger(0, AnalysisHeader."Exception Count", 'Additional-supply subscriber should cover the shortage.');
    end;

    [Test]
    procedure SalesDemandEventCanExcludeLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        EventSubscriber: Codeunit "SCATestEventSubscriber";
    begin
        Library.Initialize();
        EventSubscriber.SetExcludeAllSalesDemand(true);
        Library.CreateItem(Item);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.AreEqualInteger(0, AnalysisHeader."Exception Count", 'OnShouldIncludeSalesDemand subscriber should be able to exclude a line.');
    end;

    var
        Library: Codeunit "SCATestLibrary";
        Assert: Codeunit "SCATestAssert";
}
