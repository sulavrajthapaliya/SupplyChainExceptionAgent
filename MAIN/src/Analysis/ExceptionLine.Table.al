namespace SupplyChain.ExceptionAgent;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 50303 "SCAExceptionLine"
{
    Caption = 'Supply Chain Exception';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Analysis Entry No."; Integer)
        {
            Caption = 'Analysis Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "SCAAnalysisHeader"."Entry No.";
            ToolTip = 'Specifies the analysis that produced this exception.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the unique line number of the exception within the analysis.';
        }
        field(3; "Exception Type"; Enum "SCAExceptionType")
        {
            Caption = 'Exception Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the type of supply chain exception that was detected.';
        }
        field(4; "Risk Level"; Enum "SCARiskLevel")
        {
            Caption = 'Risk Level';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the risk level assigned to the exception.';
        }
        field(5; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";
            ToolTip = 'Specifies the item affected by the exception.';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the description of the item affected by the exception.';
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
            ToolTip = 'Specifies the location at which demand and supply were analyzed.';
        }
        field(8; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the item variant affected by the exception.';
        }
        field(9; "Demand Document No."; Code[20])
        {
            Caption = 'Demand Document No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the sales order number that generated the demand.';
        }
        field(10; "Demand Line No."; Integer)
        {
            Caption = 'Demand Line No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the line number on the sales order that generated the demand.';
        }
        field(11; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            DataClassification = CustomerContent;
            TableRelation = Customer."No.";
            ToolTip = 'Specifies the customer associated with the demand.';
        }
        field(12; "Demand Date"; Date)
        {
            Caption = 'Demand Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the shipment date by which the demand is required.';
        }
        field(13; "Outstanding Demand Qty. (Base)"; Decimal)
        {
            Caption = 'Outstanding Demand Qty. (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the outstanding quantity on the demand line, in the base unit of measure.';
        }
        field(14; "Cumulative Demand Qty. (Base)"; Decimal)
        {
            Caption = 'Cumulative Demand Qty. (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the total outstanding demand for the same item, location, and variant through the demand date, in base units of measure.';
        }
        field(15; "Current Inventory (Base)"; Decimal)
        {
            Caption = 'Current Inventory (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the current inventory for the item, location, and variant, in the base unit of measure.';
        }
        field(16; "PO Supply by Need Date (Base)"; Decimal)
        {
            Caption = 'PO Supply by Need Date (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the outstanding purchase order supply expected by the demand date, in the base unit of measure.';
        }
        field(17; "Additional Supply (Base)"; Decimal)
        {
            Caption = 'Additional Supply (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies additional supply contributed through the analysis extension event, in the base unit of measure.';
        }
        field(18; "Projected Availability (Base)"; Decimal)
        {
            Caption = 'Projected Availability (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies inventory plus qualifying supply minus cumulative demand through the demand date, in base units of measure.';
        }
        field(19; "Shortage Qty. (Base)"; Decimal)
        {
            Caption = 'Shortage Qty. (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the quantity by which projected availability falls below zero, in the base unit of measure.';
        }
        field(20; "Next Inbound Date"; Date)
        {
            Caption = 'Next Inbound Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the earliest expected receipt date for purchase supply arriving after the demand date.';
        }
        field(21; "Source Purchase Order No."; Code[20])
        {
            Caption = 'Source Purchase Order No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the purchase order associated with the relevant inbound supply.';
        }
        field(22; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor."No.";
            ToolTip = 'Specifies the vendor on the purchase order associated with the exception.';
        }
        field(23; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the expected receipt date of the overdue purchase supply associated with the exception.';
        }
        field(24; "Days Late"; Integer)
        {
            Caption = 'Days Late';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how many days the demand or expected purchase receipt is past due.';
        }
        field(25; Reason; Text[250])
        {
            Caption = 'Reason';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the facts that caused the exception to be detected.';
        }
        field(26; Recommendation; Text[250])
        {
            Caption = 'Recommendation';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the recommended actions for a user to review and carry out.';
        }
        field(27; "Resolution Status"; Enum "SCAResolutionStatus")
        {
            Caption = 'Resolution Status';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the current resolution status of the exception.';
        }
    }

    keys
    {
        key(PK; "Analysis Entry No.", "Line No.") { Clustered = true; }
        key(Risk; "Analysis Entry No.", "Risk Level", "Line No.") { }
        key(ItemDate; "Item No.", "Location Code", "Variant Code", "Demand Date") { }
    }
}
