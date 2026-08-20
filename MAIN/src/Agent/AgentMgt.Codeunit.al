namespace SupplyChain.ExceptionAgent;

using System.Agents;

codeunit 50304 "SCAAgentMgt"
{
    Access = Public;

    procedure CreateAnalysisReviewTask(var AnalysisHeader: Record "SCAAnalysisHeader"): BigInteger
    var
        AgentTask: Record "Agent Task";
        AgentInstance: Record "SCAAgentInstance";
        Setup: Record "SCASetup";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        AgentUnavailableErr: Label 'Supply Chain Exception Agent is missing, archived, or inactive. Open the agent setup and enable/reconfigure it before creating a task.';
        AnalysisReviewPromptLbl: Label 'Review Supply Chain Exception Analysis %1. It contains %2 exception(s), including %3 critical and %4 high-risk exception(s), with aggregate peak shortage %5 base units. Prioritize up to %6 exceptions by risk. Use only the deterministic analysis values. Explain likely operational impact and recommend human actions. Do not create, release, post or modify any Business Central document.', Comment = '%1 = analysis entry number, %2 = exception count, %3 = critical exception count, %4 = high-risk exception count, %5 = aggregate peak shortage quantity, %6 = maximum exceptions to prioritize';
        AnalysisReviewTitleLbl: Label 'Supply chain exception review - analysis %1', Comment = '%1 = analysis entry number';
        NoAgentErr: Label 'Supply Chain Exception Agent is not configured. Open Copilot & agent capabilities and configure the agent first.';
        MessageText: Text;
    begin
        if not AgentInstance.FindFirst() then
            Error(NoAgentErr);

        if not CheckAgentIsActive(AgentInstance."User Security ID") then
            Error(AgentUnavailableErr);

        SetupMgt.GetSetup(Setup);

        MessageText :=
            StrSubstNo(
                AnalysisReviewPromptLbl,
                AnalysisHeader."Entry No.",
                AnalysisHeader."Exception Count",
                AnalysisHeader."Critical Count",
                AnalysisHeader."High Count",
                AnalysisHeader."Peak Shortage Qty. (Base)",
                Setup."Agent Top Exceptions");

        AgentTaskMessageBuilder.Initialize('Supply Chain Exceptions', MessageText);
        AgentTaskMessageBuilder.SetRequiresReview(false);

        AgentTask :=
            AgentTaskBuilder
                .Initialize(
                    AgentInstance."User Security ID",
                    StrSubstNo(AnalysisReviewTitleLbl, AnalysisHeader."Entry No."))
                .AddTaskMessage(AgentTaskMessageBuilder)
                .Create();

        AnalysisHeader."Agent Task ID" := AgentTask.ID;
        AnalysisHeader.Modify(true);

        exit(AgentTask.ID);
    end;

    procedure RunScanAndCreateTask(): BigInteger
    var
        AnalysisHeader: Record "SCAAnalysisHeader";
        AnalysisEntryNo: Integer;
    begin
        AnalysisEntryNo := ExceptionEngine.RunFullScan(false);
        AnalysisHeader.Get(AnalysisEntryNo);
        exit(CreateAnalysisReviewTask(AnalysisHeader));
    end;

    [TryFunction]
    local procedure CheckAgentIsActive(AgentUserSecurityId: Guid)
    var
        Agent: Codeunit Agent;
        AgentNotActiveErr: Label 'Agent is not active.';
    begin
        if not Agent.IsActive(AgentUserSecurityId) then
            Error(AgentNotActiveErr);
    end;

    var
        ExceptionEngine: Codeunit "SCAExceptionEngine";
        SetupMgt: Codeunit "SCASetupMgt";
}
