namespace SupplyChain.ExceptionAgent.Tests;

codeunit 50400 "SCATestAssert"
{
    procedure IsTrue(Condition: Boolean; Message: Text)
    begin
        if not Condition then
            Error(IsTrueErr, Message);
    end;

    procedure IsFalse(Condition: Boolean; Message: Text)
    begin
        if Condition then
            Error(IsFalseErr, Message);
    end;

    procedure AreEqualInteger(Expected: Integer; Actual: Integer; Message: Text)
    begin
        if Expected <> Actual then
            Error(AreEqualErr, Expected, Actual, Message);
    end;

    procedure AreEqualBigInteger(Expected: BigInteger; Actual: BigInteger; Message: Text)
    begin
        if Expected <> Actual then
            Error(AreEqualErr, Expected, Actual, Message);
    end;

    procedure AreEqualDecimal(Expected: Decimal; Actual: Decimal; Tolerance: Decimal; Message: Text)
    begin
        if Abs(Expected - Actual) > Tolerance then
            Error(AreEqualWithToleranceErr, Expected, Actual, Tolerance, Message);
    end;

    procedure AreEqualDate(Expected: Date; Actual: Date; Message: Text)
    begin
        if Expected <> Actual then
            Error(AreEqualErr, Expected, Actual, Message);
    end;

    procedure AreEqualText(Expected: Text; Actual: Text; Message: Text)
    begin
        if Expected <> Actual then
            Error(AreEqualTextErr, Expected, Actual, Message);
    end;

    procedure Contains(Actual: Text; ExpectedPart: Text; Message: Text)
    begin
        if StrPos(Actual, ExpectedPart) = 0 then
            Error(ContainsErr, ExpectedPart, Actual, Message);
    end;

    var
        IsTrueErr: Label 'Assert.IsTrue failed: %1', Locked = true;
        IsFalseErr: Label 'Assert.IsFalse failed: %1', Locked = true;
        AreEqualErr: Label 'Assert.AreEqual failed. Expected %1, actual %2. %3', Locked = true;
        AreEqualWithToleranceErr: Label 'Assert.AreEqual failed. Expected %1, actual %2, tolerance %3. %4', Locked = true;
        AreEqualTextErr: Label 'Assert.AreEqual failed. Expected "%1", actual "%2". %3', Locked = true;
        ContainsErr: Label 'Assert.Contains failed. "%1" was not found in "%2". %3', Locked = true;
}
