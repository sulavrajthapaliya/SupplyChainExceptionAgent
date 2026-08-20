namespace SupplyChain.ExceptionAgent;

using Microsoft.Sales.Document;
using System.Agents;

page 50306 "SCASalesOrderRiskFactBox"
{
    ApplicationArea = All;
    Caption = 'Supply Chain Risk';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    PageType = CardPart;
    SourceTable = "Sales Header";

    layout
    {
        area(Content)
        {
            group(Analysis)
            {
                Caption = 'Latest analysis';

                field(AnalysisEntryNo; AnalysisEntryNo)
                {
                    Caption = 'Analysis';
                    ToolTip = 'Specifies the latest supply chain exception analysis for this sales order. Select the value to open the analysis.';

                    trigger OnDrillDown()
                    begin
                        OpenAnalysis();
                    end;
                }
                field(HighestRiskLevel; HighestRiskLevel)
                {
                    Caption = 'Highest Risk';
                    StyleExpr = RiskStyle;
                    ToolTip = 'Specifies the highest risk level in the latest analysis.';
                }
                field(ExceptionCount; ExceptionCount)
                {
                    Caption = 'Exceptions';
                    ToolTip = 'Specifies the number of exceptions found in the latest analysis.';
                }
                field(CriticalCount; CriticalCount)
                {
                    Caption = 'Critical';
                    Style = Unfavorable;
                    ToolTip = 'Specifies the number of critical-risk exceptions found in the latest analysis.';
                }
                field(HighCount; HighCount)
                {
                    Caption = 'High';
                    Style = Attention;
                    ToolTip = 'Specifies the number of high-risk exceptions found in the latest analysis.';
                }
                field(AnalyzedAt; AnalyzedAt)
                {
                    Caption = 'Analyzed At';
                    ToolTip = 'Specifies when the latest analysis was performed.';
                }
            }
            group(AgentTaskDetails)
            {
                Caption = 'Agent task';

                field(AgentTaskId; AgentTaskId)
                {
                    Caption = 'Task ID';
                    ExtendedDatatype = Task;
                    ToolTip = 'Specifies the agent task created for the latest analysis. Select the value to open the task.';

                    trigger OnDrillDown()
                    begin
                        OpenAgentTask();
                    end;
                }
                field(AgentTaskStatus; AgentTaskStatus)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies the current status of the agent task.';
                }
                field(AgentTaskNeedsAttention; AgentTaskNeedsAttention)
                {
                    Caption = 'Needs Attention';
                    StyleExpr = AttentionStyle;
                    ToolTip = 'Specifies whether the agent task requires user attention.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadLatestAnalysis();
    end;

    procedure RefreshFactBox()
    begin
        LoadLatestAnalysis();
        CurrPage.Update(false);
    end;

    local procedure LoadLatestAnalysis()
    var
        CurrentAgentTask: Record "Agent Task";
        Engine: Codeunit "SCAExceptionEngine";
    begin
        ClearFactBox();

        if not Engine.GetLatestAnalysis(Enum::"SCAScanScope"::"Sales Order", Rec."No.", AnalysisHeader) then
            exit;

        AnalysisEntryNo := AnalysisHeader."Entry No.";
        HighestRiskLevel := AnalysisHeader."Highest Risk Level";
        ExceptionCount := AnalysisHeader."Exception Count";
        CriticalCount := AnalysisHeader."Critical Count";
        HighCount := AnalysisHeader."High Count";
        AnalyzedAt := AnalysisHeader."Analyzed At";
        AgentTaskId := AnalysisHeader."Agent Task ID";
        SetRiskStyle();

        if (AgentTaskId <> 0) and CurrentAgentTask.Get(AgentTaskId) then begin
            AgentTaskStatus := Format(CurrentAgentTask.Status);
            AgentTaskNeedsAttention := CurrentAgentTask."Needs Attention";
            if AgentTaskNeedsAttention then
                AttentionStyle := 'Unfavorable';
        end;
    end;

    local procedure ClearFactBox()
    begin
        Clear(AnalysisHeader);
        Clear(AnalysisEntryNo);
        Clear(HighestRiskLevel);
        Clear(ExceptionCount);
        Clear(CriticalCount);
        Clear(HighCount);
        Clear(AnalyzedAt);
        Clear(AgentTaskId);
        Clear(AgentTaskStatus);
        Clear(AgentTaskNeedsAttention);
        Clear(RiskStyle);
        Clear(AttentionStyle);
    end;

    local procedure OpenAnalysis()
    begin
        if AnalysisEntryNo = 0 then
            exit;

        AnalysisHeader.Get(AnalysisEntryNo);
        Page.Run(Page::"SCAAnalysisCard", AnalysisHeader);
    end;

    local procedure OpenAgentTask()
    var
        CurrentAgentTask: Record "Agent Task";
    begin
        if AgentTaskId = 0 then
            exit;

        CurrentAgentTask.SetRange(ID, AgentTaskId);
        Page.Run(Page::"Agent Task List", CurrentAgentTask);
    end;

    local procedure SetRiskStyle()
    begin
        case HighestRiskLevel of
            HighestRiskLevel::Critical:
                RiskStyle := 'Unfavorable';
            HighestRiskLevel::High:
                RiskStyle := 'Attention';
            HighestRiskLevel::Medium:
                RiskStyle := 'Ambiguous';
            else
                RiskStyle := 'Favorable';
        end;
    end;

    var
        AnalysisHeader: Record "SCAAnalysisHeader";
        HighestRiskLevel: Enum "SCARiskLevel";
        AgentTaskId: BigInteger;
        AnalysisEntryNo: Integer;
        CriticalCount: Integer;
        ExceptionCount: Integer;
        HighCount: Integer;
        AnalyzedAt: DateTime;
        AgentTaskNeedsAttention: Boolean;
        AgentTaskStatus: Text;
        AttentionStyle: Text;
        RiskStyle: Text;
}
