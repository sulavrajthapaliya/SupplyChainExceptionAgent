namespace SupplyChain.ExceptionAgent;

page 50301 "SCAAnalyses"
{
    AdditionalSearchTerms = 'supply chain exceptions, shortage analysis, late supply';
    ApplicationArea = All;
    Caption = 'Supply Chain Exception Analyses';
    CardPageId = "SCAAnalysisCard";
    DeleteAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "SCAAnalysisHeader";
    SourceTableView = sorting("Entry No.") order(descending);
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Analyses)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Analysis Date"; Rec."Analysis Date") { ApplicationArea = All; }
                field(Scope; Rec.Scope) { ApplicationArea = All; }
                field("Source Document No."; Rec."Source Document No.") { ApplicationArea = All; }
                field("Highest Risk Level"; Rec."Highest Risk Level")
                {
                    ApplicationArea = All;
                    StyleExpr = RiskStyle;
                }
                field("Exception Count"; Rec."Exception Count") { ApplicationArea = All; }
                field("Critical Count"; Rec."Critical Count") { ApplicationArea = All; }
                field("High Count"; Rec."High Count") { ApplicationArea = All; }
                field("Peak Shortage Qty. (Base)"; Rec."Peak Shortage Qty. (Base)") { ApplicationArea = All; }
                field("Was Truncated"; Rec."Was Truncated") { ApplicationArea = All; }
                field("Analyzed At"; Rec."Analyzed At") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunFullScan)
            {
                ApplicationArea = All;
                Caption = 'Run Full Scan';
                Image = AnalysisView;
                ToolTip = 'Run a deterministic supply chain exception scan.';
                trigger OnAction()
                var
                    Engine: Codeunit "SCAExceptionEngine";
                begin
                    Engine.RunFullScan(true);
                end;
            }
            action(SendToAgent)
            {
                ApplicationArea = All;
                Caption = 'Send to Agent';
                Image = Task;
                ToolTip = 'Create an agent task to review the selected supply chain exception analysis.';
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
