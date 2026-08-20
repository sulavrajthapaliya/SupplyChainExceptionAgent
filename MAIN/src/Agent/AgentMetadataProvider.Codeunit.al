namespace SupplyChain.ExceptionAgent;

using System.Agents;
using System.AI;
using System.Reflection;
using System.Security.AccessControl;

codeunit 50302 "SCAAgentMetadataProvider" implements IAgentMetadata, IAgentFactory
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetDefaultInitials(): Text[4]
    begin
        exit('SCE');
    end;

    procedure GetInitials(AgentUserId: Guid): Text[4]
    begin
        exit('SCE');
    end;

    procedure GetFirstTimeSetupPageId(): Integer
    begin
        exit(Page::"SCAAgentSetup");
    end;

    procedure GetSetupPageId(AgentUserId: Guid): Integer
    begin
        exit(Page::"SCAAgentSetup");
    end;

    procedure GetSummaryPageId(AgentUserId: Guid): Integer
    begin
        exit(0);
    end;

    procedure ShowCanCreateAgent(): Boolean
    var
        AgentInstance: Record "SCAAgentInstance";
    begin
        exit(AgentInstance.IsEmpty());
    end;

    procedure GetCopilotCapability(): Enum "Copilot Capability"
    begin
        exit(Enum::"Copilot Capability"::"SCASupplyChainExceptions");
    end;

    procedure GetAgentAnnotations(AgentUserId: Guid; var Annotations: Record "Agent Annotation")
    var
        Setup: Record "SCASetup";
        SetupMgt: Codeunit "SCASetupMgt";
        SetupWarningDetailsMsg: Label 'Open Supply Chain Exception Setup and verify horizon, shortage thresholds, overdue thresholds and included document statuses.';
        SetupWarningMsg: Label 'Review the Supply Chain Exception policy before using this agent.';
    begin
        Clear(Annotations);
        SetupMgt.GetSetup(Setup);

        if (Setup."Horizon Days" <= 0) or (Setup."Maximum Exceptions Per Scan" <= 0) then begin
            Annotations.Code := 'SCASETUP001';
            Annotations.Severity := Annotations.Severity::Warning;
            Annotations.Message := SetupWarningMsg;
            Annotations.Details := SetupWarningDetailsMsg;
            Annotations.Insert();
        end;
    end;

    procedure GetAgentTaskMessagePageId(AgentUserId: Guid; MessageId: Guid): Integer
    begin
        exit(Page::"Agent Task Message Card");
    end;

    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    var
        Agent: Codeunit Agent;
        CurrentModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModule);
        Agent.PopulateDefaultProfile('SCAAGENT', CurrentModule.Id, TempAllProfile);
    end;

    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        CurrentModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModule);

        TempAccessControlBuffer.Init();
        TempAccessControlBuffer."Company Name" :=
            CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := CurrentModule.Id;
        TempAccessControlBuffer."Role ID" := 'SCAAGENT';
        TempAccessControlBuffer.Insert();
    end;
}
