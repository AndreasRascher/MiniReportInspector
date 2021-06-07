// pageextension 80001 "ReportInboxPart" extends "Report Inbox Part"
// {
//     layout
//     {
//         // Add changes to page layout here
//     }

//     actions
//     {
//         // Add changes to page actions here
//         addafter(Action11)
//         {
//             action(RunTestToCreateDataSetXML_SaveResultInReportInbox)
//             {
//                 ApplicationArea = all;
//                 Image = TestFile;
//                 trigger OnAction()
//                 begin
//                     Codeunit.Run(50102);
//                 end;
//             }
//         }
//     }

// }