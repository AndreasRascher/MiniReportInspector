/// <summary>
/// To persist the output of RequestPageHandler a seperat testrunner without Testisolation is used
/// </summary>
codeunit 50102 "RunTestWithoutIsolation"
{
    Subtype = TestRunner;
    TestIsolation = Disabled;
    trigger OnRun()
    begin
        Commit();
        Codeunit.Run(50101);
    end;


}