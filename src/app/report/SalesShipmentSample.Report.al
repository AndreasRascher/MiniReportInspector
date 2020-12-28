report 50101 "SalesShipmentSample" // Report 208 Sales Shipment BC14
{
    DefaultLayout = RDLC;
    RDLCLayout = 'src/app/report/Layout/SalesShipment.rdlc';
    Caption = 'Sales - Shipment';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem("Sales Shipment Header"; "Sales Shipment Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Sell-to Customer No.", "No. Printed";
            RequestFilterHeading = 'Posted Sales Shipment';
            // column(SalesShipmentHeader_ID; Format(RecordID)) { }
            // column(SalesShipmentHeader_DataItemCnt; GetAndIncDataItemCounter()) { }
            column(No_SalesShptHeader; "No.") { }
            column(PageCaption; PageCaptionCap) { }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    // column(PageLoop_ID; Format(RecordID)) { }
                    // column(PageLoop_DataItemCnt; GetAndIncDataItemCounter()) { }
                    column(CompanyInfo2Picture; CompanyInfo2.Picture) { }
                    column(CompanyInfo1Picture; CompanyInfo1.Picture) { }
                    column(CompanyInfo3Picture; CompanyInfo3.Picture) { }
                    column(SalesShptCopyText; StrSubstNo(Text002, CopyText)) { }
                    column(ShipToAddr1; ShipToAddr[1]) { }
                    column(CompanyAddr1; CompanyAddr[1]) { }
                    column(ShipToAddr2; ShipToAddr[2]) { }
                    column(CompanyAddr2; CompanyAddr[2]) { }
                    column(ShipToAddr3; ShipToAddr[3]) { }
                    column(CompanyAddr3; CompanyAddr[3]) { }
                    column(ShipToAddr4; ShipToAddr[4]) { }
                    column(CompanyAddr4; CompanyAddr[4]) { }
                    column(ShipToAddr5; ShipToAddr[5]) { }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.") { }
                    column(ShipToAddr6; ShipToAddr[6]) { }
                    column(CompanyInfoHomePage; CompanyInfo."Home Page") { }
                    column(CompanyInfoEmail; CompanyInfo."E-Mail") { }
                    column(CompanyInfoFaxNo; CompanyInfo."Fax No.") { }
                    column(CompanyInfoVATRegtnNo; CompanyInfo."VAT Registration No.") { }
                    column(CompanyInfoGiroNo; CompanyInfo."Giro No.") { }
                    column(CompanyInfoBankName; CompanyInfo."Bank Name") { }
                    column(CompanyInfoBankAccountNo; CompanyInfo."Bank Account No.") { }
                    column(SelltoCustNo_SalesShptHeader; "Sales Shipment Header"."Sell-to Customer No.") { }
                    column(DocDate_SalesShptHeader; Format("Sales Shipment Header"."Document Date", 0, 4)) { }
                    column(SalesPersonText; SalesPersonText) { }
                    column(SalesPurchPersonName; SalesPurchPerson.Name) { }
                    column(ReferenceText; ReferenceText) { }
                    column(YourRef_SalesShptHeader; "Sales Shipment Header"."Your Reference") { }
                    column(ShipToAddr7; ShipToAddr[7]) { }
                    column(ShipToAddr8; ShipToAddr[8]) { }
                    column(CompanyAddr5; CompanyAddr[5]) { }
                    column(CompanyAddr6; CompanyAddr[6]) { }
                    column(ShptDate_SalesShptHeader; Format("Sales Shipment Header"."Shipment Date")) { }
                    column(OutputNo; OutputNo) { }
                    column(ItemTrackingAppendixCaption; ItemTrackingAppendixCaptionLbl) { }
                    column(PhoneNoCaption; PhoneNoCaptionLbl) { }
                    column(VATRegNoCaption; VATRegNoCaptionLbl) { }
                    column(GiroNoCaption; GiroNoCaptionLbl) { }
                    column(BankNameCaption; BankNameCaptionLbl) { }
                    column(BankAccNoCaption; BankAccNoCaptionLbl) { }
                    column(ShipmentNoCaption; ShipmentNoCaptionLbl) { }
                    column(ShipmentDateCaption; ShipmentDateCaptionLbl) { }
                    column(HomePageCaption; HomePageCaptionLbl) { }
                    column(EmailCaption; EmailCaptionLbl) { }
                    column(DocumentDateCaption; DocumentDateCaptionLbl) { }
                    column(SelltoCustNo_SalesShptHeaderCaption; "Sales Shipment Header".FieldCaption("Sell-to Customer No.")) { }
                    column(OrderNoCaption_SalesShptHeader; OurDocumentNoLbl) { }
                    column(OrderNo_SalesShptHeader; "Sales Shipment Header"."Order No.") { }
                    column(ExternalDocumentNoCaption_SalesShptHeader; PurchaseOrderNoLbl) { }
                    column(ExternalDocumentNo_SalesShptHeader; "Sales Shipment Header"."External Document No.") { }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Sales Shipment Header";
                        DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                        // column(DimensionLoop1_ID; Format(RecordID)) { }
                        // column(DimensionLoop_DataItemCnt; GetAndIncDataItemCounter()) { }
                        column(DimText; DimText) { }
                        column(HeaderDimensionsCaption; HeaderDimensionsCaptionLbl) { }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry1.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            Clear(DimText);
                            Continue := false;
                            repeat
                                OldDimText := DimText;
                                if DimText = '' then
                                    DimText := StrSubstNo('%1 - %2', DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1; %2 - %3', DimText,
                                        DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until DimSetEntry1.Next() = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Sales Shipment Line"; "Sales Shipment Line")
                    {
                        DataItemLink = "Document No." = FIELD("No.");
                        DataItemLinkReference = "Sales Shipment Header";
                        DataItemTableView = SORTING("Document No.", "Line No.");
                        // column(SalesShipmentLine_ID; Format(RecordID)) { }
                        // column(SalesShipmentLine_DataItemCnt; GetAndIncDataItemCounter()) { }
                        column(Description_SalesShptLine; Description) { }
                        column(ShowInternalInfo; ShowInternalInfo) { }
                        column(ShowCorrectionLines; ShowCorrectionLines) { }
                        column(Type_SalesShptLine; Format(Type, 0, 2)) { }
                        column(AsmHeaderExists; AsmHeaderExists) { }
                        column(DocumentNo_SalesShptLine; "Document No.") { }
                        column(LinNo; LinNo) { }
                        column(Qty_SalesShptLine; Quantity) { }
                        column(UOM_SalesShptLine; "Unit of Measure") { }
                        column(No_SalesShptLine; "No.") { }
                        column(LineNo_SalesShptLine; "Line No.") { }
                        column(Description_SalesShptLineCaption; FieldCaption(Description)) { }
                        column(Qty_SalesShptLineCaption; FieldCaption(Quantity)) { }
                        column(UOM_SalesShptLineCaption; FieldCaption("Unit of Measure")) { }
                        column(No_SalesShptLineCaption; FieldCaption("No.")) { }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                            // column(DimensionLoop2_ID; Format(RecordID)) { }
                            // column(DimensionLoop2_DataItemCnt; GetAndIncDataItemCounter()) { }
                            column(DimText1; DimText) { }
                            column(LineDimensionsCaption; LineDimensionsCaptionLbl) { }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.FindSet() then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                Clear(DimText);
                                Continue := false;
                                repeat
                                    OldDimText := DimText;
                                    if DimText = '' then
                                        DimText := StrSubstNo('%1 - %2', DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText :=
                                          StrSubstNo(
                                            '%1; %2 - %3', DimText,
                                            DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code");
                                    if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                        DimText := OldDimText;
                                        Continue := true;
                                        exit;
                                    end;
                                until DimSetEntry2.Next() = 0;
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();
                            end;
                        }
                        dataitem(DisplayAsmInfo; "Integer")
                        {
                            DataItemTableView = SORTING(Number);
                            // column(DisplayAsmInfo_ID; Format(RecordID)) { }
                            // column(DisplayAsmInfo_DataItemCnt; GetAndIncDataItemCounter()) { }
                            column(PostedAsmLineItemNo; BlanksForIndent + PostedAsmLine."No.") { }
                            column(PostedAsmLineDescription; BlanksForIndent + PostedAsmLine.Description) { }
                            column(PostedAsmLineQuantity; PostedAsmLine.Quantity)
                            {
                                DecimalPlaces = 0 : 5;
                            }
                            column(PostedAsmLineUOMCode; GetUnitOfMeasureDescr(PostedAsmLine."Unit of Measure Code")) { }

                            trigger OnAfterGetRecord()
                            var
                                ItemTranslation: Record "Item Translation";
                            begin
                                if Number = 1 then
                                    PostedAsmLine.FindSet()
                                else
                                    PostedAsmLine.Next();

                                if ItemTranslation.Get(PostedAsmLine."No.",
                                     PostedAsmLine."Variant Code",
                                     "Sales Shipment Header"."Language Code")
                                then
                                    PostedAsmLine.Description := ItemTranslation.Description;
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not DisplayAssemblyInformation then
                                    CurrReport.Break();
                                if not AsmHeaderExists then
                                    CurrReport.Break();

                                PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
                                SetRange(Number, 1, PostedAsmLine.Count);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            LinNo := "Line No.";
                            if not ShowCorrectionLines and Correction then
                                CurrReport.Skip();

                            DimSetEntry2.SetRange("Dimension Set ID", "Dimension Set ID");
                            if DisplayAssemblyInformation then
                                AsmHeaderExists := AsmToShipmentExists(PostedAsmHeader);
                        end;

                        trigger OnPostDataItem()
                        begin
                            if ShowLotSN then begin
                                ItemTrackingDocMgt.SetRetrieveAsmItemTracking(true);
                                TrackingSpecCount :=
                                  ItemTrackingDocMgt.RetrieveDocumentItemTracking(TrackingSpecBuffer,
                                    "Sales Shipment Header"."No.", DATABASE::"Sales Shipment Header", 0);
                                ItemTrackingDocMgt.SetRetrieveAsmItemTracking(false);
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("No." = '') and (Quantity = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                        // column(Total_ID; Format(RecordID)) { }
                        // column(Total_DataItemCnt; GetAndIncDataItemCounter()) { }
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                        // column(Total2_ID; Format(RecordID)) { }
                        // column(Total2_DataItemCnt; GetAndIncDataItemCounter()) { }
                        column(BilltoCustNo_SalesShptHeader; "Sales Shipment Header"."Bill-to Customer No.") { }
                        column(CustAddr1; CustAddr[1]) { }
                        column(CustAddr2; CustAddr[2]) { }
                        column(CustAddr3; CustAddr[3]) { }
                        column(CustAddr4; CustAddr[4]) { }
                        column(CustAddr5; CustAddr[5]) { }
                        column(CustAddr6; CustAddr[6]) { }
                        column(CustAddr7; CustAddr[7]) { }
                        column(CustAddr8; CustAddr[8]) { }
                        column(BilltoAddressCaption; BilltoAddressCaptionLbl) { }
                        column(BilltoCustNo_SalesShptHeaderCaption; "Sales Shipment Header".FieldCaption("Bill-to Customer No.")) { }

                        trigger OnPreDataItem()
                        begin
                            if not ShowCustAddr then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(ItemTrackingLine; "Integer")
                    {
                        DataItemTableView = SORTING(Number);
                        // column(ItemTrackingLine_ID; Format(RecordID)) { }
                        // column(ItemTrackingLine_DataItemCnt; GetAndIncDataItemCounter()) { }
                        column(TrackingSpecBufferNo; TrackingSpecBuffer."Item No.") { }
                        column(TrackingSpecBufferDesc; TrackingSpecBuffer.Description) { }
                        column(TrackingSpecBufferLotNo; TrackingSpecBuffer."Lot No.") { }
                        column(TrackingSpecBufferSerNo; TrackingSpecBuffer."Serial No.") { }
                        column(TrackingSpecBufferQty; TrackingSpecBuffer."Quantity (Base)") { }
                        column(ShowTotal; ShowTotal) { }
                        column(ShowGroup; ShowGroup) { }
                        column(QuantityCaption; QuantityCaptionLbl) { }
                        column(SerialNoCaption; SerialNoCaptionLbl) { }
                        column(LotNoCaption; LotNoCaptionLbl) { }
                        column(DescriptionCaption; DescriptionCaptionLbl) { }
                        column(NoCaption; NoCaptionLbl) { }
                        dataitem(TotalItemTracking; "Integer")
                        {
                            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                            column(Quantity1; TotalQty) { }
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                TrackingSpecBuffer.FindSet()
                            else
                                TrackingSpecBuffer.Next();

                            if not ShowCorrectionLines and TrackingSpecBuffer.Correction then
                                CurrReport.Skip;
                            if TrackingSpecBuffer.Correction then
                                TrackingSpecBuffer."Quantity (Base)" := -TrackingSpecBuffer."Quantity (Base)";

                            ShowTotal := false;
                            if ItemTrackingAppendix.IsStartNewGroup(TrackingSpecBuffer) then
                                ShowTotal := true;

                            ShowGroup := false;
                            if (TrackingSpecBuffer."Source Ref. No." <> OldRefNo) or
                               (TrackingSpecBuffer."Item No." <> OldNo)
                            then begin
                                OldRefNo := TrackingSpecBuffer."Source Ref. No.";
                                OldNo := TrackingSpecBuffer."Item No.";
                                TotalQty := 0;
                            end else
                                ShowGroup := true;
                            TotalQty += TrackingSpecBuffer."Quantity (Base)";
                        end;

                        trigger OnPreDataItem()
                        begin
                            if TrackingSpecCount = 0 then
                                CurrReport.Break();
                            SetRange(Number, 1, TrackingSpecCount);
                            TrackingSpecBuffer.SetCurrentKey("Source ID", "Source Type", "Source Subtype", "Source Batch Name",
                              "Source Prod. Order Line", "Source Ref. No.");
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        // Item Tracking:
                        if ShowLotSN then begin
                            TrackingSpecCount := 0;
                            OldRefNo := 0;
                            ShowGroup := false;
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := FormatDocument.GetCOPYText();
                        OutputNo += 1;
                    end;
                    TotalQty := 0;           // Item Tracking
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CODEUNIT.Run(CODEUNIT::"Sales Shpt.-Printed", "Sales Shipment Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := 1 + Abs(NoOfCopies);
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Language.GetLanguageID("Language Code");

                FormatAddressFields("Sales Shipment Header");
                FormatDocumentFields("Sales Shipment Header");

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if the document shows internal information.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want to record the reports that you print as interactions.';
                    }
                    field("Show Correction Lines"; ShowCorrectionLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Correction Lines';
                        ToolTip = 'Specifies if the correction lines of an undoing of quantity posting will be shown on the report.';
                    }
                    field(ShowLotSN; ShowLotSN)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Serial/Lot Number Appendix';
                        ToolTip = 'Specifies if you want to print an appendix to the sales shipment report showing the lot and serial numbers in the shipment.';
                    }
                    field(DisplayAsmInfo; DisplayAssemblyInformation)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Show Assembly Components';
                        ToolTip = 'Specifies if you want the report to include information about components that were used in linked assembly orders that supplied the item(s) being sold.';
                    }
                    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteractionEnable := true;
        end;

        trigger OnOpenPage()
        begin
            InitLogInteraction();
            LogInteractionEnable := LogInteraction;
            //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            IsRunRequestPageMode := DataSetExportHelper.GetRunReqPageMode();
            //-------------------------------------------------------------------------            
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        SalesSetup.Get();
        FormatDocument.SetLogoPosition(SalesSetup."Logo Position on Documents", CompanyInfo1, CompanyInfo2, CompanyInfo3);
    end;

    trigger OnPostReport()
    begin
        if LogInteraction and not IsReportInPreviewMode() then
            if "Sales Shipment Header".FindSet() then
                repeat
                    SegManagement.LogDocument(
                      5, "Sales Shipment Header"."No.", 0, 0, DATABASE::Customer, "Sales Shipment Header"."Sell-to Customer No.",
                      "Sales Shipment Header"."Salesperson Code", "Sales Shipment Header"."Campaign No.",
                      "Sales Shipment Header"."Posting Description", '');
                until "Sales Shipment Header".Next() = 0;
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            InitLogInteraction;
        AsmHeaderExists := false;
    end;

    var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        Language: Record Language;
        PostedAsmHeader: Record "Posted Assembly Header";
        PostedAsmLine: Record "Posted Assembly Line";
        RespCenter: Record "Responsibility Center";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        TrackingSpecBuffer: Record "Tracking Specification" temporary;
        ItemTrackingAppendix: Report "Item Tracking Appendix";
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        SegManagement: Codeunit SegManagement;
        AsmHeaderExists: Boolean;
        Continue: Boolean;
        DisplayAssemblyInformation: Boolean;
        LogInteraction: Boolean;
        [InDataSet]

        LogInteractionEnable: Boolean;
        MoreLines: Boolean;
        ShowCorrectionLines: Boolean;
        ShowCustAddr: Boolean;
        ShowGroup: Boolean;
        ShowInternalInfo: Boolean;
        ShowLotSN: Boolean;
        ShowTotal: Boolean;
        OldNo: Code[20];
        TotalQty: Decimal;
        LinNo: Integer;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OldRefNo: Integer;
        OutputNo: Integer;
        TrackingSpecCount: Integer;
        BankAccNoCaptionLbl: Label 'Account No.';
        BankNameCaptionLbl: Label 'Bank';
        BilltoAddressCaptionLbl: Label 'Bill-to Address';
        DescriptionCaptionLbl: Label 'Description';
        DocumentDateCaptionLbl: Label 'Document Date';
        EmailCaptionLbl: Label 'Email';
        GiroNoCaptionLbl: Label 'Giro No.';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        HomePageCaptionLbl: Label 'Home Page';
        ItemTrackingAppendixCaptionLbl: Label 'Item Tracking - Appendix';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        LotNoCaptionLbl: Label 'Lot No.';
        NoCaptionLbl: Label 'No.';
        OurDocumentNoLbl: Label 'Our Document No.';
        PageCaptionCap: Label 'Page %1 of %2';
        PhoneNoCaptionLbl: Label 'Phone No.';
        PurchaseOrderNoLbl: Label 'Purchase Order No.';
        QuantityCaptionLbl: Label 'Quantity';
        Text002: Label 'Sales - Shipment %1', Comment = '%1 = Document No.';
        SerialNoCaptionLbl: Label 'Serial No.';
        ShipmentDateCaptionLbl: Label 'Shipment Date';
        ShipmentNoCaptionLbl: Label 'Shipment No.';
        VATRegNoCaptionLbl: Label 'VAT Reg. No.';
        SalesPersonText: Text[20];
        CopyText: Text[30];
        OldDimText: Text[75];
        ReferenceText: Text[80];
        CompanyAddr: array[8] of Text[100];
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        DimText: Text[120];
        DataItemCounter: Integer;
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    var
        DataSetExportHelper: Codeunit DataSetExportHelper;
        ExportDatasetOptions: Option "Select an export format","ResultSet XML","ReportSaveAs XML","Excel";
        [InDataSet]
        IsRunRequestPageMode: Boolean;
        ExportDataSet: Boolean;
    //-------------------------------------------------------------------------        

    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractTmplCode(5) <> '';
    end;

    procedure InitializeRequest(NewNoOfCopies: Integer; NewShowInternalInfo: Boolean; NewLogInteraction: Boolean; NewShowCorrectionLines: Boolean; NewShowLotSN: Boolean; DisplayAsmInfo: Boolean)
    begin
        NoOfCopies := NewNoOfCopies;
        ShowInternalInfo := NewShowInternalInfo;
        LogInteraction := NewLogInteraction;
        ShowCorrectionLines := NewShowCorrectionLines;
        ShowLotSN := NewShowLotSN;
        DisplayAssemblyInformation := DisplayAsmInfo;
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody);
    end;

    local procedure FormatAddressFields(SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        FormatAddr.GetCompanyAddr(SalesShipmentHeader."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        FormatAddr.SalesShptShipTo(ShipToAddr, SalesShipmentHeader);
        ShowCustAddr := FormatAddr.SalesShptBillTo(CustAddr, ShipToAddr, SalesShipmentHeader);
    end;

    local procedure FormatDocumentFields(SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        with SalesShipmentHeader do begin
            FormatDocument.SetSalesPerson(SalesPurchPerson, "Salesperson Code", SalesPersonText);
            ReferenceText := FormatDocument.SetText("Your Reference" <> '', FieldCaption("Your Reference"));
        end;
    end;

    local procedure GetUnitOfMeasureDescr(UOMCode: Code[10]): Text[50]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if not UnitOfMeasure.Get(UOMCode) then
            exit(UOMCode);
        exit(UnitOfMeasure.Description);
    end;

    procedure BlanksForIndent(): Text[10]
    begin
        exit(PadStr('', 2, ' '));
    end;

    procedure GetAndIncDataItemCounter(): Integer
    begin
        DataItemCounter += 1;
        exit(DataItemCounter);
    end;
}

