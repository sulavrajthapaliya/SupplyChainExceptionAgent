namespace SupplyChain.ExceptionAgent;

using Microsoft.Sales.Document;

page 50302 "SCAAnalysisCard"
{
    ApplicationArea = All;
    Caption = 'Supply Chain Exception Analysis';
    DeleteAllowed = false;
    Editable = false;
    PageType = Card;
    SourceTable = "SCAAnalysisHeader";
    UsageCategory = Administration;
    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Scope; Rec.Scope) { ApplicationArea = All; }
                field("Source Document No."; Rec."Source Document No.") { ApplicationArea = All; }
                field("Analysis Date"; Rec."Analysis Date") { ApplicationArea = All; }
                field("Horizon End Date"; Rec."Horizon End Date") { ApplicationArea = All; }
                field("Highest Risk Level"; Rec."Highest Risk Level")
                {
                    ApplicationArea = All;
                    StyleExpr = RiskStyle;
                }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Was Truncated"; Rec."Was Truncated") { ApplicationArea = All; }
            }
            group(Summary)
            {
                Caption = 'Summary';
                field("Exception Count"; Rec."Exception Count") { ApplicationArea = All; }
                field("Critical Count"; Rec."Critical Count") { ApplicationArea = All; }
                field("High Count"; Rec."High Count") { ApplicationArea = All; }
                field("Medium Count"; Rec."Medium Count") { ApplicationArea = All; }
                field("Low Count"; Rec."Low Count") { ApplicationArea = All; }
                field("Peak Shortage Qty. (Base)"; Rec."Peak Shortage Qty. (Base)") { ApplicationArea = All; }
            }
            part(Lines; "SCAExceptionLines")
            {
                ApplicationArea = All;
                SubPageLink = "Analysis Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SendToAgent)
            {
                ApplicationArea = All;
                Caption = 'Send to Agent';
                Image = Task;
                ToolTip = 'Create an agent task to review this supply chain exception analysis.';
                trigger OnAction()
                var
                    AgentMgt: Codeunit "SCAAgentMgt";
                    TaskId: BigInteger;
                    TaskCreatedMsg: Label 'Agent task %1 was created.', Comment = '%1 is the task ID.';
                begin
                    TaskId := AgentMgt.CreateAnalysisReviewTask(Rec);
                    Message(TaskCreatedMsg, TaskId);
                end;
            }
            action(MarkReviewed)
            {
                ApplicationArea = All;
                Caption = 'Mark Reviewed';
                Image = Approve;
                ToolTip = 'Mark this supply chain exception analysis as reviewed.';
                trigger OnAction()
                var
                    Header: Record "SCAAnalysisHeader";
                begin
                    Header.Get(Rec."Entry No.");
                    Header.Status := Header.Status::Reviewed;
                    Header.Modify(true);
                    Rec := Header;
                    CurrPage.Update(false);
                end;
            }
            action(OpenSalesOrder)
            {
                ApplicationArea = All;
                Caption = 'Open Sales Order';
                Enabled = Rec."Source Document No." <> '';
                Image = Document;
                ToolTip = 'Open the sales order associated with this supply chain exception analysis.';
                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    if SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Source Document No.") then
                        Page.Run(Page::"Sales Order", SalesHeader);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetRiskStyle();
    end;

    local procedure SetRiskStyle()
    begin
        case Rec."Highest Risk Level" of
            Rec."Highest Risk Level"::Critical:
                RiskStyle := 'Unfavorable';
            Rec."Highest Risk Level"::High:
                RiskStyle := 'Attention';
            Rec."Highest Risk Level"::Medium:
                RiskStyle := 'Ambiguous';
            else
                RiskStyle := 'Favorable';
        end;
    end;

    var
        RiskStyle: Text;
}
