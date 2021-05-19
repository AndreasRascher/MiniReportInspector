codeunit 80005 "RDLTablixBuilderEventSubs"
{
    EventSubscriberInstance = Manual;
    [EventSubscriber(ObjectType::Table, Database::"Custom Report Layout", 'OnBeforeUpdateLayout', '', true, true)]
    local procedure Handle_CustomReportLayout(var IsHandled: Boolean; var LayoutUpdated: Boolean)
    begin
        IsHandled := true;
    end;
}