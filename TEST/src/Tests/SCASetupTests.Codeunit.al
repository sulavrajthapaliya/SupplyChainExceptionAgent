namespace SupplyChain.ExceptionAgent.Tests;

using SupplyChain.ExceptionAgent;

codeunit 50410 "SCASetupTests"
{
    Subtype = Test;
    RequiredTestIsolation = Function;
    TestType = UnitTest;

    [Test]
    procedure DefaultSetupValuesAreInitialized()
    var
        Setup: Record "SCASetup";
    begin
        Library.Initialize();
        Setup.Get('');

        Assert.AreEqualInteger(30, Setup."Horizon Days", 'Unexpected default horizon.');
        Assert.AreEqualDecimal(20, Setup."High Shortage %", 0.00001, 'Unexpected high shortage threshold.');
        Assert.AreEqualDecimal(50, Setup."Critical Shortage %", 0.00001, 'Unexpected critical shortage threshold.');
        Assert.AreEqualInteger(3, Setup."High Past Due Days", 'Unexpected high past-due threshold.');
        Assert.AreEqualInteger(7, Setup."Critical Past Due Days", 'Unexpected critical past-due threshold.');
        Assert.IsTrue(Setup."Include Open Sales Orders", 'Open sales orders should be included by default.');
        Assert.IsTrue(Setup."Include Open Purchase Orders", 'Open purchase orders should be included by default.');
    end;

    [Test]
    procedure CriticalShortageBelowHighIsRejected()
    var
        Setup: Record "SCASetup";
    begin
        Library.Initialize();
        Setup.Get('');
        Setup."High Shortage %" := 50;
        Setup."Critical Shortage %" := 40;

        asserterror SetupMgt.ValidateSetup(Setup);
        Assert.Contains(GetLastErrorText(), 'Critical Shortage', 'Validation should explain shortage threshold ordering.');
    end;

    [Test]
    procedure CriticalPastDueBelowHighIsRejected()
    var
        Setup: Record "SCASetup";
    begin
        Library.Initialize();
        Setup.Get('');
        Setup."High Past Due Days" := 10;
        Setup."Critical Past Due Days" := 5;

        asserterror SetupMgt.ValidateSetup(Setup);
        Assert.Contains(GetLastErrorText(), 'Critical Past Due Days', 'Validation should explain past-due threshold ordering.');
    end;

    [Test]
    procedure EqualThresholdsAreAllowed()
    var
        Setup: Record "SCASetup";
    begin
        Library.Initialize();
        Setup.Get('');
        Setup."High Shortage %" := 30;
        Setup."Critical Shortage %" := 30;
        Setup."High Past Due Days" := 4;
        Setup."Critical Past Due Days" := 4;

        SetupMgt.ValidateSetup(Setup);
    end;

    [Test]
    procedure RiskRankOrdersLowToCritical()
    begin
        Assert.AreEqualInteger(0, SetupMgt.RiskRank(Enum::"SCARiskLevel"::Low), 'Low rank mismatch.');
        Assert.AreEqualInteger(1, SetupMgt.RiskRank(Enum::"SCARiskLevel"::Medium), 'Medium rank mismatch.');
        Assert.AreEqualInteger(2, SetupMgt.RiskRank(Enum::"SCARiskLevel"::High), 'High rank mismatch.');
        Assert.AreEqualInteger(3, SetupMgt.RiskRank(Enum::"SCARiskLevel"::Critical), 'Critical rank mismatch.');
    end;

    var
        Library: Codeunit "SCATestLibrary";
        Assert: Codeunit "SCATestAssert";
        SetupMgt: Codeunit "SCASetupMgt";
}
