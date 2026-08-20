namespace SupplyChain.ExceptionAgent;

table 50300 "SCASetup"
{
    Caption = 'Supply Chain Exception Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the identifier of the supply chain exception setup record.';
        }
        field(2; "Horizon Days"; Integer)
        {
            Caption = 'Horizon Days';
            DataClassification = CustomerContent;
            InitValue = 30;
            MinValue = 1;
            ToolTip = 'Specifies how many days ahead sales demand is analyzed.';
        }
        field(3; "High Shortage %"; Decimal)
        {
            Caption = 'High Shortage %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            InitValue = 20;
            MaxValue = 100;
            MinValue = 0;
            ToolTip = 'Specifies the shortage percentage at which an exception is assigned a high risk level.';
        }
        field(4; "Critical Shortage %"; Decimal)
        {
            Caption = 'Critical Shortage %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            InitValue = 50;
            MaxValue = 100;
            MinValue = 0;
            ToolTip = 'Specifies the shortage percentage at which an exception is assigned a critical risk level.';
        }
        field(5; "High Past Due Days"; Integer)
        {
            Caption = 'High Past Due Days';
            DataClassification = CustomerContent;
            InitValue = 3;
            MinValue = 0;
            ToolTip = 'Specifies the number of days that demand must be past due to be assigned a high risk level.';
        }
        field(6; "Critical Past Due Days"; Integer)
        {
            Caption = 'Critical Past Due Days';
            DataClassification = CustomerContent;
            InitValue = 7;
            MinValue = 0;
            ToolTip = 'Specifies the number of days that demand must be past due to be assigned a critical risk level.';
        }
        field(7; "Minimum Shortage Qty. (Base)"; Decimal)
        {
            Caption = 'Minimum Shortage Qty. (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            InitValue = 0.00001;
            MinValue = 0;
            ToolTip = 'Specifies the minimum shortage quantity in the base unit of measure that is reported as an exception.';
        }
        field(8; "Late Receipt Grace Days"; Integer)
        {
            Caption = 'Late Receipt Grace Days';
            DataClassification = CustomerContent;
            InitValue = 0;
            MinValue = 0;
            ToolTip = 'Specifies the number of days after the demand date that an inbound receipt can arrive before it is considered late.';
        }
        field(9; "Maximum Exceptions Per Scan"; Integer)
        {
            Caption = 'Maximum Exceptions Per Scan';
            DataClassification = CustomerContent;
            InitValue = 500;
            MinValue = 1;
            ToolTip = 'Specifies the maximum number of exception lines that one scan can create.';
        }
        field(10; "Agent Top Exceptions"; Integer)
        {
            Caption = 'Agent Top Exceptions';
            DataClassification = CustomerContent;
            InitValue = 20;
            MaxValue = 100;
            MinValue = 1;
            ToolTip = 'Specifies how many top exceptions the agent prioritizes in a review.';
        }
        field(11; "Include Open Sales Orders"; Boolean)
        {
            Caption = 'Include Open Sales Orders';
            DataClassification = CustomerContent;
            InitValue = true;
            ToolTip = 'Specifies whether open sales orders are included as demand in the analysis.';
        }
        field(12; "Include Released Sales Orders"; Boolean)
        {
            Caption = 'Include Released Sales Orders';
            DataClassification = CustomerContent;
            InitValue = true;
            ToolTip = 'Specifies whether released sales orders are included as demand in the analysis.';
        }
        field(13; "Include Open Purchase Orders"; Boolean)
        {
            Caption = 'Include Open Purchase Orders';
            DataClassification = CustomerContent;
            InitValue = true;
            ToolTip = 'Specifies whether open purchase orders are included as inbound supply in the analysis.';
        }
        field(14; "Include Released PO"; Boolean)
        {
            Caption = 'Include Released Purchase Orders';
            DataClassification = CustomerContent;
            InitValue = true;
            ToolTip = 'Specifies whether released purchase orders are included as inbound supply in the analysis.';
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
