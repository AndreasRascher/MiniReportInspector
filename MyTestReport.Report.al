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
                    field(DataSetExportOptionsCtrl; ExportDatasetOptions)
                    {
                        OptionCaption = ' ,XML,Excel';
                        Caption = 'Export Dataset as';
                        ApplicationArea = All;
                    }
                }
            }
        }
    }
    var
        ExportDatasetOptions: Option " ","XML","Excel";

    trigger OnPostReport()
    var
        Report_Management: Codeunit Report_Management;
    begin
        if ExportDatasetOptions = ExportDatasetOptions::" " then
            exit;
        Report_Management.ExportReportDataset(CurrReport.ObjectId(false), ExportDatasetOptions = ExportDatasetOptions::"Excel");
    end;
}