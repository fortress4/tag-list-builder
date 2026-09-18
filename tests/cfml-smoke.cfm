<cfscript>
controls = CreateObject('component', '../components/controls');
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

<cfscript>
report = {
    passed = ReFindNoCase('<(script|img)[[:space:]>]', renderedControl) == 0 &&
        FindNoCase('data-valueformat="json"', renderedControl) > 0 &&
        FindNoCase('data-normalizestoredcase="0"', renderedControl) > 0,
    rawExecutableElementCount = ReFindNoCase('<(script|img)[[:space:]>]', renderedControl),
    hasJsonFormat = FindNoCase('data-valueformat="json"', renderedControl) > 0,
    normalizeStoredCaseDefault = FindNoCase('data-normalizestoredcase="0"', renderedControl) > 0
};
</cfscript>

<cfcontent type="application/json; charset=utf-8" reset="true"><cfoutput>#SerializeJSON(report)#</cfoutput>
