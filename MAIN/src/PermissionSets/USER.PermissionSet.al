namespace SupplyChain.ExceptionAgent;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Agents;

permissionset 50300 "SCAUSER"
{
    Assignable = true;
    Caption = 'Supply Chain Exception User';

    Permissions =
        tabledata "SCAAgentInstance" = R,
        table "SCAAnalysisHeader" = X,
        tabledata "SCAAnalysisHeader" = RIM,
        table "SCAExceptionLine" = X,
        tabledata "SCAExceptionLine" = RIM,
        tabledata "SCASetup" = R,
        tabledata "Agent Task" = R,
        codeunit "SCAAgentMgt" = X,
        codeunit "SCAExceptionEngine" = X,
        codeunit "SCASetupMgt" = X,
        page "SCAAnalyses" = X,
        page "SCAAnalysisCard" = X,
        page "SCAExceptionLines" = X,
        page "SCAReviewWorkspace" = X,
        page "SCASalesOrderRiskFactBox" = X;
}

permissionset 50301 "SCAADMIN"
{
    Assignable = true;
    Caption = 'Supply Chain Exception Administrator';
    IncludedPermissionSets = "SCAUSER";

    Permissions =
        table "SCAAgentInstance" = X,
        tabledata "SCAAgentInstance" = RIMD,
        table "SCASetup" = X,
        tabledata "SCASetup" = RIMD,
        page "SCAAgentSetup" = X,
        page "SCASetup" = X;
}

permissionset 50302 "SCAAGENT"
{
    Assignable = false;
    Caption = 'Supply Chain Exception Agent';

    Permissions =
        tabledata Customer = R,
        tabledata Item = R,
        tabledata Location = R,
        tabledata "Purchase Header" = R,
        tabledata "Purchase Line" = R,
        tabledata "Sales Header" = R,
        tabledata "Sales Line" = R,
        tabledata "SCAAgentInstance" = R,
        tabledata "SCAAnalysisHeader" = RIM,
        tabledata "SCAExceptionLine" = RIM,
        tabledata "SCASetup" = R,
        tabledata Vendor = R,
        codeunit "SCAExceptionEngine" = X,
        codeunit "SCASetupMgt" = X,
        page "Purchase Order" = X,
        page "Purchase Order List" = X,
        page "Sales Order" = X,
        page "Sales Order List" = X,
        page "SCAAnalyses" = X,
        page "SCAAnalysisCard" = X,
        page "SCAExceptionLines" = X,
        page "SCAReviewWorkspace" = X;
}
