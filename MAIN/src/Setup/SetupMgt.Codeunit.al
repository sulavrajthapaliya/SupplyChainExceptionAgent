namespace SupplyChain.ExceptionAgent;

codeunit 50300 "SCASetupMgt"
{
    Access = Public;
    Permissions = tabledata "SCASetup" = rim;

    procedure GetSetup(var Setup: Record "SCASetup")
    begin
        if Setup.Get('') then
            exit;

        Setup.Init();
        Setup."Primary Key" := '';
        Setup."Horizon Days" := 30;
        Setup."High Shortage %" := 20;
        Setup."Critical Shortage %" := 50;
        Setup."High Past Due Days" := 3;
        Setup."Critical Past Due Days" := 7;
        Setup."Minimum Shortage Qty. (Base)" := 0.00001;
        Setup."Late Receipt Grace Days" := 0;
        Setup."Maximum Exceptions Per Scan" := 500;
        Setup."Agent Top Exceptions" := 20;
        Setup."Include Open Sales Orders" := true;
        Setup."Include Released Sales Orders" := true;
        Setup."Include Open Purchase Orders" := true;
        Setup."Include Released PO" := true;
        Setup.Insert(true);
    end;

    procedure ValidateSetup(var Setup: Record "SCASetup")
    var
        CriticalPastDueErr: Label 'Critical Past Due Days must be greater than or equal to High Past Due Days.';
        CriticalShortageErr: Label 'Critical Shortage %% must be greater than or equal to High Shortage %%.';
    begin
        if Setup."Critical Shortage %" < Setup."High Shortage %" then
            Error(CriticalShortageErr);
        if Setup."Critical Past Due Days" < Setup."High Past Due Days" then
            Error(CriticalPastDueErr);
    end;

    procedure RiskRank(RiskLevel: Enum "SCARiskLevel"): Integer
    begin
        case RiskLevel of
            RiskLevel::Low:
                exit(0);
            RiskLevel::Medium:
                exit(1);
            RiskLevel::High:
                exit(2);
            RiskLevel::Critical:
                exit(3);
        end;
    end;
}
