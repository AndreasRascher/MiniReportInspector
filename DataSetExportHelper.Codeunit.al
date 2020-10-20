codeunit 50100 "DataSetExportHelper"
{
    SingleInstance = true;
    procedure OpenRequestPageForDatasetExport(ReportIDasIntegerOrText: Variant)
    var
        ReportID: Integer;
        RequestPageParams: text;
        Selection: text;
    begin
        Message('OpenRequestPageForDatasetExport IsRunRequestPageMode=%1', IsRunRequestPageMode);
        if not TryFindReportID(ReportIDasIntegerOrText, ReportID) then
            Error('Invalid ReportID "%1"', ReportIDasIntegerOrText);
        SetRunReqPageMode(true);
        RequestPageParams := Report.RunRequestPage(ReportID);
        SetRunReqPageMode(false);
        Selection := copystr(RequestPageParams, Strpos(RequestPageParams, '<Field name="ExportDatasetOptions">') + 35, 1);
        Case Selection of
            '0':
                ExportDatasetOptions := ExportDatasetOptions::XML;
            '1':
                ExportDatasetOptions := ExportDatasetOptions::Excel;
        end;
        Message('OnBeforeDownloadDataSet');
        DownloadDataset(ReportID, ExportDatasetOptions);
    end;

    procedure DownloadDataset(ReportIDasIntegerOrText: Variant; ExportOptions: Option "XML","Excel")
    begin
        case ExportOptions of
            ExportOptions::Excel:
                ExportDataSetAsExcel(DatasetXML);
            ExportOptions::XML:
                ExportDataSetasXML(DatasetXML);
        end;
    end;

    local procedure TryFindReportID(ReportIDasIntegerOrText: Variant; var ReportID: Integer) Found: boolean
    begin
        if ReportIDasIntegerOrText.IsInteger then
            ReportID := ReportIDasIntegerOrText;
        if ReportIDasIntegerOrText.IsText then
            Evaluate(ReportId, CopyStr(ReportIDasIntegerOrText, 8));
        Found := (ReportID <> 0);
    end;

    procedure GetColumnNames(DataSetXML: XmlDocument; var ColumnNames: List of [Text]);
    var
        DataSetRows: XmlNodeList;
        DataSetColumns: XmlNodeList;
        RowNode: XmlNode;
        ColumnNode: XmlNode;
        RowIndex: Integer;
        ColumnIndex: Integer;
        AttrNode: XmlAttribute;
        Name: Text;
    begin
        DataSetXML.SelectNodes('/ReportDataSet/DataItems/DataItem/Columns', DataSetRows);
        for RowIndex := 1 to DataSetRows.Count do begin
            DataSetRows.Get(RowIndex, RowNode);
            RowNode.SelectNodes('node()', DataSetColumns);  // Childnodes
            // Header
            if RowIndex = 1 then
                for ColumnIndex := 1 to DataSetColumns.Count do begin
                    DataSetColumns.Get(ColumnIndex, ColumnNode);
                    if ColumnNode.IsXmlElement() then begin
                        if ColumnNode.AsXmlElement().Attributes().Get('name', AttrNode) then begin
                            Name := AttrNode.Value();
                            ColumnNames.Add(Name);
                        end;
                        if ColumnNode.AsXmlElement().Attributes().Get('decimalformatter', AttrNode) then
                            ColumnNames.Add(Name + 'Format');
                    end;
                end;
        end;
    end;

    /// <summary> 
    /// Converts the Dataset.xml to a flattened row by row represantation 
    /// </summary>
    procedure FlattenDataSetXMLIntoExcelBuffer(DataSetXML: XmlDocument; var TmpXLBuf: Record "Excel Buffer" temporary);
    var
        ColumnIndex: Integer;
        RowIndex: Integer;
        Name: Text;
        NodeValue: text;
        AttrNode: XmlAttribute;
        ColNode: XmlNode;
        RowNode: XmlNode;
        DataSetCols: XmlNodeList;
        DataSetRows: XmlNodeList;
        ColumnNames: List of [Text];
    begin
        // Header
        GetColumnNames(DataSetXML, ColumnNames);
        foreach Name in ColumnNames do
            TmpXLBuf.AddColumn(Name, false, '', true, false, false, '', TmpXLBuf."Cell Type"::Text);
        TmpXLBuf.NewRow();

        DataSetXML.SelectNodes('/ReportDataSet/DataItems/DataItem/Columns', DataSetRows);
        for RowIndex := 1 to DataSetRows.Count do begin
            TmpXLBuf.NewRow();
            DataSetRows.Get(RowIndex, RowNode);
            RowNode.SelectNodes('node()', DataSetCols);  // Childnodes
            // Lines
            for ColumnIndex := 1 to DataSetCols.Count do begin
                DataSetCols.Get(ColumnIndex, ColNode);
                if ColNode.IsXmlElement then begin
                    NodeValue := ColNode.AsXmlElement().InnerText;
                    TmpXLBuf.AddColumn(NodeValue, false, '', false, false, false, '', TmpXLBuf."Cell Type"::Text);
                    if ColNode.AsXmlElement().Attributes().Get('decimalformatter', AttrNode) then begin
                        NodeValue := AttrNode.Value();
                        TmpXLBuf.AddColumn(NodeValue, false, '', false, false, false, '', TmpXLBuf."Cell Type"::Text);
                    end;
                end;
            end;
        end;
    end;

    /// <summary> 
    /// Converts the DataSet.xml to an excel file with column titles
    /// </summary>
    /// <param name="DataSetXML">Report XML Dataset</param>
    procedure ExportDataSetAsExcel(DataSetXML: XmlDocument);
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
    begin
        FlattenDataSetXMLIntoExcelBuffer(DataSetXML, TempExcelBuffer);
        TempExcelBuffer.CreateNewBook('SheetNameTxt');
        TempExcelBuffer.WriteSheet(Format(CurrentDateTime, 0, 9), CompanyName(), UserId());
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.SetFriendlyFilename('DataSetExport');
        TempExcelBuffer.OpenExcel();
    end;

    procedure ExportDataSetAsXML(DataSetXML: XmlDocument)
    var
        TenantMedia: Record "Tenant Media";
        OutStr: OutStream;
        FlattenedDataSetXML: XmlDocument;
        XRoot: XmlNode;
        XNode: XmlNode;
        XNode2: XmlNode;
        ColumnNames: List of [Text];
        DataSetRows: XmlNodeList;
        DataSetCols: XmlNodeList;
        RowIndex: Integer;
        ColumnIndex: Integer;
        RowNode: XmlNode;
        ColNode: XmlNode;
        NodeValue: text;
        AttrNode: XmlAttribute;
    begin
        // Init Target XML Document
        FlattenedDataSetXML := XmlDocument.Create();
        XRoot := XmlElement.Create('DataSet').AsXmlNode();
        FlattenedDataSetXML.AddFirst(XRoot);

        GetColumnNames(DataSetXML, ColumnNames);

        // Export Rows
        DataSetXML.SelectNodes('/ReportDataSet/DataItems/DataItem/Columns', DataSetRows);
        for RowIndex := 1 to DataSetRows.Count do begin
            XNode := XmlElement.Create('Result').AsXmlNode();
            XRoot.AsXmlElement().Add(XNode);
            DataSetRows.Get(RowIndex, RowNode);
            RowNode.SelectNodes('node()', DataSetCols);  // Childnodes
            // Lines
            for ColumnIndex := 1 to DataSetCols.Count do begin
                DataSetCols.Get(ColumnIndex, ColNode);
                if ColNode.IsXmlElement then begin
                    NodeValue := ColNode.AsXmlElement().InnerText;
                    XNode2 := XmlElement.Create(ColumnNames.Get(ColumnIndex), '', NodeValue).AsXmlNode();
                    XNode.AsXmlElement().Add(XNode2);
                    if ColNode.AsXmlElement().Attributes().Get('decimalformatter', AttrNode) then begin
                        NodeValue := AttrNode.Value();
                        XNode2 := XmlElement.Create(ColumnNames.Get(ColumnIndex), '', NodeValue).AsXmlNode();
                        XNode.AsXmlElement().Add(XNode2);
                    end;
                end;
            end;
        end;

        TenantMedia.Content.CreateOutStream(OutStr);
        FlattenedDataSetXML.WriteTo(OutStr);
        DownloadBlobContent(TenantMedia, 'DataSet.xml');
    end;

    procedure GetReportDatasetXML(ReportID: Integer; RequestPageParams: Text) XMLDoc: XmlDocument
    var
        TenantMedia: Record "Tenant Media";
        InStr: InStream;
        OutStr: OutStream;
    begin
        TenantMedia.CalcFields(Content);
        TenantMedia.Content.CreateOutStream(OutStr, TextEncoding::Windows);
        Report.SaveAs(ReportID, RequestPageParams, ReportFormat::Xml, OutStr);
        TenantMedia.Content.CreateInStream(InStr, TextEncoding::Windows);
        XmlDocument.ReadFrom(InStr, XMLDoc);
    end;

    procedure DownloadBlobContent(var TenantMedia: Record "Tenant Media"; FileName: Text): Text
    var
        FileMgt: Codeunit "File Management";
        IsDownloaded: Boolean;
        InStr: InStream;
        Path: text;
        OutExt: text;
        AllFilesDescriptionTxt: TextConst DEU = 'Alle Dateien (*.*)|*.*', ENU = 'All Files (*.*)|*.*';
        ExcelFileTypeTok: TextConst DEU = 'Excel-Dateien (*.xlsx)|*.xlsx', ENU = 'Excel Files (*.xlsx)|*.xlsx';
        ExportLbl: TextConst DEU = 'Export', ENU = 'Export';
        RDLFileTypeTok: TextConst DEU = 'SQL Report Builder (*.rdl;*.rdlc)|*.rdl;*.rdlc', ENU = 'SQL Report Builder (*.rdl;*.rdlc)|*.rdl;*.rdlc';
        TXTFileTypeTok: TextConst DEU = 'Textdateien (*.txt)|*.txt', ENU = 'Text Files (*.txt)|*.txt';
        XMLFileTypeTok: TextConst DEU = 'XML-Dateien (*.xml)|*.xml', ENU = 'XML Files (*.xml)|*.xml';
    begin
        CASE UPPERCASE(FileMgt.GetExtension(FileName)) OF
            'XLSX':
                OutExt := ExcelFileTypeTok;
            'XML':
                OutExt := XMLFileTypeTok;
            'TXT':
                OutExt := TXTFileTypeTok;
            'RDL', 'RDLC':
                OutExt := RDLFileTypeTok;
        END;
        IF OutExt = '' THEN
            OutExt := AllFilesDescriptionTxt
        else
            OutExt += '|' + AllFilesDescriptionTxt;

        TenantMedia.Content.CreateInStream(InStr);
        IsDownloaded := DOWNLOADFROMSTREAM(InStr, ExportLbl, Path, OutExt, FileName);
        if IsDownloaded THEN
            EXIT(FileName);
        EXIT('');
    end;

    procedure SetRunReqPageMode(IsRunRequestPageModeNEW: Boolean);
    begin
        IsRunRequestPageMode := IsRunRequestPageModeNEW;
        // if Confirm('') then;
    end;

    procedure GetRunReqPageMode(): Boolean;
    begin
        exit(IsRunRequestPageMode);
    end;

    var
        IsRunRequestPageMode: Boolean;
        DatasetXML: XmlDocument;
        ExportDatasetOptions: Option "XML","Excel";

}