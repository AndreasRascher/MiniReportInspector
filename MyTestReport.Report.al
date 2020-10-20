report 50100 "MyTestReport"
{
    Caption = 'MyTestReport';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultLayout = RDLC;
    RDLCLayout = 'MyTestReport.rdl';

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.";
            column(BalanceLCY; "Balance (LCY)") { }
            column(City; City) { }
            column(County; County) { }
            column(Name; Name) { }
            column(No; "No.") { }
            column(SalesLCY; "Sales (LCY)") { }
            column(SalespersonCode; "Salesperson Code") { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(ExportDataSetCtrl; ExportDataSet)
                    {
                        Caption = 'Export DataSet';
                        ApplicationArea = all;
                        Visible = not IsRunRequestPageMode;
                        trigger OnValidate()
                        begin
                            DataSetExportHelper.OpenRequestPageForDatasetExport(CurrReport.ObjectId(false));
                            ExportDataSet := false;
                        end;
                    }
                    field(DataSetExportOptionsCtrl; ExportDatasetOptions)
                    {
                        OptionCaption = 'XML,Excel';
                        Caption = 'Export Dataset as';
                        ApplicationArea = All;
                        Visible = IsRunRequestPageMode;
                    }
                }
            }
        }
        trigger OnOpenPage()
        begin
            IsRunRequestPageMode := DataSetExportHelper.GetRunReqPageMode();
        end;
    }
    var
        DataSetExportHelper: Codeunit DataSetExportHelper;
        ExportDatasetOptions: Option "XML","Excel";
        [InDataSet]
        IsRunRequestPageMode: Boolean;
        ExportDataSet: Boolean;
}