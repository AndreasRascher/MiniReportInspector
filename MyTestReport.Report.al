report 50100 "MyTestReport"
{
    Caption = 'MyTestReport';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultLayout = RDLC;
    RDLCLayout = 'MyTestReport.rdl';

    dataset
    {
        dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
        {
            RequestFilterFields = Code;
            PrintOnlyIfDetail = true;
            column(SalesPersonCode; Code) { }
            column(SalesPersonName; Name) { }

            dataitem(Customer; Customer)
            {
                DataItemLink = "Salesperson Code" = field(Code);

                column(CustomerBalanceLCY; "Balance (LCY)") { }
                column(CustomerCity; City) { }
                column(CustomerCounty; County) { }
                column(CustomerName; Name) { }
                column(CustomerNo; "No.") { }
                column(CustomerSalesLCY; "Sales (LCY)") { }
                column(CustomerSalespersonCode; "Salesperson Code") { }
            }
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
                        Caption = 'Export Dataset as';
                        ShowCaption = false;
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
        ExportDatasetOptions: Option "Select an export format","XML","Excel";
        [InDataSet]
        IsRunRequestPageMode: Boolean;
        ExportDataSet: Boolean;
}