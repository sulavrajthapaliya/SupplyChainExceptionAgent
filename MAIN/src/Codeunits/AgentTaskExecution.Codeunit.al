namespace SupplyChain.ExceptionAgent;

using System.Agents;

codeunit 50303 "SCAAgentTaskExecution" implements IAgentTaskExecution
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure AnalyzeAgentTaskMessage(
        AgentTaskMessage: Record "Agent Task Message";
        var Annotations: Record "Agent Annotation")
    var
        AgentMessage: Codeunit "Agent Message";
        NotRelevantDetailsMsg: Label 'Supply Chain Exception Agent is intended to review shortages, overdue demand, late inbound supply and overdue purchase supply in Business Central.';
        NotRelevantMsg: Label 'This task does not appear to reference a supply chain exception review.';
        MessageText: Text;
    begin
        if AgentTaskMessage.Type <> AgentTaskMessage.Type::Input then
            exit;

        MessageText := LowerCase(AgentMessage.GetText(AgentTaskMessage));
        if (StrPos(MessageText, 'supply') = 0) and
           (StrPos(MessageText, 'shortage') = 0) and
           (StrPos(MessageText, 'sales order') = 0) and
           (StrPos(MessageText, 'purchase order') = 0) and
           (StrPos(MessageText, 'exception') = 0)
        then begin
            Annotations.Code := 'SCARELEVANCE001';
            Annotations.Severity := Annotations.Severity::Warning;
            Annotations.Message := NotRelevantMsg;
            Annotations.Details := NotRelevantDetailsMsg;
            Annotations.Insert();
        end;
    end;

    procedure GetAgentTaskUserInterventionSuggestions(
        AgentTaskUserInterventionRequestDetails: Record "Agent User Int Request Details";
        var AgentTaskUserInterventionSuggestion: Record "Agent Task User Int Suggestion")
    var
        ReviewExceptionDescriptionLbl: Label 'Use when a person needs to decide how to resolve a shortage, late supply or overdue demand.', Locked = true;
        ReviewExceptionInstructionsLbl: Label 'Open Current Supply Chain Exceptions, inspect the deterministic reason and recommendation, then decide whether to expedite, reallocate, replan or contact the customer/vendor.';
        ReviewExceptionLbl: Label 'Review supply chain exception';
        ReviewSetupDescriptionLbl: Label 'Use when the scan policy needs confirmation.', Locked = true;
        ReviewSetupInstructionsLbl: Label 'Open Supply Chain Exception Setup and verify horizon, risk thresholds and included document statuses.';
        ReviewSetupLbl: Label 'Review exception policy';
    begin
        if AgentTaskUserInterventionRequestDetails.Type =
           AgentTaskUserInterventionRequestDetails.Type::Assistance
        then begin
            AgentTaskUserInterventionSuggestion.Summary := ReviewExceptionLbl;
            AgentTaskUserInterventionSuggestion.Description := ReviewExceptionDescriptionLbl;
            AgentTaskUserInterventionSuggestion.Instructions := ReviewExceptionInstructionsLbl;
            AgentTaskUserInterventionSuggestion.Insert();

            AgentTaskUserInterventionSuggestion.Summary := ReviewSetupLbl;
            AgentTaskUserInterventionSuggestion.Description := ReviewSetupDescriptionLbl;
            AgentTaskUserInterventionSuggestion.Instructions := ReviewSetupInstructionsLbl;
            AgentTaskUserInterventionSuggestion.Insert();
        end;
    end;

    procedure GetAgentTaskPageContext(
        AgentTaskPageContextRequest: Record "Agent Task Page Context Req.";
        var AgentTaskPageContext: Record "Agent Task Page Context")
    begin
        // The agent works through the deterministic review workspace and analysis pages.
    end;
}
