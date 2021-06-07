codeunit 80004 "DataSetExcelExport"
{
    procedure Process(ReportID: Integer)
    var
        CustomReportLayout: Record "Custom Report Layout";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempNameValueBufferOut: Record "Name/Value Buffer" temporary;
        TenantMedia: Record "Tenant Media" temporary;
        DataSetExportHelper: Codeunit DataSetExportHelper;
        PrintResult_IStream: InStream;
        ColumnNames: List of [Text];
        PrintResult_OStream: OutStream;
        LayoutXML: XmlDocument;
    begin
        if not FindReportRDLCLayout(ReportID, LayoutXML) then
            Error('No RDLC layout found in Report %1', ReportID);
        DataSetExportHelper.TryFindColumnNamesInRDLCLayout(ReportID, ColumnNames);
        // Add Parameters to the Dataset Table
        CreateBlankLayoutAndAddTablix(LayoutXML, ColumnNames);

        // DEBUG: Download generated Layout
        // ================================
        // DataSetExportHelper.DownloadReportSaveAsXMLResult(LayoutXML);


        TenantMedia.Content.CreateOutStream(PrintResult_OStream);
        RunReportWithLayout(PrintResult_OStream, ReportID, CustomReportLayout, LayoutXML);
        TenantMedia.Insert(false);
        TenantMedia.CalcFields(Content);
        TenantMedia.Content.CreateInStream(PrintResult_IStream);
        TempExcelBuffer.GetSheetsNameListFromStream(PrintResult_IStream, TempNameValueBufferOut);
        TenantMedia.CalcFields(Content);
        TenantMedia.Content.CreateInStream(PrintResult_IStream);
        TempExcelBuffer.OpenBookStream(PrintResult_IStream, TempNameValueBufferOut.Value);
        TempExcelBuffer.ReadSheet();
        If TempExcelBuffer.FindFirst() then begin
            TempExcelBuffer.SetRange("Row No.", TempExcelBuffer."Row No.");
            TempExcelBuffer.ModifyAll(Bold, true);
            TempExcelBuffer.SetRange("Row No.");
        end;
        // Create New Excel
        TempExcelBuffer.CreateNewBook('SheetNameTxt');
        TempExcelBuffer.WriteSheet(Format(CurrentDateTime, 0, 9), CompanyName(), UserId());
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.SetFriendlyFilename('DataSetExport');
        TempExcelBuffer.OpenExcel();
        Error('1. ToDo: Fehlermeldung beim löschen der Zeile in der Berichtsauswahl' +
              '2. TODO: XML Export des DataSets');
    end;

    local procedure CreateTablix(ColumnNames: List of [Text]) XTablix: XmlElement
    var
        TB: TextBuilder;
        i: Integer;
        XMLDoc: XmlDocument;
        ColCount: Integer;
    begin
        ColCount := ColumnNames.Count;
        //ColCount := 2;

        TB.AppendLine('<?xml version="1.0" encoding="utf-8"?>');
        TB.AppendLine('<Tablix Name="Tablix1">');
        TB.AppendLine('  <TablixBody>');
        TB.AppendLine('    <TablixColumns>');
        for i := 1 To ColCount do begin
            TB.AppendLine('      <TablixColumn><Width>2cm</Width></TablixColumn>');
        end;
        TB.AppendLine('    </TablixColumns>');
        TB.AppendLine('    <TablixRows>');
        // Row 1 Headers
        TB.AppendLine('  	 <TablixRow>');
        TB.AppendLine('  	   <Height>0.25in</Height>');
        TB.AppendLine('  	   <TablixCells>');
        for i := 1 To ColCount do begin
            TB.AppendLine('  		 <TablixCell>');
            TB.AppendLine('  		   <CellContents>');
            TB.AppendLine('  			 <Textbox Name="HeaderField' + format(i) + '">');
            TB.AppendLine('  			   <CanGrow>true</CanGrow>');
            TB.AppendLine('  			   <KeepTogether>true</KeepTogether>');
            TB.AppendLine('  			   <Paragraphs><Paragraph>');
            TB.AppendLine('  				   <TextRuns><TextRun>');
            TB.AppendLine('  				  	   <Value>' + ColumnNames.Get(i) + '</Value>');
            TB.AppendLine('  				  	   <Style><FontWeight>Bold</FontWeight></Style>');
            TB.AppendLine('  				   </TextRun></TextRuns><Style />');
            TB.AppendLine('  			   </Paragraph></Paragraphs>');
            //TB.AppendLine('  			   <rd:DefaultName>Textbox' + format(i) + '</rd:DefaultName>');
            TB.AppendLine('  			 <Style />');
            TB.AppendLine('  		   </Textbox>');
            TB.AppendLine('  		 </CellContents>');
            TB.AppendLine('  	   </TablixCell>');
        end;
        TB.AppendLine('	     </TablixCells>');
        TB.AppendLine('    </TablixRow>');

        // Row 2 Values
        TB.AppendLine('  	 <TablixRow>');
        TB.AppendLine('  	   <Height>0.25in</Height>');
        TB.AppendLine('  	   <TablixCells>');
        for i := 1 To ColCount do begin
            TB.AppendLine('  		 <TablixCell>');
            TB.AppendLine('  		   <CellContents>');
            TB.AppendLine('  			 <Textbox Name="LineField' + format(i) + '">');
            TB.AppendLine('  			   <CanGrow>true</CanGrow>');
            TB.AppendLine('  			   <KeepTogether>true</KeepTogether>');
            TB.AppendLine('  			   <Paragraphs>');
            TB.AppendLine('                  <Paragraph>');
            TB.AppendLine('  				   <TextRuns><TextRun>');
            TB.AppendLine('  				  	   <Value>=Fields!' + ColumnNames.Get(i) + '.Value</Value>');
            TB.AppendLine('  				  	   <Style />');
            TB.AppendLine('  				   </TextRun></TextRuns>');
            TB.AppendLine('  				   <Style />');
            TB.AppendLine('                  </Paragraph>');
            TB.AppendLine('  			   </Paragraphs>');
            //TB.AppendLine('  			   <rd:DefaultName>Textbox' + format(i) + '</rd:DefaultName>');
            TB.AppendLine('  			 <Style />');
            TB.AppendLine('  		   </Textbox>');
            TB.AppendLine('  		 </CellContents>');
            TB.AppendLine('  	   </TablixCell>');
        end;
        TB.AppendLine('	     </TablixCells>');
        TB.AppendLine('    </TablixRow>');
        TB.AppendLine('  </TablixRows>');
        TB.AppendLine('</TablixBody>');
        TB.AppendLine('<TablixColumnHierarchy>');
        TB.AppendLine('  <TablixMembers>');
        for i := 1 To ColCount do begin
            TB.AppendLine('	   <TablixMember />');
        end;
        TB.AppendLine('  </TablixMembers>');
        TB.AppendLine('</TablixColumnHierarchy>');
        TB.AppendLine('<TablixRowHierarchy>');
        TB.AppendLine('  <TablixMembers>');
        TB.AppendLine('    <TablixMember>');
        TB.AppendLine('      <KeepWithGroup>After</KeepWithGroup>');
        TB.AppendLine('    </TablixMember>');
        TB.AppendLine('    <TablixMember>');
        TB.AppendLine('	     <Group Name="Details" />');
        TB.AppendLine('	   </TablixMember>');
        TB.AppendLine('  </TablixMembers>');
        TB.AppendLine('</TablixRowHierarchy>');
        //TB.AppendLine('<Top>0.53833in</Top>'); // =0 if missing
        //TB.AppendLine('<Left>0.83833in</Left>');// =0 if missing
        TB.AppendLine('<Height>0.25in</Height>');
        TB.AppendLine('<Width>1in</Width>');
        TB.AppendLine('<Style>');
        TB.AppendLine('  <Border>');
        TB.AppendLine('	<Style>None</Style>');
        TB.AppendLine('  </Border>');
        TB.AppendLine('</Style>');
        TB.AppendLine('</Tablix>');
        XmlDocument.ReadFrom(TB.ToText(), XmlDoc);
        XMLDoc.GetRoot(XTablix);
    end;

    local procedure FindReportRDLCLayout(ReportID: Integer; var LayoutXML: XmlDocument) Found: Boolean
    var
        LayoutInstream: InStream;
    begin
        if not Report.RdlcLayout(ReportID, LayoutInstream) then
            exit(false);
        Found := XmlDocument.ReadFrom(LayoutInstream, LayoutXML);
    end;

    local procedure CreateCustomLayoutEntry(var CustomReportLayout: Record "Custom Report Layout"; ReportID: Integer; var LayoutXML: XmlDocument)
    var
        TenantMedia: Record "Tenant Media" temporary;
        OStr: OutStream;
        XMLAsText: Text;
        InsertOK: Boolean;
    begin
        TenantMedia.Content.CreateOutStream(OStr);
        Clear(CustomReportLayout);
        CustomReportLayout.Code := StrSubstNo('XL-%1', ReportID);
        CustomReportLayout.Type := CustomReportLayout.Type::RDLC;
        CustomReportLayout.Description := 'DataSet Excel Export';
        CustomReportLayout."Report ID" := ReportID;
        InsertOK := CustomReportLayout.Insert(true);
        LayoutXML.WriteTo(XMLAsText);
        CustomReportLayout.SetLayout(XMLAsText);
        CustomReportLayout.Calcfields(Layout);
        CustomReportLayout."Custom XML Part" := CustomReportLayout.Layout;
        CustomReportLayout.Modify();
    end;

    local procedure RunReportWithLayout(var PrintResult_OStr: OutStream; ReportID: Integer; var CustomReportLayout: Record "Custom Report Layout"; var LayoutXML: XmlDocument)
    var
        ReportLayoutSelection_Existing: Record "Report Layout Selection";
        ReportLayoutSelection: Record "Report Layout Selection";
        ModificationType: Option " ",modified,new;
    begin
        // Set new Layout code so it works with BC14
        CreateCustomLayoutEntry(CustomReportLayout, ReportID, LayoutXML);
        if not ReportLayoutSelection_Existing.Get(ReportID, CompanyName) then begin
            ReportLayoutSelection."Report ID" := ReportID;
            ReportLayoutSelection."Company Name" := CompanyName;
            ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Custom Layout";
            ReportLayoutSelection."Custom Report Layout Code" := CustomReportLayout.Code;
            ReportLayoutSelection.insert(true);
            ModificationType := ModificationType::new;
        end else begin
            ReportLayoutSelection := ReportLayoutSelection_Existing;
            ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Custom Layout";
            ReportLayoutSelection."Custom Report Layout Code" := CustomReportLayout.Code;
            ReportLayoutSelection.Modify(true);
            ModificationType := ModificationType::modified;
        end;
        Report.SaveAs(ReportID, '', ReportFormat::Excel, PrintResult_OStr);
        // Restore old state
        case ModificationType of
            ModificationType::new:
                begin
                    ReportLayoutSelection.Delete(true);
                    CustomReportLayout.Delete(true);
                end;
            ModificationType::modified:
                begin
                    //ReportLayoutSelection := ReportLayoutSelection_Existing;
                    //ReportLayoutSelection.Modify();
                    //ReportLayoutSelection_Existing.Modify();
                    Commit();
                    CustomReportLayout.Find('=');
                    CustomReportLayout.Delete(true);
                end;
        end;
    end;

    local procedure CreateBlankLayoutAndAddTablix(var LayoutXML: XmlDocument; var ColumnNames: List of [Text])
    var
        DataSetExportHelper: Codeunit DataSetExportHelper;
        Debug: Boolean;
        XMLAsText: Text;
        XmlNsMgr: XmlNamespaceManager;
        XDummyNode: XmlNode;
        XReportItemsNew: XmlNode;
        XReportItemsOld: XmlNode;
        XReportItemsList: XmlNodeList;
    begin
        DataSetExportHelper.AddNamespaces(XmlNsMgr, LayoutXML);
        Debug := LayoutXML.SelectSingleNode('/ns:Report/ns:ReportSections/ns:ReportSection/ns:Body/ns:ReportItems', XMLNsMgr, XReportItemsOld);
        Debug := LayoutXML.SelectNodes('/ns:Report/ns:ReportSections/ns:ReportSection/ns:Body/ns:ReportItems', XMLNsMgr, XReportItemsList);
        XReportItemsNew := XmlElement.Create('ReportItems').AsXmlNode();
        XReportItemsNew.AsXmlElement().Add(CreateTablix(ColumnNames));
        XReportItemsOld.ReplaceWith(XReportItemsNew);
        LayoutXML.WriteTo(XMLAsText);
        XMLAsText := XMLAsText.Replace(' xmlns=""', '');
        XMLDocument.ReadFrom(XMLAsText, LayoutXML);
        //Remove Header
        if LayoutXML.SelectSingleNode('/ns:Report/ns:ReportSections/ns:ReportSection/ns:Page/ns:PageHeader', XmlNsMgr, XDummyNode) then
            XDummyNode.Remove();
        //Remove Footer
        if LayoutXML.SelectSingleNode('/ns:Report/ns:ReportSections/ns:ReportSection/ns:Page/ns:PageFooter', XmlNsMgr, XDummyNode) then
            XDummyNode.Remove();
    end;
}