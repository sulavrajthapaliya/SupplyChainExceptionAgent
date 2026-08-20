namespace SupplyChain.ExceptionAgent;

enum 50300 "SCARiskLevel"
{
    Extensible = false;

    value(0; Low) { Caption = 'Low'; }
    value(1; Medium) { Caption = 'Medium'; }
    value(2; High) { Caption = 'High'; }
    value(3; Critical) { Caption = 'Critical'; }
}
