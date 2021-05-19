codeunit 80004 "RDLTablixBuilder"
{
    Subtype = Test;
    [Test]
    procedure GetReportLayoutXML()
    var
        DataSetExportHelper: Codeunit DataSetExportHelper;
        LayoutXML: XmlDocument;
        XmlNsMgr: XmlNamespaceManager;
        XReportItemsOld: XmlNode;
        XReportItemsNew: XmlNode;
        XDummyNode: XmlNode;
        ColumnNames: List of [Text];
        ParamNames: List of [Text];
        ParamName: Text;
        XMLAsText: Text;
        OStr: OutStream;
        TenantMedia: Record "Tenant Media" temporary;
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutSelection: Record "Report Layout Selection";
        RDLTablixBuilderEventSubs: Codeunit "RDLTablixBuilderEventSubs";
    begin
        FindReportRDLCLayout(Report::"Sales - Shipment", LayoutXML);
        DataSetExportHelper.AddNamespaces(XmlNsMgr, LayoutXML);
        DataSetExportHelper.TryFindColumnNamesInRDLCLayout(Report::"Sales - Shipment", ColumnNames);
        // Add Parameters to the Dataset Table
        DataSetExportHelper.TryFindParameterNamesInRDLCLayout(Report::"Sales - Shipment", ParamNames);
        foreach ParamName in ParamNames do begin
            ColumnNames.Add(ParamName);
        end;

        LayoutXML.SelectSingleNode('/ns:Report/ns:ReportSections/ns:ReportSection/ns:Body/ns:ReportItems', XMLNsMgr, XReportItemsOld);
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


        // DEBUG: Download generated Layout
        // ================================
        //DataSetExportHelper.DownloadReportSaveAsXMLResult(LayoutXML);


        TenantMedia.Content.CreateOutStream(OStr);
        Clear(CustomReportLayout);
        CustomReportLayout.Code := StrSubstNo('XL-%1', Report::"Sales - Shipment");
        CustomReportLayout.Type := CustomReportLayout.Type::RDLC;
        CustomReportLayout.Description := 'DataSet Excel Export';
        CustomReportLayout."Report ID" := Report::"Sales - Shipment";
        if CustomReportLayout.Insert(true) then;
        LayoutXML.WriteTo(XMLAsText);
        CustomReportLayout.SetLayout(XMLAsText);
        CustomReportLayout.Calcfields(Layout);
        CustomReportLayout."Custom XML Part" := CustomReportLayout.Layout;
        //if "Layout Last Updated" > "Last Modified" then
        CustomReportLayout."Layout Last Updated" := CustomReportLayout."Last Modified" + 1000; // Skip update
        CustomReportLayout.Modify();
        //if CustomReportLayout."Layout Last Updated" > CustomReportLayout."Last Modified" then
        //    Error('');
        ReportLayoutSelection.SetTempLayoutSelected(CustomReportLayout.Code);
        BindSubscription(RDLTablixBuilderEventSubs);
        Report.SaveAs(Report::"Sales - Shipment", '', ReportFormat::Excel, OStr);
        DataSetExportHelper.DownloadBlobContent(TenantMedia, 'DataSet.xlsx');
        CustomReportLayout.Delete();
    end;

    local procedure CreateTablix(ColumnNames: List of [Text]) XTablix: XmlElement
    var
        TB: TextBuilder;
        i: Integer;
        ColName: text;
        XMLDoc: XmlDocument;
        ColCount: Integer;
    begin
        /*
        Ausgaberendering für Bericht fehlgeschlagen. Fehler: The tablix ‘Tablix1’ has an incorrect number of TablixColumns. The number of TablixColumns must equal the number of innermost TablixMembers (TablixMembers with no submembers) in the TablixColumnHierarchy.
        */
        ColCount := ColumnNames.Count;
        //ColCount := 2;

        TB.AppendLine('<?xml version="1.0" encoding="utf-8"?>');
        TB.AppendLine('<Tablix Name="Tablix1">');
        TB.AppendLine('  <TablixBody>');
        TB.AppendLine('    <TablixColumns>');
        for i := 1 To ColCount do begin
            TB.AppendLine('      <TablixColumn><Width>1cm</Width></TablixColumn>');
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
            TB.AppendLine('  			   <Paragraphs>');
            TB.AppendLine('                  <Paragraph>');
            TB.AppendLine('  				   <TextRuns><TextRun>');
            TB.AppendLine('  				  	   <Value>' + ColumnNames.Get(i) + '</Value>');
            TB.AppendLine('  				  	   <Style><FontWeight>Bold</FontWeight></Style>');
            TB.AppendLine('  				   </TextRun></TextRuns><Style />');
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

        // Row 2 Values
        TB.AppendLine('  	 <TablixRow>');
        TB.AppendLine('  	   <Height>0.25in</Height>');
        TB.AppendLine('  	   <TablixCells>');
        for i := 1 To 2 /*ColumnNames.Count*/ do begin
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
}