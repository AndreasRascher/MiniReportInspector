# Mini Report Inspector

The Mini Report Inspector enables you to export informations about the report DataSet in 3 different formats:


* **SaveAsXML** the Result from Report.SaveAsxml
* **ResultSet XML** the Dataset format known from the windows client as XML File
* **Excel** the Dataset format known from the windows client as Excel File

## Limitations:
Only available for Reports with integrated RDLC Layout.
The data is collected by parsing the SaveAsXML File (Columns) and the RLDC File (Order of Columns). Not all Metadata is available to recreate a complete DataSet.xml like in the windows client (e.g. XSD Section).


## Integration Types

### "Report Layout Selection" Integration
Start by clicking "Mini Report Inspector" Action.

[<img src="images/A01_ReportLayoutSelection.png" width="400"/>](RepLayoutSelection01)

Set your filters in the SaveRequestPage dialog.

[<img src="images/A02_RunReqPage.png" width="400"/>](RepLayoutSelection02)

Choose the export format from the Stringmenu.

[<img src="images/A03_SelectFormat.png" width="400"/>](RepLayoutSelection03)

### "Report Request Page" Integration
Toggle the Export DataSet Control

[<img src="images/B01_ReqPageIntegration.png" width="400"/>](RequestPageIntegration01)

Set your filters and export format in the SaveRequestPage dialog.

[<img src="images/B02_ReqPageIntegration.png" width="400"/>](RequestPageIntegration02)