namespace SupplyChain.ExceptionAgent.Tests;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using SupplyChain.ExceptionAgent;

codeunit 50411 "SCADemandTests"
{
    RequiredTestIsolation = Function;
    Subtype = Test;
    TestType = IntegrationTest;

    [Test]
    procedure NoInboundSupplyCreatesCriticalException()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.AreEqualText(Format(Enum::"SCAScanScope"::"Sales Order"), Format(AnalysisHeader.Scope), 'Analysis scope mismatch.');
        Assert.AreEqualText(SalesHeader."No.", AnalysisHeader."Source Document No.", 'Source document mismatch.');
        Assert.AreEqualInteger(1, AnalysisHeader."Exception Count", 'Header exception count mismatch.');
        Assert.AreEqualInteger(1, AnalysisHeader."Critical Count", 'Header critical count mismatch.');
        Assert.AreEqualText(Format(Enum::"SCARiskLevel"::Critical), Format(AnalysisHeader."Highest Risk Level"), 'Highest-risk header value mismatch.');
        Assert.AreEqualDecimal(100, AnalysisHeader."Peak Shortage Qty. (Base)", 0.00001, 'Peak shortage mismatch.');
        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'Expected a demand exception.');
        Assert.AreEqualText(Format(Enum::"SCAExceptionType"::"No Inbound Supply"), Format(ExceptionLine."Exception Type"), 'Wrong exception type.');
        Assert.AreEqualText(Format(Enum::"SCARiskLevel"::Critical), Format(ExceptionLine."Risk Level"), '100% shortage should be critical.');
        Assert.AreEqualDecimal(100, ExceptionLine."Shortage Qty. (Base)", 0.00001, 'Shortage mismatch.');
    end;

    [Test]
    procedure SmallNoInboundShortageIsAtLeastHigh()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.AddInventory(Item."No.", '', '', 95);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'Expected a demand exception.');
        Assert.AreEqualText(Format(Enum::"SCAExceptionType"::"No Inbound Supply"), Format(ExceptionLine."Exception Type"), 'Wrong exception type.');
        Assert.AreEqualText(Format(Enum::"SCARiskLevel"::High), Format(ExceptionLine."Risk Level"), 'No inbound supply should be at least high risk.');
        Assert.AreEqualDecimal(5, ExceptionLine."Shortage Qty. (Base)", 0.00001, 'Shortage mismatch.');
    end;

    [Test]
    procedure OnTimePurchaseSupplyEliminatesShortage()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
        NeedDate: Date;
    begin
        Library.Initialize();
        NeedDate := CalcDate('<+5D>', WorkDate());
        Library.CreateItem(Item);
        Library.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", 100, CalcDate('<+3D>', WorkDate()), '', '');
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, NeedDate, '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.AreEqualInteger(0, AnalysisHeader."Exception Count", 'Supply received before demand should cover the order.');
        Assert.IsFalse(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'No demand exception should exist.');
    end;

    [Test]
    procedure PartialOnTimeSupplyCreatesInventoryShortage()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", 90, CalcDate('<+3D>', WorkDate()), '', '');
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'Expected a residual shortage.');
        Assert.AreEqualText(Format(Enum::"SCAExceptionType"::"Inventory Shortage"), Format(ExceptionLine."Exception Type"), 'Partial on-time supply should leave inventory shortage.');
        Assert.AreEqualDecimal(90, ExceptionLine."PO Supply by Need Date (Base)", 0.00001, 'PO supply mismatch.');
        Assert.AreEqualDecimal(10, ExceptionLine."Shortage Qty. (Base)", 0.00001, 'Residual shortage mismatch.');
    end;

    [Test]
    procedure LateFuturePurchaseSupplyCreatesLateInboundException()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
        InboundDate: Date;
        NeedDate: Date;
    begin
        Library.Initialize();
        NeedDate := CalcDate('<+5D>', WorkDate());
        InboundDate := CalcDate('<+10D>', WorkDate());
        Library.CreateItem(Item);
        Library.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", 100, InboundDate, '', '');
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, NeedDate, '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'Expected late inbound exception.');
        Assert.AreEqualText(Format(Enum::"SCAExceptionType"::"Late Inbound Supply"), Format(ExceptionLine."Exception Type"), 'Wrong exception type.');
        Assert.AreEqualDate(InboundDate, ExceptionLine."Next Inbound Date", 'Next inbound date mismatch.');
        Assert.AreEqualText(PurchaseHeader."No.", ExceptionLine."Source Purchase Order No.", 'Expected next inbound purchase order reference.');
    end;

    [Test]
    procedure OverduePurchaseSupplyCreatesLateInboundException()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
        OverdueDate: Date;
    begin
        Library.Initialize();
        OverdueDate := CalcDate('<-2D>', WorkDate());
        Library.CreateItem(Item);
        Library.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", 100, OverdueDate, '', '');
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'Expected overdue inbound exception.');
        Assert.AreEqualText(Format(Enum::"SCAExceptionType"::"Late Inbound Supply"), Format(ExceptionLine."Exception Type"), 'Overdue PO should be classified as late inbound.');
        Assert.AreEqualText(PurchaseHeader."No.", ExceptionLine."Source Purchase Order No.", 'Overdue PO reference mismatch.');
        Assert.AreEqualDate(OverdueDate, ExceptionLine."Expected Receipt Date", 'Expected receipt date mismatch.');
    end;

    [Test]
    procedure CurrentInventoryEliminatesShortage()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.AddInventory(Item."No.", '', '', 100);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.AreEqualInteger(0, AnalysisHeader."Exception Count", 'Current inventory should cover demand.');
    end;

    [Test]
    procedure PartialInventoryCreatesShortage()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.AddInventory(Item."No.", '', '', 60);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'Expected shortage.');
        Assert.AreEqualDecimal(60, ExceptionLine."Current Inventory (Base)", 0.00001, 'Inventory mismatch.');
        Assert.AreEqualDecimal(40, ExceptionLine."Shortage Qty. (Base)", 0.00001, 'Shortage mismatch.');
        Assert.AreEqualText(Format(Enum::"SCARiskLevel"::High), Format(ExceptionLine."Risk Level"), '40% shortage should be high risk.');
    end;

    [Test]
    procedure CumulativeDemandAcrossOrdersUsesSameStock()
    var
        Item: Record Item;
        FirstHeader: Record "Sales Header";
        SecondHeader: Record "Sales Header";
        FirstLine: Record "Sales Line";
        SecondLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.AddInventory(Item."No.", '', '', 100);
        Library.CreateSalesOrder(FirstHeader, FirstLine, Item."No.", 80, CalcDate('<+3D>', WorkDate()), '', '');
        Library.CreateSalesOrder(SecondHeader, SecondLine, Item."No.", 80, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SecondHeader, AnalysisHeader);

        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SecondHeader."No.", ExceptionLine), 'Second order should see cumulative shortage.');
        Assert.AreEqualDecimal(160, ExceptionLine."Cumulative Demand Qty. (Base)", 0.00001, 'Cumulative demand mismatch.');
        Assert.AreEqualDecimal(60, ExceptionLine."Shortage Qty. (Base)", 0.00001, 'Shared-stock shortage mismatch.');
    end;

    [Test]
    procedure InventoryIsLocationSpecific()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.AddInventory(Item."No.", 'LOC1', '', 100);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), 'LOC2', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'Inventory in another location must not cover demand.');
        Assert.AreEqualDecimal(0, ExceptionLine."Current Inventory (Base)", 0.00001, 'Other-location inventory leaked into calculation.');
        Assert.AreEqualDecimal(100, ExceptionLine."Shortage Qty. (Base)", 0.00001, 'Location shortage mismatch.');
    end;

    [Test]
    procedure PurchaseSupplyIsLocationSpecific()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", 100, CalcDate('<+3D>', WorkDate()), 'LOC1', '');
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), 'LOC2', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'Supply in another location must not cover demand.');
        Assert.AreEqualDecimal(0, ExceptionLine."PO Supply by Need Date (Base)", 0.00001, 'Other-location PO supply leaked into calculation.');
        Assert.AreEqualText(Format(Enum::"SCAExceptionType"::"No Inbound Supply"), Format(ExceptionLine."Exception Type"), 'No matching-location inbound supply should be found.');
    end;

    [Test]
    procedure PastDueDemandOneDayIsMedium()
    begin
        VerifyPastDueRisk(1, Enum::"SCARiskLevel"::Medium);
    end;

    [Test]
    procedure PastDueDemandFourDaysIsHigh()
    begin
        VerifyPastDueRisk(4, Enum::"SCARiskLevel"::High);
    end;

    [Test]
    procedure PastDueDemandEightDaysIsCritical()
    begin
        VerifyPastDueRisk(8, Enum::"SCARiskLevel"::Critical);
    end;

    [Test]
    procedure FutureDemandBeyondHorizonIsIgnored()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+31D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.AreEqualInteger(0, AnalysisHeader."Exception Count", 'Demand outside the 30-day horizon should be ignored.');
    end;

    [Test]
    procedure ReleasedSalesOrderIsIncludedByDefault()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');
        Library.SetSalesOrderReleased(SalesHeader);

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.AreEqualInteger(1, AnalysisHeader."Exception Count", 'Released sales order should be included by default.');
    end;

    [Test]
    procedure ReleasedSalesOrderCanBeExcluded()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        Setup: Record "SCASetup";
    begin
        Library.Initialize();
        Setup.Get('');
        Setup."Include Released Sales Orders" := false;
        Setup.Modify(false);
        Library.CreateItem(Item);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');
        Library.SetSalesOrderReleased(SalesHeader);

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.AreEqualInteger(0, AnalysisHeader."Exception Count", 'Released sales order should be excluded when setup says so.');
    end;

    [Test]
    procedure ZeroOutstandingQuantityIsIgnored()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 0, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.AreEqualInteger(0, AnalysisHeader."Exception Count", 'Zero outstanding quantity should not be analyzed.');
    end;

    [Test]
    procedure BlankDemandDateStillScansSupplyRisk()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, 0D, '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'Blank-date demand with shortage should still be analyzed.');
        Assert.AreEqualDate(0D, ExceptionLine."Demand Date", 'Demand date should remain blank.');
        Assert.AreEqualText(Format(Enum::"SCAExceptionType"::"No Inbound Supply"), Format(ExceptionLine."Exception Type"), 'Expected no inbound supply exception.');
    end;


    [Test]
    procedure ReleasedPurchaseOrderSupplyIsIncludedByDefault()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", 100, CalcDate('<+3D>', WorkDate()), '', '');
        Library.SetPurchaseOrderReleased(PurchaseHeader);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.AreEqualInteger(0, AnalysisHeader."Exception Count", 'Released purchase supply should be included by default.');
    end;

    [Test]
    procedure ReleasedPurchaseOrderCanBeExcluded()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
        Setup: Record "SCASetup";
    begin
        Library.Initialize();
        Setup.Get('');
        Setup."Include Released PO" := false;
        Setup.Modify(false);
        Library.CreateItem(Item);
        Library.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", 100, CalcDate('<+3D>', WorkDate()), '', '');
        Library.SetPurchaseOrderReleased(PurchaseHeader);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'Excluded released purchase supply should leave a shortage.');
        Assert.AreEqualText(Format(Enum::"SCAExceptionType"::"No Inbound Supply"), Format(ExceptionLine."Exception Type"), 'Excluded released PO should not count as inbound supply.');
    end;

    [Test]
    procedure LateReceiptWithinGraceIsInventoryShortageNotLateInbound()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
        Setup: Record "SCASetup";
    begin
        Library.Initialize();
        Setup.Get('');
        Setup."Late Receipt Grace Days" := 2;
        Setup.Modify(false);
        Library.CreateItem(Item);
        Library.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", 100, CalcDate('<+6D>', WorkDate()), '', '');
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'Supply arriving after need date still leaves projected shortage by need date.');
        Assert.AreEqualText(Format(Enum::"SCAExceptionType"::"Inventory Shortage"), Format(ExceptionLine."Exception Type"), 'Inbound inside grace should not be classified as late inbound.');
    end;

    [Test]
    procedure MinimumShortageThresholdSuppressesTinyShortage()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        Setup: Record "SCASetup";
    begin
        Library.Initialize();
        Setup.Get('');
        Setup."Minimum Shortage Qty. (Base)" := 1;
        Setup.Modify(false);
        Library.CreateItem(Item);
        Library.AddInventory(Item."No.", '', '', 99.5);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.AreEqualInteger(0, AnalysisHeader."Exception Count", 'Shortage at or below minimum threshold should be suppressed.');
    end;

    [Test]
    procedure PurchaseSupplyIsVariantSpecific()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", 100, CalcDate('<+3D>', WorkDate()), '', 'BLUE');
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', 'RED');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'Supply for another variant must not cover demand.');
        Assert.AreEqualDecimal(0, ExceptionLine."PO Supply by Need Date (Base)", 0.00001, 'Other-variant purchase supply leaked into calculation.');
        Assert.AreEqualText(Format(Enum::"SCAExceptionType"::"No Inbound Supply"), Format(ExceptionLine."Exception Type"), 'No matching-variant inbound supply should be found.');
    end;

    local procedure VerifyPastDueRisk(DaysPastDue: Integer; ExpectedRisk: Enum "SCARiskLevel")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
        ExceptionLine: Record "SCAExceptionLine";
        SubtractDaysDateFormulaLbl: Label '<-%1D>', Locked = true;
    begin
        Library.Initialize();
        Library.CreateItem(Item);
        Library.AddInventory(Item."No.", '', '', 100);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate(StrSubstNo(SubtractDaysDateFormulaLbl, DaysPastDue), WorkDate()), '', '');

        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        Assert.IsTrue(Library.GetDemandException(AnalysisHeader."Entry No.", SalesHeader."No.", ExceptionLine), 'Past-due demand should always create an exception.');
        Assert.AreEqualText(Format(Enum::"SCAExceptionType"::"Past Due Demand"), Format(ExceptionLine."Exception Type"), 'Wrong past-due type.');
        Assert.AreEqualText(Format(ExpectedRisk), Format(ExceptionLine."Risk Level"), 'Past-due risk mismatch.');
        Assert.AreEqualInteger(DaysPastDue, ExceptionLine."Days Late", 'Days late mismatch.');
        Assert.AreEqualDecimal(0, ExceptionLine."Shortage Qty. (Base)", 0.00001, 'Inventory should cover demand in this test.');
    end;

    var
        Assert: Codeunit "SCATestAssert";
        Library: Codeunit "SCATestLibrary";
}
