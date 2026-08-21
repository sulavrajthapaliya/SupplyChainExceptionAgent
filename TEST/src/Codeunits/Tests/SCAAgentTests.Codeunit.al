namespace SupplyChain.ExceptionAgent.Tests;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using SupplyChain.ExceptionAgent;

codeunit 50414 "SCAAgentTests"
{
    Subtype = Test;
    RequiredTestIsolation = Function;
    TestType = IntegrationTest;

    [Test]
    procedure MissingAgentConfigurationReturnsFriendlyError()
    var
        AgentInstance: Record "SCAAgentInstance";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
    begin
        Library.Initialize();
        AgentInstance.DeleteAll(false);
        Library.CreateItem(Item);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');
        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        asserterror AgentMgt.CreateAnalysisReviewTask(AnalysisHeader);
        Assert.Contains(GetLastErrorText(), 'not configured', 'Missing agent should return a user-friendly configuration error.');
    end;

    [Test]
    procedure StaleAgentGuidReturnsFriendlyError()
    var
        AgentInstance: Record "SCAAgentInstance";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisHeader: Record "SCAAnalysisHeader";
    begin
        Library.Initialize();
        AgentInstance.DeleteAll(false);
        AgentInstance.Init();
        AgentInstance."User Security ID" := CreateGuid();
        AgentInstance.Insert(false);
        Library.CreateItem(Item);
        Library.CreateSalesOrder(SalesHeader, SalesLine, Item."No.", 100, CalcDate('<+5D>', WorkDate()), '', '');
        Library.AnalyzeSalesOrder(SalesHeader, AnalysisHeader);

        asserterror AgentMgt.CreateAnalysisReviewTask(AnalysisHeader);
        Assert.Contains(GetLastErrorText(), 'missing, archived, or inactive', 'Stale agent GUID should be translated into the app-level error.');
    end;

    var
        Library: Codeunit "SCATestLibrary";
        Assert: Codeunit "SCATestAssert";
        AgentMgt: Codeunit "SCAAgentMgt";
}
