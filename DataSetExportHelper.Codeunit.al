codeunit 50100 "DataSetExportHelper"
{
    SingleInstance = true;
    procedure OpenRequestPageForDatasetExport(ReportIDasIntegerOrText: Variant)
    var
        ReportID: Integer;
        RequestPageParams: text;
        Selection: text;
        ExportDatasetOptions: Option " ","XML","Excel";
    begin
        //Message('OpenRequestPageForDatasetExport IsRunRequestPageMode=%1', IsRunRequestPageMode);
        if not TryFindReportID(ReportIDasIntegerOrText, ReportID) then
            Error('Invalid ReportID "%1"', ReportIDasIntegerOrText);
        SetRunReqPageMode(true);
        RequestPageParams := Report.RunRequestPage(ReportID);
        SetRunReqPageMode(false);
        Selection := copystr(RequestPageParams, Strpos(RequestPageParams, '<Field name="ExportDatasetOptions">') + 35, 1);
        Case Selection of
            '0':
                exit;
            '1':
                ExportDatasetOptions := ExportDatasetOptions::XML;
            '2':
                ExportDatasetOptions := ExportDatasetOptions::Excel;
        end;
        DownloadDataset(ReportID, RequestPageParams, Format(ExportDatasetOptions));
    end;

    procedure DownloadDataset(ReportID: Integer; RequestPageParams: Text; ExportOptionText: Text)
    var
        DataSetXML: XmlDocument;
        Lines: List of [Dictionary of [Text, Text]];
    begin
        DataSetXML := GetReportDatasetLines(ReportID, RequestPageParams);
        TransformToTableLayoutXML(DataSetXML, Lines);
        case Uppercase(ExportOptionText) of
            'EXCEL':
                ExportDataSetAsExcel(Lines);
            'XML':
                //ExportDataSetAsXML(Lines);
                ExportDataSetXML(DataSetXML);
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
    procedure ExportDataSetAsExcel(Lines: List of [Dictionary of [Text, Text]]);
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        CurrRow: Integer;
        Line: Dictionary of [Text, Text];
        ColName: Text;
    begin
        Foreach Line in Lines do begin
            CurrRow += 1;
            if CurrRow = 1 then begin
                foreach ColName in Line.Keys do
                    TempExcelBuffer.AddColumn(ColName, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.NewRow();
            end;

            foreach ColName in Line.Keys do begin
                TempExcelBuffer.AddColumn(Line.Get(ColName), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            end;
            TempExcelBuffer.NewRow();
        end;
        TempExcelBuffer.CreateNewBook('SheetNameTxt');
        TempExcelBuffer.WriteSheet(Format(CurrentDateTime, 0, 9), CompanyName(), UserId());
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.SetFriendlyFilename('DataSetExport');
        TempExcelBuffer.OpenExcel();
    end;

    procedure ExportDataSetAsResultSetXML(Lines: List of [Dictionary of [Text, Text]]; FormatAsResultSetXML: Boolean)
    var
        TenantMedia: Record "Tenant Media";
        Line: Dictionary of [Text, Text];
        ColIndex: Integer;
        RowIndex: Integer;
        OutStr: OutStream;
        FormattedDataSetXML: XmlDocument;
        XResult: XmlNode;
        XField: XmlNode;
        XRoot: XmlNode;
        ColName: Text;
    begin
        // Init Target XML Document
        FormattedDataSetXML := XmlDocument.Create();
        XRoot := XmlElement.Create('DataSet').AsXmlNode();
        FormattedDataSetXML.AddFirst(XRoot);

        // Export Rows
        foreach Line in Lines do begin
            RowIndex += 1;
            XResult := XmlElement.Create('Result').AsXmlNode();
            XRoot.AsXmlElement().Add(XResult);
            // Lines
            foreach ColName in Line.Keys do begin
                ColIndex += 1;
                if Line.Get(ColName) <> '' then
                    XField := XmlElement.Create(ColName, '', Line.Get(ColName)).AsXmlNode()
                else
                    XField := XmlElement.Create(ColName).AsXmlNode();
                XResult.AsXmlElement().Add(XField);
            end;
        end;

        TenantMedia.Content.CreateOutStream(OutStr);
        FormattedDataSetXML.WriteTo(OutStr);
        DownloadBlobContent(TenantMedia, 'DataSet.xml');
    end;

    procedure ExportDataSetXML(DataSetXML: XmlDocument)
    var
        TenantMedia: Record "Tenant Media";
        OutStr: OutStream;
    begin
        TenantMedia.Content.CreateOutStream(OutStr);
        DataSetXML.WriteTo(OutStr);
        DownloadBlobContent(TenantMedia, 'DataSet.xml');
    end;


    procedure GetReportDatasetLines(ReportID: Integer; RequestPageParams: Text) XMLDoc: XmlDocument
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

    procedure GetAttributeValue(XNode: XmlNode; AttrName: text) AttrValue: Text
    begin
        if not GetAttributeValue(XNode, AttrName, AttrValue) then
            exit('');
    end;

    procedure GetAttributeValue(XNode: XmlNode; AttrName: text; var AttrValue: Text) OK: Boolean
    var
        AttrNode: XmlAttribute;
    begin
        Clear(AttrValue);
        OK := XNode.AsXmlElement().Attributes().Get(AttrName, AttrNode);
        if OK then
            AttrValue := AttrNode.Value();
    end;

    /// <summary>
    /// Transforms a hierarchical Dataset.xml result from report.saveasxml into its flat rdlc version
    /// </summary>
    /// <param name="DataSetXML">report.saveasxml Result</param>
    /// <param name="Lines">Data Table</param>
    procedure TransformToTableLayoutXML(DataSetXML: XMLDocument; var Lines: List of [Dictionary of [Text, Text]]);
    var
        XNodeList: XmlNodeList;
        XNode_InnerDataItem: XmlNode;
        Ancestors: XmlNodeList;
        Ancestor: XmlNode;
        Columns: XmlNodeList;
        Col: XmlNode;
        Line: Dictionary of [Text, Text];
        ListCount: Integer;
        DebugText: text;
        DecimalFormatter: Text;
        ColName: Text;
        ColValue: Text;
        DecimalValue: Decimal;
    begin
        // Foreach Dataitem without child Dataitems
        case true of
            DataSetXML.SelectNodes('//DataItem', XNodeList):
                ListCount := XnodeList.Count;
        end;

        foreach XNode_InnerDataItem in XNodeList do begin
            if IsLeafDataItemWithoutChildDataItems(XNode_InnerDataItem) then begin
                // Join all Columns from current dataiten and its ancestors (ancestor-or-self)
                // New Line
                Clear(Line);
                XNode_InnerDataItem.SelectNodes('ancestor-or-self::DataItem', Ancestors);
                ListCount := Ancestors.Count;
                foreach Ancestor in Ancestors do begin
                    // If dataitem has columns
                    if Ancestor.SelectNodes('child::*', Columns) then
                        if Columns.Get(1, Col) then
                            if Col.AsXmlElement().Name = 'Columns' then
                                if Col.SelectNodes('child::*', Columns) then
                                    foreach Col in Columns do
                                        if Col.IsXmlElement then begin
                                            Col.WriteTo(DebugText);
                                            // Add Name and Values to Line
                                            //<Column name="BalanceLCY" decimalformatter="#,##0.00">0</Column>                                        
                                            ColName := GetAttributeValue(Col, 'name');
                                            ColValue := Col.AsXmlElement().InnerText;
                                            DecimalFormatter := GetAttributeValue(Col, 'decimalformatter');

                                            if DecimalFormatter <> '' then begin
                                                If evaluate(DecimalValue, ColValue) then
                                                    ColValue := Format(DecimalValue, 0, 9);
                                                Line.Add(GetAttributeValue(Col, 'name'), ColValue);
                                                Line.Add(ColName + 'Format', DecimalFormatter);
                                            end else begin
                                                Line.Add(ColName, ColValue);
                                            end;

                                        end;
                end;
            end;
            //Save line to data table
            if Line.Count > 0 then
                Lines.Add(Line);
        end;
    end;

    /// <summary>
    /// Returns true if the DataItem Node has zero or empty "DataItems" children    
    /// </summary>
    /// <param name="XDataItem"></param>
    /// <returns></returns>
    procedure IsLeafDataItemWithoutChildDataItems(XDataItem: XmlNode) Result: Boolean
    var
        DataItemName: Text;
        XDataItemsBelow: XmlNodeList;
        XDataItems: XmlNode;
    begin
        GetAttributeValue(XDataItem, 'name', DataItemName); //debug
        XDataItem.SelectNodes('./DataItems', XDataItemsBelow);
        // Zero or empty <DataItems /> are accepted
        if XDataItemsBelow.Count = 0 then
            exit(true);
        foreach XDataItems in XDataItemsBelow do begin
            if XDataItems.IsXmlElement then
                if not XDataItems.AsXmlElement().IsEmpty then
                    exit(false);
        end;
        exit(true);
    end;

    var
        IsRunRequestPageMode: Boolean;

}