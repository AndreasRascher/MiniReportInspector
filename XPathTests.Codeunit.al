codeunit 50101 "XPathTests"
{
    Subtype = Test;
    [Test]
    procedure TestCountXPathCount()
    var
        XML: Text;
        XDoc: XmlDocument;
        XNodeList: XmlNodeList;
        XNodeList2: XmlNodeList;
        XDataItem: XmlNode;
        XDataItems: XmlNode;
        ListCount: Integer;
        IsElement: Boolean;
        IsEmptyElement: Boolean;
        LeafCount: Integer;
        test: Record "Report Data Items"
    begin
        XML := GetSampleXML();
        XmlDocument.ReadFrom(XML, XDoc);
        // XDoc := GetSampleXML2();

        XDoc.SelectNodes('//DataItem', XNodeList);
        ListCount := XNodeList.Count;
        foreach XDataItem in XNodeList do begin
            if IsLeafDataItemWithoutChildDataItems(XDataItem) then
                LeafCount += 1;
        end;

    end;

    /// <summary>
    /// Returns true if the DataItem Node no or empty DataItems children  
    /// </summary>
    /// <param name="XDataItem"></param>
    /// <returns></returns>
    procedure IsLeafDataItemWithoutChildDataItems(XDataItem: XmlNode) Result: Boolean
    var
        DataItemName: Text;
        XDataItemsBelow: XmlNodeList;
        XDataItems: XmlNode;
    begin
        GetAttributeValue(XDataItem, 'name', DataItemName);
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

    local procedure GetSampleXML(): text
    var
        TB: TextBuilder;
    begin
        TB.AppendLine('<?xml version="1.0" encoding="utf-8" standalone="yes"?>');
        TB.AppendLine('<ReportDataSet name="SalesShipmentSample" id="50101">');
        TB.AppendLine('  <DataItems>');
        TB.AppendLine('    <DataItem name="Sales_Shipment_Header">');
        TB.AppendLine('      <Columns>');
        TB.AppendLine('        <Column name="No_SalesShptHeader">102038</Column>');
        TB.AppendLine('        <Column name="PageCaption">Page %1 of %2</Column>');
        TB.AppendLine('      </Columns>');
        TB.AppendLine('      <DataItems>');
        TB.AppendLine('        <DataItem name="CopyLoop">');
        TB.AppendLine('          <DataItems>');
        TB.AppendLine('            <DataItem name="PageLoop">');
        TB.AppendLine('              <Columns>');
        TB.AppendLine('                <Column name="CompanyInfo2Picture"></Column>');
        TB.AppendLine('              </Columns>');
        TB.AppendLine('              <DataItems>');
        TB.AppendLine('                <DataItem name="Sales_Shipment_Line">');
        TB.AppendLine('                  <Columns>');
        TB.AppendLine('                    <Column name="No_SalesShptLineCaption">Nr.</Column>');
        TB.AppendLine('                  </Columns>');
        TB.AppendLine('                  <DataItems />');
        TB.AppendLine('                </DataItem>');
        TB.AppendLine('              </DataItems>');
        TB.AppendLine('            </DataItem>');
        TB.AppendLine('          </DataItems>');
        TB.AppendLine('        </DataItem>');
        TB.AppendLine('      </DataItems>');
        TB.AppendLine('    </DataItem>');
        TB.AppendLine('  </DataItems>');
        TB.AppendLine('</ReportDataSet>');
        exit(TB.ToText());
    end;

    local procedure GetSampleXML2() XMLDoc: XmlDocument;
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        TenantMedia: Record "Tenant Media" temporary;
        SalesShipment: report "Sales - Shipment";
        BigText: BigText;
        InStr: InStream;
        OutStr: OutStream;
        RecRef: RecordRef;
        ReqPageParams: text;
    begin
        ReqPageParams := '<?xml version="1.0" standalone="yes"?><ReportParameters name="SalesShipmentSample" id="50101"><Options><Field name="NoOfCopies">0</Field><Field name="ShowInternalInfo">false</Field><Field name="LogInteraction">true</Field><Field name="ShowCorrectionLines">false</Field><Field name="ShowLotSN">false</Field><Field name="DisplayAssemblyInformation">false</Field><Field name="ExportDataSet">false</Field><Field name="ExportDatasetOptions">1</Field></Options><DataItems><DataItem name="Sales Shipment Header">VERSION(1) SORTING(Field3)</DataItem><DataItem name="CopyLoop">VERSION(1) SORTING(Field1)</DataItem><DataItem name="PageLoop">VERSION(1) SORTING(Field1)</DataItem><DataItem name="DimensionLoop1">VERSION(1) SORTING(Field1)</DataItem><DataItem name="Sales Shipment Line">VERSION(1) SORTING(Field3,Field4)</DataItem><DataItem name="DimensionLoop2">VERSION(1) SORTING(Field1)</DataItem><DataItem name="DisplayAsmInfo">VERSION(1) SORTING(Field1)</DataItem><DataItem name="Total">VERSION(1) SORTING(Field1)</DataItem>';
        SalesShipmentHeader.findfirst;
        SalesShipmentHeader.SetRecFilter();
        SalesShipment.SetTableView(SalesShipmentHeader);
        TenantMedia.CalcFields(Content);
        TenantMedia.Content.CreateOutStream(OutStr, TextEncoding::Windows);
        RecRef.GetTable(SalesShipmentHeader);
        SalesShipment.SaveAs('', ReportFormat::Xml, OutStr);
        TenantMedia.Content.CreateInStream(InStr, TextEncoding::Windows);
        XmlDocument.ReadFrom(InStr, XMLDoc);
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
}