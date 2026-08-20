namespace SupplyChain.ExceptionAgent.Tests;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using SupplyChain.ExceptionAgent;

codeunit 50413 "SCAFullScanTests"
{
    Subtype = Test;
    RequiredTestIsolation = Function;
    TestType = IntegrationTest;

    [Test]
    procedure OverduePurchaseSupplyAppearsInFullScan()
    var
        Setup: Record "SCASetup";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
        Engine: Codeunit "SCAExceptionEngine";
        EventSubscriber: Codeunit "SCATestEventSubscriber";
        AnalysisEntryNo: Integer;
    begin
        Library.Initialize();
        EventSubscriber.SetExcludeAllSalesDemand(true);
        Setup.Get('');
        Setup."Maximum Exceptions Per Scan" := 10000;
        Setup.Modify(false);
        Library.CreateItem(Item);
        Library.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", 50, CalcDate('<-5D>', WorkDate()), '', '');

        AnalysisEntryNo := Engine.RunFullScan(false);
        AnalysisHeader.Get(AnalysisEntryNo);

        Assert.AreEqualText(Format(Enum::"SCAScanScope"::"Full Scan"), Format(AnalysisHeader.Scope), 'Full scan scope mismatch.');
        Assert.IsTrue(Library.GetExceptionByPurchaseOrder(AnalysisEntryNo, PurchaseHeader."No.", ExceptionLine), 'Expected overdue purchase exception in full scan.');
        Assert.AreEqualText(Format(Enum::"SCAExceptionType"::"Overdue Purchase Supply"), Format(ExceptionLine."Exception Type"), 'Wrong full-scan purchase exception type.');
        Assert.AreEqualInteger(5, ExceptionLine."Days Late", 'Overdue days mismatch.');
        Assert.AreEqualDecimal(50, ExceptionLine."PO Supply by Need Date (Base)", 0.00001, 'Outstanding purchase quantity mismatch.');
    end;

    [Test]
    procedure FullScanMarksTruncatedAtConfiguredLimit()
    var
        Setup: Record "SCASetup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        Engine: Codeunit "SCAExceptionEngine";
        EventSubscriber: Codeunit "SCATestEventSubscriber";
        AnalysisEntryNo: Integer;
    begin
        Library.Initialize();
        Setup.Get('');
        Setup."Maximum Exceptions Per Scan" := 1;
        Setup.Modify(false);
        Library.CreateItem(Item);
        EventSubscriber.SetSalesDemandItemFilter(Item."No.");
        Library.CreateSalesOrder(SalesHeader, FirstLine, Item."No.", 50, CalcDate('<+5D>', WorkDate()), '', '');
        Library.AddSalesLine(SalesHeader, SecondLine, 20000, Item."No.", 50, CalcDate('<+5D>', WorkDate()), '', '');

        AnalysisEntryNo := Engine.RunFullScan(false);
        AnalysisHeader.Get(AnalysisEntryNo);

        Assert.IsTrue(AnalysisHeader."Was Truncated", 'Full scan should mark truncation when the configured maximum is reached.');
        Assert.AreEqualInteger(1, AnalysisHeader."Exception Count", 'Only one exception should be persisted at the configured limit.');
    end;

    [Test]
    procedure PeakShortageIsNotDoubleCountedForSameItem()
    var
        Setup: Record "SCASetup";
        Item: Record Item;
        FirstHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondHeader: Record "Sales Header";
        SecondLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        Engine: Codeunit "SCAExceptionEngine";
        EventSubscriber: Codeunit "SCATestEventSubscriber";
        AnalysisEntryNo: Integer;
    begin
        Library.Initialize();
        Setup.Get('');
        Setup."Maximum Exceptions Per Scan" := 10000;
        Setup.Modify(false);
        Library.CreateItem(Item);
        EventSubscriber.SetSalesDemandItemFilter(Item."No.");
        Library.CreateSalesOrder(FirstHeader, FirstLine, Item."No.", 60, CalcDate('<+3D>', WorkDate()), '', '');
        Library.CreateSalesOrder(SecondHeader, SecondLine, Item."No.", 40, CalcDate('<+5D>', WorkDate()), '', '');

        AnalysisEntryNo := Engine.RunFullScan(false);
        AnalysisHeader.Get(AnalysisEntryNo);

        Assert.AreEqualDecimal(100, AnalysisHeader."Peak Shortage Qty. (Base)", 0.00001, 'Header peak shortage must retain only the maximum shortage for the same item/location/variant.');
    end;

    [Test]
    procedure LatestAnalysisReturnsNewestSalesOrderAnalysis()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FirstAnalysis: Record "SCAAnalysisHeader";
        SecondAnalysis: Record "SCAAnalysisHeader";
        LatestAnalysis: Record "SCAAnalysisHeader";
        Engine: Codeunit "SCAExceptionEngine";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, FirstAnalysis);
        Library.AnalyzeSalesOrder(SalesHeader, SecondAnalysis);

        Assert.IsTrue(Engine.GetLatestAnalysis(Enum::"SCAScanScope"::"Sales Order", SalesHeader."No.", LatestAnalysis), 'Latest analysis should be found.');
        Assert.AreEqualInteger(SecondAnalysis."Entry No.", LatestAnalysis."Entry No.", 'Newest analysis should be returned.');
        Assert.IsTrue(SecondAnalysis."Entry No." > FirstAnalysis."Entry No.", 'Second analysis entry should be newer.');
    end;

    var
        Library: Codeunit "SCATestLibrary";
        Assert: Codeunit "SCATestAssert";
}
