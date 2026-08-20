namespace SupplyChain.ExceptionAgent;

page 50300 "SCASetup"
{
    AdditionalSearchTerms = 'supply chain agent setup, shortage policy, exception policy';
    ApplicationArea = All;
    Caption = 'Supply Chain Exception Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "SCASetup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(Analysis)
            {
                Caption = 'Analysis';
                field("Horizon Days"; Rec."Horizon Days")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many days ahead sales demand is analyzed.';
                }
                field("Maximum Exceptions Per Scan"; Rec."Maximum Exceptions Per Scan")
                {
                    ApplicationArea = All;
                    ToolTip = 'Limits the number of exception lines created by one scan.';
                }
                field("Minimum Shortage Qty. (Base)"; Rec."Minimum Shortage Qty. (Base)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Ignores shortages at or below this base quantity.';
                }
            }
            group(Risk)
            {
                Caption = 'Risk thresholds';
                field("High Shortage %"; Rec."High Shortage %") { ApplicationArea = All; }
                field("Critical Shortage %"; Rec."Critical Shortage %") { ApplicationArea = All; }
                field("High Past Due Days"; Rec."High Past Due Days") { ApplicationArea = All; }
                field("Critical Past Due Days"; Rec."Critical Past Due Days") { ApplicationArea = All; }
                field("Late Receipt Grace Days"; Rec."Late Receipt Grace Days") { ApplicationArea = All; }
            }
            group(Scope)
            {
                Caption = 'Document scope';
                field("Include Open Sales Orders"; Rec."Include Open Sales Orders") { ApplicationArea = All; }
                field("Include Released Sales Orders"; Rec."Include Released Sales Orders") { ApplicationArea = All; }
                field("Include Open Purchase Orders"; Rec."Include Open Purchase Orders") { ApplicationArea = All; }
                field("Include Released PO"; Rec."Include Released PO") { ApplicationArea = All; }
            }
            group(Agent)
            {
                Caption = 'Agent';
                field("Agent Top Exceptions"; Rec."Agent Top Exceptions")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many top exceptions the agent should prioritize in a review.';
                }
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
            action(RunScanAndSendToAgent)
            {
                ApplicationArea = All;
                Caption = 'Run Scan and Send to Agent';
                Image = Task;
                ToolTip = 'Run a full deterministic scan and create an agent review task.';
                trigger OnAction()
                var
                    AgentMgt: Codeunit "SCAAgentMgt";
                    TaskId: BigInteger;
                    TaskCreatedMsg: Label 'Agent task %1 was created.';
                begin
                    TaskId := AgentMgt.RunScanAndCreateTask();
                    Message(TaskCreatedMsg, TaskId);
                end;
            }
            action(ConfigureAgent)
            {
                ApplicationArea = All;
                Caption = 'Configure Agent';
                Image = Setup;
                ToolTip = 'Configure the Supply Chain Exception Agent.';
                trigger OnAction()
                begin
                    Page.Run(Page::"SCAAgentSetup");
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        SetupMgt: Codeunit "SCASetupMgt";
    begin
        SetupMgt.GetSetup(Rec);
    end;

    trigger OnModifyRecord(): Boolean
    var
        SetupMgt: Codeunit "SCASetupMgt";
    begin
        SetupMgt.ValidateSetup(Rec);
        exit(true);
    end;
}
