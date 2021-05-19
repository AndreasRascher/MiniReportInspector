/// <summary>
/// To persist the output of RequestPageHandler a seperat testrunner without Testisolation is used
/// </summary>
codeunit 80001 "RunTestWithoutIsolation"
{
    Subtype = TestRunner;
    TestIsolation = Disabled;
    trigger OnRun()
    begin
        Commit();
        Codeunit.Run(Codeunit::OnPremDataSetExport);
    end;


}