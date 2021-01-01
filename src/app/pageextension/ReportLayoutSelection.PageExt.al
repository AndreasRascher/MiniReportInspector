pageextension 50101 "ReportLayoutSelection" extends "Report Layout Selection"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addlast(Reporting)
        {
            action(ExportDataSet)
            {
                ApplicationArea = All;
                Image = CreateXMLFile;
                Caption = 'Export Report DataSet';

                trigger OnAction()
                var
                    ReqPageParams: Text;
                    ReportSaveAsXMLResult: XmlDocument;
                    ColumnNames: List of [Text];
                    Lines: List of [List of [Text]];
                    Choice: Integer;
                begin
                    ReqPageParams := Report.RunRequestPage(Rec."Report ID");
                    ReportSaveAsXMLResult := DataSetExportHelper.GetReportDatasetXML(Rec."Report ID", ReqPageParams);
                    DataSetExportHelper.TryFindColumnNamesInRDLCLayout(Rec."Report ID", ColumnNames);
                    DataSetExportHelper.TransformToTableLayoutXML(ReportSaveAsXMLResult, ColumnNames, Lines);
                    Choice := StrMenu('ResultSet XML,ReportSaveAs XML,Excel');
                    case Choice of
                        1:
                            DataSetExportHelper.DownloadResultSetXML(ColumnNames, Lines);
                        2:
                            DataSetExportHelper.DownloadReportSaveAsXMLResult(ReportSaveAsXMLResult);
                        3:
                            DataSetExportHelper.DownloadDataSetExcel(ColumnNames, Lines);
                    end;
                end;
            }
        }
    }

    var
        DataSetExportHelper: Codeunit DataSetExportHelper;
}