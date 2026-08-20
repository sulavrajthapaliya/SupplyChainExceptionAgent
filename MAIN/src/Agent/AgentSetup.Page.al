namespace SupplyChain.ExceptionAgent;

using System.Agents;

page 50305 "SCAAgentSetup"
{
    AdditionalSearchTerms = 'AI supply chain agent, shortage agent, late supply agent';
    ApplicationArea = All;
    Caption = 'Configure Supply Chain Exception Agent';
    Extensible = false;
    InstructionalText = 'Configure the Business Central agent that reviews deterministic supply chain exception analyses.';
    PageType = ConfigurationDialog;
    RefreshOnActivate = true;
    SourceTable = "SCAAgentInstance";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            part(AgentSetupPart; "Agent Setup Part")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
            }
            group(Policy)
            {
                Caption = 'Exception policy';
                InstructionalText = 'The agent explains deterministic results. It does not calculate inventory itself and does not create, release, post or modify sales, purchase, transfer, production or planning documents.';

                field(OpenSupplyChainSetup; OpenSetupLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = StandardAccent;
                    ToolTip = 'Open Supply Chain Exception Setup.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"SCASetup");
                    end;
                }
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(OK)
            {
                Caption = 'Update';
                ToolTip = 'Apply the changes to the agent setup.';
            }
            systemaction(Cancel)
            {
                Caption = 'Cancel';
                ToolTip = 'Discard changes and close the setup page.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        InitializePage();
    end;

    trigger OnAfterGetRecord()
    begin
        InitializePage();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::Cancel then
            exit(true);

        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(AgentSetupBuffer);
        SaveSetup();
        exit(true);
    end;

    local procedure InitializePage()
    var
        ExistingInstance: Record "SCAAgentInstance";
        AgentSetup: Codeunit "Agent Setup";
    begin
        if not IsNullGuid(Rec."User Security ID") then
            if ExistingInstance.Get(Rec."User Security ID") then
                Rec.TransferFields(ExistingInstance, false);

        if Rec.IsEmpty() then
            Rec.Insert();

        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(AgentSetupBuffer);
        if AgentSetupBuffer.IsEmpty() then
            AgentSetup.GetSetupRecord(
                AgentSetupBuffer,
                Rec."User Security ID",
                Enum::"Agent Metadata Provider"::SCASupplyChainExceptions_SCA,
                'SUPPLYCHAIN',
                'Supply Chain Exception Agent',
                'Reviews shortages, overdue demand, late inbound supply and overdue purchase receipts using deterministic Business Central analysis.');

        CurrPage.AgentSetupPart.Page.SetAgentSetupBuffer(AgentSetupBuffer);
    end;

    local procedure SaveSetup()
    var
        ExistingInstance: Record "SCAAgentInstance";
        Agent: Codeunit Agent;
        AgentSetup: Codeunit "Agent Setup";
        InstructionsFileLbl: Label 'Instructions.txt', Locked = true;
        Instructions: SecretText;
    begin
        if AgentSetup.GetChangesMade(AgentSetupBuffer) then
            Rec."User Security ID" := AgentSetup.SaveChanges(AgentSetupBuffer)
        else
            Rec."User Security ID" := AgentSetupBuffer."User Security ID";

        if IsNullGuid(Rec."User Security ID") then
            exit;

        Instructions := NavApp.GetResourceAsText(InstructionsFileLbl);
        Agent.SetInstructions(Rec."User Security ID", Instructions);

        if ExistingInstance.Get(Rec."User Security ID") then
            exit;

        ExistingInstance.Init();
        ExistingInstance."User Security ID" := Rec."User Security ID";
        ExistingInstance.Insert();
    end;

    var
        AgentSetupBuffer: Record "Agent Setup Buffer";
        OpenSetupLbl: Label 'Open Supply Chain Exception Setup';
}
