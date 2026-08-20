namespace SupplyChain.ExceptionAgent.Tests;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using SupplyChain.ExceptionAgent;

permissionset 50400 "SCATEST"
{
    Assignable = true;
    Caption = 'Supply Chain Exception Automated Tests';

    Permissions =
        tabledata Item = RIMD,
        tabledata "Item Ledger Entry" = RIMD,
        tabledata "Sales Header" = RIMD,
        tabledata "Sales Line" = RIMD,
        tabledata "Purchase Header" = RIMD,
        tabledata "Purchase Line" = RIMD,
        tabledata "SCASetup" = RIMD,
        tabledata "SCAAgentInstance" = RIMD,
        tabledata "SCAAnalysisHeader" = RIMD,
        tabledata "SCAExceptionLine" = RIMD,
        table "SCASetup" = X,
        table "SCAAgentInstance" = X,
        table "SCAAnalysisHeader" = X,
        table "SCAExceptionLine" = X,
        codeunit "SCASetupMgt" = X,
        codeunit "SCAExceptionEngine" = X,
        codeunit "SCAAgentMgt" = X,
        codeunit "SCATestAssert" = X,
        codeunit "SCATestEventSubscriber" = X,
        codeunit "SCATestLibrary" = X,
        codeunit "SCASetupTests" = X,
        codeunit "SCADemandTests" = X,
        codeunit "SCAExtensibilityTests" = X,
        codeunit "SCAFullScanTests" = X,
        codeunit "SCAAgentTests" = X;
}
