namespace SupplyChain.ExceptionAgent;

using System.AI;

codeunit 50305 "SCAInstall"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapability();
    end;

    trigger OnInstallAppPerCompany()
    var
        Setup: Record "SCASetup";
        SetupMgt: Codeunit "SCASetupMgt";
    begin
        SetupMgt.GetSetup(Setup);
    end;

    local procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        LearnMoreUrlLbl: Label 'https://YOUR-DOMAIN.example/supply-chain-exception-agent', Locked = true;
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"SCASupplyChainExceptions") then
            CopilotCapability.RegisterCapability(
                Enum::"Copilot Capability"::"SCASupplyChainExceptions",
                Enum::"Copilot Availability"::Preview,
                Enum::"Copilot Billing Type"::"Microsoft Billed",
                LearnMoreUrlLbl);
    end;
}
