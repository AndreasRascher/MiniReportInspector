report 80001 "SimpleSalesQuote"
{
    UsageCategory = Administration;
    ApplicationArea = All;
    RDLCLayout = 'src\test\SimpleSalesQuote.Report.rdlc';

    dataset
    {
        dataitem(SH; "Sales Header")
        {
            DataItemTableView = SORTING("Document Type", "No.") where("Document Type" = const(Quote));
            column(No_SH; "No.") { }
            dataitem(SL; "Sales Line")
            {
                column(No_; "No.") { IncludeCaption = true; }
                column(Type; Format(Type, 0, 'number')) { }
                column(Description; Description) { }
            }
        }
    }
    labels
    {
        PageLbl = 'Page: ';
    }
}
