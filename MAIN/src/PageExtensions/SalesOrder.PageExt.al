namespace SupplyChain.ExceptionAgent;

using Microsoft.Sales.Document;
using System.Agents;

pageextension 50300 "SCASalesOrder" extends "Sales Order"
{
    layout
    {
        addfirst(factboxes)
        {
            part(SCASupplyRiskFactBox_SCA; "SCASalesOrderRiskFactBox")
            {
                ApplicationArea = All;
                Caption = 'Supply Chain Risk';
                SubPageLink = "Document Type" = field("Document Type"),
                              "No." = field("No.");
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            group(SCASupplyChainExceptions_SCA)
            {
                Caption = 'Supply Chain Exceptions';
                Image = AnalysisView;

                action(SCAAnalyzeSupplyRisk_SCA)
                {
                    ApplicationArea = All;
                    Caption = 'Analyze Supply Risk';
                    Image = AnalysisView;
                    ToolTip = 'Analyze inventory and inbound purchase supply, create an agent review task, and update the Supply Chain Risk FactBox.';

                    trigger OnAction()
                    var
                        AnalysisHeader: Record "SCAAnalysisHeader";
                        AgentMgt: Codeunit "SCAAgentMgt";
                        Engine: Codeunit "SCAExceptionEngine";
                        s: page "Agent Card";
                        TaskCreatedNotification: Notification;
                        TaskId: BigInteger;
                        AnalysisEntryNo: Integer;
                        TaskCreatedMsg: Label 'Supply risk analysis %1 created agent task %2 for sales order %3.', Comment = '%1 = analysis entry number, %2 = agent task ID, %3 = sales order number';
                    begin
                        AnalysisEntryNo := Engine.AnalyzeSalesOrder(Rec, false);
                        AnalysisHeader.Get(AnalysisEntryNo);
                        TaskId := AgentMgt.CreateAnalysisReviewTask(AnalysisHeader);

                        TaskCreatedNotification.Message :=
                            StrSubstNo(TaskCreatedMsg, AnalysisEntryNo, TaskId, Rec."No.");
                        TaskCreatedNotification.Scope := NotificationScope::LocalScope;
                        TaskCreatedNotification.Send();

                        CurrPage.Update(false);
                        CurrPage.SCASupplyRiskFactBox_SCA.Page.RefreshFactBox();
                    end;
                }
            }
        }
    }
}
