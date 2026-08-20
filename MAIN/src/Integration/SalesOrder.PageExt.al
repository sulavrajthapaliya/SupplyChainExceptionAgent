namespace SupplyChain.ExceptionAgent;

using Microsoft.Sales.Document;

pageextension 50300 "SCASalesOrder" extends "Sales Order"
{
    actions
    {
        addlast(Processing)
        {
            group(SCASupplyChainExceptions)
            {
                Caption = 'Supply Chain Exceptions';
                Image = AnalysisView;

                action(SCAAnalyzeSupplyRisk)
                {
                    ApplicationArea = All;
                    Caption = 'Analyze Supply Risk';
                    Image = AnalysisView;
                    ToolTip = 'Analyze inventory and inbound purchase supply against this sales order and open the deterministic exception analysis.';

                    trigger OnAction()
                    var
                        Engine: Codeunit "SCAExceptionEngine";
                    begin
                        Engine.AnalyzeSalesOrder(Rec, true);
                    end;
                }
            }
        }
    }
}
