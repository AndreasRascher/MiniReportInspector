// codeunit 80002 "ResultSetTest"
// {
//     Subtype = Test;

//     [Test]
//     procedure TestResultSetLineCount()
//     var
//         DataSetExportHelper: Codeunit DataSetExportHelper;
//         Lines: List of [List of [Text]];
//         ColumnNames: List of [Text];
//         ReqPageParams: text;
//         DataSetXML: XmlDocument;
//     begin
//         ReqPageParams := '<?xml version="1.0" standalone="yes"?>' +
//         '<ReportParameters name="SalesShipmentSample" id="80000">' +
//         '  <Options>' +
//         '    <Field name="ExportDataSet">false</Field>' +
//         '    <Field name="ExportDatasetOptions">1</Field>' +
//         '  </Options>' +
//         '  <DataItems>' +
//         '    <DataItem name="Sales Shipment Header">VERSION(1) SORTING(Field3) WHERE(Field3=1(102001..102002))</DataItem>' +
//         '  </DataItems>' +
//         '</ReportParameters>';
//         DataSetXML := DataSetExportHelper.GetReportDatasetXML(Report::"Sales - Shipment", ReqPageParams);
//         DataSetExportHelper.TryFindColumnNamesInRDLCLayout(Report::"Sales - Shipment", ColumnNames);
//         DataSetExportHelper.TransformToTableLayoutXML(DataSetXML, ColumnNames, Lines);
//         if Lines.Count <> 5 then
//             Error('5 Lines expected');
//     end;
// }