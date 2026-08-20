namespace SupplyChain.ExceptionAgent;

table 50301 "SCAAgentInstance"
{
    Caption = 'Supply Chain Exception Agent Instance';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the security ID of the user associated with this agent instance.';
        }
    }

    keys
    {
        key(PK; "User Security ID") { Clustered = true; }
    }
}
