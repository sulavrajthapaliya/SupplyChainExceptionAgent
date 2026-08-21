namespace SupplyChain.ExceptionAgent;

table 50302 "SCAAnalysisHeader"
{
    Caption = 'Supply Chain Exception Analysis';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the unique entry number of the analysis.';
        }
        field(2; Scope; Enum "SCAScanScope")
        {
            Caption = 'Scope';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the analysis covers all eligible documents or a specific source document.';
        }
        field(3; "Source Document No."; Code[20])
        {
            Caption = 'Source Document No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the document number that the analysis was run for. The field is blank for a full scan.';
        }
        field(4; "Analysis Date"; Date)
        {
            Caption = 'Analysis Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the work date on which the analysis was performed.';
        }
        field(5; "Horizon End Date"; Date)
        {
            Caption = 'Horizon End Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the last demand date included in the analysis horizon.';
        }
        field(6; "Exception Count"; Integer)
        {
            Caption = 'Exception Count';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the total number of exceptions found by the analysis.';
        }
        field(7; "Critical Count"; Integer)
        {
            Caption = 'Critical Count';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of critical-risk exceptions found by the analysis.';
        }
        field(8; "High Count"; Integer)
        {
            Caption = 'High Count';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of high-risk exceptions found by the analysis.';
        }
        field(9; "Medium Count"; Integer)
        {
            Caption = 'Medium Count';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of medium-risk exceptions found by the analysis.';
        }
        field(10; "Low Count"; Integer)
        {
            Caption = 'Low Count';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number of low-risk exceptions found by the analysis.';
        }
        field(11; "Peak Shortage Qty. (Base)"; Decimal)
        {
            Caption = 'Peak Shortage Qty. (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the total peak shortage quantity across affected item, location, and variant combinations, in base units of measure.';
        }
        field(12; "Highest Risk Level"; Enum "SCARiskLevel")
        {
            Caption = 'Highest Risk Level';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the highest risk level among the exceptions found by the analysis.';
        }
        field(13; Status; Enum "SCAAnalysisStatus")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the current processing or review status of the analysis.';
        }
        field(14; "Was Truncated"; Boolean)
        {
            Caption = 'Was Truncated';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the scan stopped after reaching the configured maximum number of exceptions.';
        }
        field(15; "Analyzed At"; DateTime)
        {
            Caption = 'Analyzed At';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the date and time when the analysis was performed.';
        }
        field(16; "Analyzed By"; Guid)
        {
            Caption = 'Analyzed By';
            DataClassification = EndUserIdentifiableInformation;
            ToolTip = 'Specifies the security ID of the user who ran the analysis.';
        }
        field(17; "Agent Task ID"; BigInteger)
        {
            Caption = 'Agent Task ID';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the ID of the agent task created to review this analysis.';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
