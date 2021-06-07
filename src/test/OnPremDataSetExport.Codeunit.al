// codeunit 80003 "OnPremDataSetExport"
// {
//     Subtype = Test;

//     [Test]
//     [HandlerFunctions('Rep80000ReqPageHandler')]
//     procedure TestingReport80000()
//     var
//         SalesShipmentHeader: Record "Sales Shipment Header";
//         SalesShipmentSample: Report SalesShipmentSample;
//     begin
//         SalesShipmentHeader.FindFirst();
//         SalesShipmentHeader.SetRecFilter();
//         SalesShipmentHeader.setfilter("No.", '102001..102002');
//         SalesShipmentSample.SetTableView(SalesShipmentHeader);
//         SalesShipmentSample.UseRequestPage := true;
//         SalesShipmentSample.Run();
//         //SaveFileToReportInbox('RP80000ParameterFile', ParameterFileName);
//         SaveFileToReportInbox('RP80000DataSetFile', DataSetFileName);
//     end;

//     [RequestPageHandler]
//     procedure Rep80000ReqPageHandler(var RequestPage: TestRequestPage 80000)
//     var
//         FileMgt: Codeunit "File Management";
//     begin
//         ParameterFileName := FileMgt.ServerTempFileName('txt');
//         DataSetFileName := FileMgt.ServerTempFileName('txt');
//         RequestPage.SaveAsXml(ParameterFileName, DataSetFileName);
//     end;

//     local procedure SaveFileToReportInbox(Descr: text[250]; Path: Text)
//     var
//         ReportInbox: Record "Report Inbox";
//         TempBlob: Record "Tenant Media" temporary;
//     begin
//         BLOBImportFromServerFile(TempBlob, Path);
//         ReportInbox."Entry No." := 1;
//         if ReportInbox.FindLast() then
//             ReportInbox."Entry No." += 1;
//         ReportInbox.init();
//         ReportInbox.Insert();
//         ReportInbox."User ID" := UserId;
//         ReportInbox.Description := Descr;
//         ReportInbox."Report Output" := TempBlob.Content;
//         ReportInbox.Modify();
//     end;

//     procedure BLOBImportFromServerFile(var TempBlob: Record "Tenant Media"; FilePath: Text)
//     var
//         OutStream: OutStream;
//         InStream: InStream;
//         InputFile: File;
//     begin
//         //IsAllowedPath(FilePath, false);

//         if not FILE.Exists(FilePath) then
//             Error('FileDoesNotExistErr\"%1"', FilePath);

//         InputFile.Open(FilePath);
//         InputFile.CreateInStream(InStream);
//         TempBlob.Content.CreateOutStream(OutStream);
//         CopyStream(OutStream, InStream);
//         InputFile.Close();
//     end;


//     var
//         DataSetFileName: Text;
//         ParameterFileName: Text;
// }