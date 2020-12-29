codeunit 50100 "DataSetExportHelper"
{
    SingleInstance = true;
    procedure OpenRequestPageForDatasetExport(ReportIDasIntegerOrText: Variant)
    var
        ReportID: Integer;
        RequestPageParams: text;
        Selection: text;
    begin
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
                ExportDatasetOptions := ExportDatasetOptions::"ResultSet XML";
            '2':
                ExportDatasetOptions := ExportDatasetOptions::"ReportSaveAs XML";
            '3':
                ExportDatasetOptions := ExportDatasetOptions::Excel;
        end;
        DownloadDataset(ReportID, RequestPageParams, ExportDatasetOptions);
    end;

    procedure DownloadDataset(ReportID: Integer; RequestPageParams: Text; _ExportDataSetOptionsInteger: Integer)
    var
        DataSetXML: XmlDocument;
        ColumnNames: List of [Text];
        Lines: List of [List of [Text]];
    begin
        DataSetXML := GetReportDatasetXML(ReportID, RequestPageParams);
        TryFindColumnNamesInRDLCLayout(ReportID, ColumnNames);
        TransformToTableLayoutXML(DataSetXML, ColumnNames, Lines);
        //RemoveEmptyColumnsFromColumnNames(ColumnNames, Lines);
        case _ExportDataSetOptionsInteger of
            ExportDatasetOptions::Excel:
                DownloadDataSetExcel(ColumnNames, Lines);
            ExportDatasetOptions::"ReportSaveAs XML":
                DownloadReportSaveAsXMLResult(DataSetXML);
            ExportDatasetOptions::"ResultSet XML":
                DownloadResultSetXML(ColumnNames, Lines);
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

    procedure TryFindColumnNamesInRDLCLayout(ReportID: Integer; var ColumnNames: List of [Text]) Found: Boolean
    var
        //Parse RDLC Layout
        LayoutInstream: InStream;
        LayoutXML: XmlDocument;
        XMLNsMgr: XmlNamespaceManager;
        XFields: XmlNodeList;
        XField: XmlNode;
        Name: Text;
    begin
        if not Report.RdlcLayout(ReportID, LayoutInstream) then
            exit(false);
        XmlDocument.ReadFrom(LayoutInstream, LayoutXML);
        AddNamespaces(XMLNsMgr, LayoutXML);
        LayoutXML.SelectNodes('/ns:Report/ns:DataSets/ns:DataSet/ns:Fields/ns:Field', XMLNsMgr, XFields);
        foreach XField in XFields do begin
            Name := GetXMLAttrValue(XField, 'Name');
            ColumnNames.Add(Name);
        end;
        Found := ColumnNames.Count > 0;
    end;

    procedure DownloadDataSetExcel(ColumnNames: List of [Text]; Lines: List of [List of [Text]]);
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        CurrRow: Integer;
        Line: List of [Text];
        ColName: Text;
        CellValue: Text;
    begin
        Foreach Line in Lines do begin
            CurrRow += 1;
            if CurrRow = 1 then begin
                foreach ColName in ColumnNames do begin
                    CellValue := CopyStr(ColName, 1, MaxStrLen(TempExcelBuffer."Cell Value as Text"));
                    TempExcelBuffer.AddColumn(CellValue, false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                end;
                TempExcelBuffer.NewRow();
            end;

            foreach CellValue in Line do begin
                CellValue := CopyStr(CellValue, 1, MaxStrLen(TempExcelBuffer."Cell Value as Text"));
                TempExcelBuffer.AddColumn(CellValue, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            end;
            TempExcelBuffer.NewRow();
        end;
        TempExcelBuffer.CreateNewBook('SheetNameTxt');
        TempExcelBuffer.WriteSheet(Format(CurrentDateTime, 0, 9), CompanyName(), UserId());
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.SetFriendlyFilename('DataSetExport');
        TempExcelBuffer.OpenExcel();
    end;

    procedure DownloadResultSetXML(ColumnNames: List of [Text]; Lines: List of [List of [Text]])
    var
        TenantMedia: Record "Tenant Media";
        Line: List of [Text];
        ColIndex: Integer;
        RowIndex: Integer;
        OutStr: OutStream;
        FormattedDataSetXML: XmlDocument;
        XDeclaration: XmlDeclaration;
        XResult: XmlNode;
        XField: XmlNode;
        XRoot: XmlNode;
        ColName: Text;
    begin
        // Init Target XML Document
        FormattedDataSetXML := XmlDocument.Create();
        XDeclaration := XmlDeclaration.Create('1.0', '', 'yes');
        FormattedDataSetXML.SetDeclaration(XDeclaration);
        XRoot := XmlElement.Create('DataSet').AsXmlNode();
        FormattedDataSetXML.AddFirst(XRoot);

        // Export Rows
        foreach Line in Lines do begin
            RowIndex += 1;
            XResult := XmlElement.Create('Result').AsXmlNode();
            XRoot.AsXmlElement().Add(XResult);
            // Lines
            Clear(ColIndex);
            foreach ColName in ColumnNames do begin
                ColIndex += 1;
                if Line.Get(ColIndex) <> '' then
                    XField := XmlElement.Create(ColName, '', Line.Get(ColIndex)).AsXmlNode()
                else
                    XField := XmlElement.Create(ColName).AsXmlNode();
                if XField.IsXmlElement then
                    if not XField.AsXmlElement().IsEmpty then
                        XResult.AsXmlElement().Add(XField);
            end;
        end;
        TenantMedia.Content.CreateOutStream(OutStr);
        FormattedDataSetXML.WriteTo(OutStr);
        DownloadBlobContent(TenantMedia, 'ResultSet.xml');
    end;

    procedure DownloadReportSaveAsXMLResult(ReportSaveAsXMLResult: XmlDocument)
    var
        TenantMedia: Record "Tenant Media";
        OutStr: OutStream;
    begin
        TenantMedia.Content.CreateOutStream(OutStr);
        ReportSaveAsXMLResult.WriteTo(OutStr);
        DownloadBlobContent(TenantMedia, 'ReportSaveAsXML.xml');
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

    procedure GetXMLAttrValue(XNode: XmlNode; AttrName: text) AttrValue: Text
    begin
        if not GetXMLAttrVal(XNode, AttrName, AttrValue) then
            exit('');
    end;

    procedure GetXMLAttrVal(XNode: XmlNode; AttrName: text; var AttrValue: Text) OK: Boolean
    var
        AttrNode: XmlAttribute;
    begin
        Clear(AttrValue);
        OK := XNode.AsXmlElement().Attributes().Get(AttrName, AttrNode);
        if OK then
            AttrValue := AttrNode.Value();
    end;

    procedure AddNamespaces(var _XmlNsMgr: XmlNamespaceManager; _XMLDoc: XmlDocument)
    var
        _XmlAttributeCollection: XmlAttributeCollection;
        _XmlAttribute: XmlAttribute;
        _XMLElement: XmlElement;
    begin
        _XmlNsMgr.NameTable(_XMLDoc.NameTable());
        _XMLDoc.GetRoot(_XMLElement);
        _XmlAttributeCollection := _XMLElement.Attributes();
        if _XMLElement.NamespaceUri() <> '' then
            _XmlNsMgr.AddNamespace('ns', _XMLElement.NamespaceUri());
        Foreach _XmlAttribute in _XmlAttributeCollection do
            if StrPos(_XmlAttribute.Name(), 'xmlns:') = 1 then
                _XmlNsMgr.AddNamespace(DELSTR(_XmlAttribute.Name(), 1, 6), _XmlAttribute.Value());
    end;

    /// <summary>
    /// Transforms a hierarchical Dataset.xml result from report.saveasxml into its flat rdlc version
    /// </summary>
    /// <param name="DataSetXML">report.saveasxml Result</param>
    /// <param name="Lines">Data Table</param>
    procedure TransformToTableLayoutXML(DataSetXML: XMLDocument; ColumnNames: List of [Text]; var Lines: List of [List of [Text]]);
    var
        XNodeList: XmlNodeList;
        XNode_InnerDataItem: XmlNode;
        Ancestors: XmlNodeList;
        Ancestor: XmlNode;
        Columns: XmlNodeList;
        Col: XmlNode;
        Line: List of [Text];
        ListCount: Integer;
        DebugText: text;
        DebugText2: TextBuilder;
        DebugLineCount: Integer;
    begin
        // Foreach Dataitem without child Dataitems
        case true of
            DataSetXML.SelectNodes('//DataItem', XNodeList):
                ListCount := XnodeList.Count;
        end;
        foreach XNode_InnerDataItem in XNodeList do begin

            DebugLineCount += 1;
            DebugText2.AppendLine(Format(DebugLineCount) + ': ' + GetXMLAttrValue(XNode_InnerDataItem, 'name'));

            if IsDataItemForNewResultLine(XNode_InnerDataItem) then begin
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
                                            AddColumnToLine(Line, ColumnNames, Col);
                                        end;
                end;
                //Save line to data table
                if Line.Count > 0 then
                    Lines.Add(Line);
            end;
        end;
    end;

    /// <summary>
    /// Assumed Rules
    /// - Output only dataitems with colums
    /// - No dataitems directly below ReportDataSet/DataItems - if there are columns in child dataitems
    /// </summary>
    /// <param name="XDataItem"></param>
    /// <returns></returns>
    procedure IsDataItemForNewResultLine(XDataItem: XmlNode) Result: Boolean
    var
        DataItemName: Text;
        XDataItemsBelow: XmlNodeList;
        XColumns: XmlNodeList;
        Ancestor: XmlNode;
        Ancestor2: XmlNode;
        IsLeafDataItem: Boolean;
        DataItemHasColumns: Boolean;
        IsTopLevelDataItem: Boolean;
    begin

        if XDataItem.SelectSingleNode('parent::node()', Ancestor) then
            if Ancestor.SelectSingleNode('parent::node()', Ancestor2) then
                if Ancestor2.AsXmlElement().LocalName = 'ReportDataSet' then
                    IsTopLevelDataItem := true;
        //IsLeafDataItemAndNotEmpty
        GetXMLAttrVal(XDataItem, 'name', DataItemName); //debug
        XDataItem.SelectNodes('./DataItems', XDataItemsBelow);
        // Zero or empty <DataItems /> are accepted
        IsLeafDataItem := XDataItemsBelow.Count = 0;
        XDataItem.SelectNodes('./Columns', XColumns);
        DataItemHasColumns := XColumns.Count > 0;
        case true of
            IsTopLevelDataItem and not IsLeafDataItem:
                exit(false);
            IsLeafDataItem:
                exit(true);
            (not DataItemHasColumns):
                exit(false);
        end;
        exit(true);
    end;

    procedure AddColumnToLine(var Line: List of [text]; ColumnNames: List of [Text]; Col: XmlNode)
    var
        ColName: Text;
        ColValue: Text;
        ColPos: Integer;
        ColNameFormat: Text;
        ColValueFormat: Text;
        DecimalValue: Decimal;
        ColPosFormat: Integer;
        debug: Integer;
    begin
        // Init List - List.Insert needs existing element
        If Line.Count = 0 then
            foreach ColName in ColumnNames do begin
                Line.Add('');
            end;
        debug := Line.Count;

        // Add Name and Values to Line
        //<Column name="BalanceLCY" decimalformatter="#,##0.00">0</Column>                                        
        ColName := GetXMLAttrValue(Col, 'name');
        ColPos := ColumnNames.IndexOf(ColName);
        ColValue := Col.AsXmlElement().InnerText;
        If GetXMLAttrVal(Col, 'decimalformatter', ColValueFormat) then
            if evaluate(DecimalValue, ColValue) then
                ColValue := Format(DecimalValue, 0, 9);
        if ColPos = 0 then
            Error('unknown Column %1', ColName);
        Line.Insert(ColPos, ColValue);

        if GetXMLAttrVal(Col, 'decimalformatter', ColValueFormat) then begin

            ColNameFormat := ColName + 'Format';
            ColPosFormat := ColumnNames.IndexOf(ColNameFormat);

            if ColPosFormat = 0 then
                Error('unknown FormatColumn %1', ColNameFormat);
            Line.Insert(ColPosFormat, ColValueFormat);
        end;
    end;

    var
        IsRunRequestPageMode: Boolean;
        ExportDatasetOptions: Option " ","ResultSet XML","ReportSaveAs XML","Excel";

}