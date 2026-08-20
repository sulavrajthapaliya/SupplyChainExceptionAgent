namespace SupplyChain.ExceptionAgent;

using System.Agents;

enumextension 50301 "SCAAgentMetadataProvider" extends "Agent Metadata Provider"
{
    value(50300; "SCASupplyChainExceptions")
    {
        Caption = 'Supply Chain Exception Agent';
        Implementation =
            IAgentFactory = "SCAAgentMetadataProvider",
            IAgentMetadata = "SCAAgentMetadataProvider",
            IAgentTaskExecution = "SCAAgentTaskExecution";
    }
}
