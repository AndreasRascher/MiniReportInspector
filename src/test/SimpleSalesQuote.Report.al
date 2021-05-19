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
            column(ID_SH; format(RecordId)) { }
            dataitem(SL; "Sales Line")
            {
                DataItemLink = "Document No." = field("No."), "Document Type" = field("Document Type");
                column(No_; "No.") { IncludeCaption = true; }
                column(Type; Format(Type, 0, 'number')) { }
                column(Description; Description) { }
                column(ID_SL; format(RecordId)) { }
            }
        }
    }
    labels
    {
        PageLbl = 'Page: ';
    }
}
