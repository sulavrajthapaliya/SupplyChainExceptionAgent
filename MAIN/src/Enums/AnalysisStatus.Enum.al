namespace SupplyChain.ExceptionAgent;

enum 50303 "SCAAnalysisStatus"
{
    Extensible = false;

    value(0; Open) { Caption = 'Open'; }
    value(1; Reviewed) { Caption = 'Reviewed'; }
    value(2; Dismissed) { Caption = 'Dismissed'; }
}
