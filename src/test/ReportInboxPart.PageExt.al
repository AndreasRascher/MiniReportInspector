pageextension 50100 "ReportInboxPart" extends "Report Inbox Part"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter(Action11)
        {
            action(CreateDataSetXMLInReportInbox)
            {
                ApplicationArea = all;
                Image = TestFile;
                trigger OnAction()
                begin
                    Codeunit.Run(50102);
                end;
            }
        }
    }

}