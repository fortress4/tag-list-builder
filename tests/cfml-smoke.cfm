<cfscript>
controls = CreateObject('component', 'tag_list_builder.components.controls');
payload = '"><img src=x onerror="window.__cfmlXss=1">';
</cfscript>

<cfsavecontent variable="renderedControl"><cfset controls.renderTagListInputField(
    fieldName = 'securityTest',
    fieldID = 'securityTest',
    fieldLabel = payload,
    placeholder = payload,
    fieldValue = [payload, 'Washington, DC'],
    tagClass = payload,
    tagHoverClass = payload,
    messageText = payload
)></cfsavecontent>

<cfsavecontent variable="renderedItemControl"><cfset controls.renderTagListInputField(
    fieldName = 'itemTest',
    fieldID = 'itemTest',
    fieldValue = [
        { value = 'item-101', label = 'DisplayLabelOne' },
        { value = 'item-202', label = 'DisplayLabelTwo' },
        { value = 'item-303', label = payload }
    ]
)></cfsavecontent>

<cfscript>
report = {
    passed = ReFindNoCase('<(script|img)[[:space:]>]', renderedControl) == 0 &&
        ReFindNoCase('<(script|img)[[:space:]>]', renderedItemControl) == 0 &&
        FindNoCase('data-valueformat="json"', renderedControl) > 0 &&
        FindNoCase('data-normalizestoredcase="0"', renderedControl) > 0 &&
        FindNoCase('item-101', renderedItemControl) > 0 &&
        FindNoCase('DisplayLabelOne', renderedItemControl) > 0 &&
        ReFindNoCase('class="tagBuilder" value="[^"]*DisplayLabelOne', renderedItemControl) == 0,
    rawExecutableElementCount = ReFindNoCase('<(script|img)[[:space:]>]', renderedControl) + ReFindNoCase('<(script|img)[[:space:]>]', renderedItemControl),
    hasJsonFormat = FindNoCase('data-valueformat="json"', renderedControl) > 0,
    normalizeStoredCaseDefault = FindNoCase('data-normalizestoredcase="0"', renderedControl) > 0,
    itemValueRendered = FindNoCase('item-101', renderedItemControl) > 0,
    itemLabelRendered = FindNoCase('DisplayLabelOne', renderedItemControl) > 0,
    itemLabelExcludedFromSubmittedValue = ReFindNoCase('class="tagBuilder" value="[^"]*DisplayLabelOne', renderedItemControl) == 0
};
</cfscript>

<cfcontent type="application/json; charset=utf-8" reset="true"><cfoutput>#SerializeJSON(report)#</cfoutput>
