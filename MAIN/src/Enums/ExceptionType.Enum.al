namespace SupplyChain.ExceptionAgent;

enum 50301 "SCAExceptionType"
{
    Extensible = false;

    value(0; "Inventory Shortage") { Caption = 'Inventory Shortage'; }
    value(1; "Late Inbound Supply") { Caption = 'Late Inbound Supply'; }
    value(2; "No Inbound Supply") { Caption = 'No Inbound Supply'; }
    value(3; "Past Due Demand") { Caption = 'Past Due Demand'; }
    value(4; "Overdue Purchase Supply") { Caption = 'Overdue Purchase Supply'; }
}
