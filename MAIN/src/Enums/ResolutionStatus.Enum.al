namespace SupplyChain.ExceptionAgent;

enum 50304 "SCAResolutionStatus"
{
    Extensible = false;

    value(0; Open) { Caption = 'Open'; }
    value(1; "In Review") { Caption = 'In Review'; }
    value(2; Resolved) { Caption = 'Resolved'; }
    value(3; Dismissed) { Caption = 'Dismissed'; }
}
