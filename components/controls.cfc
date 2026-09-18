<!---
   controls.cfc
--->
<cfcomponent displayname="controls" extends="base" hint="">

   <cffunction name="renderTagListInputField" access="public" ajaxAPI="0" output="yes" returntype="void">
      <cfargument name="fieldName" type="string" required="yes">
      <cfargument name="fieldID" type="string" required="false" default="#arguments.fieldName#">
      <cfargument name="fieldPrefix" type="string" required="false" default="">
      <cfargument name="fieldLabel" type="string" required="false" default="#arguments.fieldName#">
      <cfargument name="fieldClass" type="string" required="false" default="">
      <cfargument name="labelClass" type="string" required="false" default="">
      <cfargument name="required" type="boolean" required="false" default="false">
      <cfargument name="placeholder" type="string" required="false" default="#arguments.fieldLabel#">
      <cfargument name="fieldValue" type="any" required="false" default="">
      <cfargument name="readonly" type="boolean" required="false" default="false">
      <cfargument name="enableTagSorting" type="boolean" required="false" default="false" hint="Enable drag sorting">
      <cfargument name="tagCase" type="string" required="false" default="" hint="Display/duplicate case: lower, upper, or capitalize">
      <cfargument name="normalizeStoredCase" type="boolean" required="false" default="false" hint="Store normalized instead of entered casing">
      <cfargument name="valueFormat" type="string" required="false" default="json" hint="json (default) or deprecated comma format">
      <cfargument name="maxTagLength" type="numeric" required="false" default="100">
      <cfargument name="maxTags" type="numeric" required="false" default="100">
      <cfargument name="tagClass" type="string" required="false" default="">
      <cfargument name="tagHoverClass" type="string" required="false" default="">
      <cfargument name="validateTags" type="string" required="false" default="" hint="Deprecated/reserved; does not enforce validation">
      <cfargument name="addFieldClass" type="string" required="false" default="">
      <cfargument name="messageText" type="string" required="false" default="No Tags Added!">
      <cfargument name="showHiddenButton" type="boolean" required="false" default="false">
      <cfargument name="outputConfig" type="boolean" required="false" default="false">

      <cfscript>
         var req = arguments.required ? 1 : 0;
         var readonlyValue = arguments.readonly ? 1 : 0;
         var sortingValue = arguments.enableTagSorting ? 1 : 0;
         var normalizeStoredCaseValue = arguments.normalizeStoredCase ? 1 : 0;
         var disabledAttribute = arguments.readonly ? ' disabled="disabled" aria-disabled="true"' : '';

         arguments.fieldName = Trim(arguments.fieldName);
         arguments.fieldID = Trim(arguments.fieldID);
         arguments.fieldPrefix = Trim(arguments.fieldPrefix);
         arguments.labelClass = Trim(arguments.labelClass);
         arguments.tagCase = LCase(Trim(arguments.tagCase));
         arguments.valueFormat = LCase(Trim(arguments.valueFormat));

         if (Len(arguments.fieldPrefix))
            arguments.fieldID = arguments.fieldPrefix & '_' & arguments.fieldID;

         validateIdentifier(arguments.fieldName, 'fieldName');
         validateIdentifier(arguments.fieldID, 'fieldID');
         validateEnum(arguments.tagCase, ['', 'lower', 'upper', 'capitalize'], 'tagCase');
         validateEnum(arguments.valueFormat, ['json', 'comma'], 'valueFormat');
         validatePositiveInteger(arguments.maxTagLength, 'maxTagLength');
         validatePositiveInteger(arguments.maxTags, 'maxTags');

         if (arguments.required) {
            arguments.labelClass &= ' required';
            if (Len(Trim(arguments.placeholder)) && !Len(Trim(arguments.fieldLabel)))
               arguments.placeholder &= ' *';
         }

         var serializedFieldValue = serializeTagFieldValue(arguments.fieldValue, arguments.valueFormat);
         var serializedFieldItems = serializeTagFieldItems(arguments.fieldValue, arguments.valueFormat);
         var encodedFieldName = EncodeForHTMLAttribute(arguments.fieldName);
         var encodedFieldID = EncodeForHTMLAttribute(arguments.fieldID);
         var encodedFieldClass = EncodeForHTMLAttribute(arguments.fieldClass);
         var encodedLabelClass = EncodeForHTMLAttribute(arguments.labelClass);
         var encodedAddFieldClass = EncodeForHTMLAttribute(arguments.addFieldClass);
         var encodedPlaceholder = EncodeForHTMLAttribute(arguments.placeholder);
         var encodedFieldValue = EncodeForHTMLAttribute(serializedFieldValue);
         var encodedFieldItems = EncodeForHTMLAttribute(serializedFieldItems);
         var encodedTagCase = EncodeForHTMLAttribute(arguments.tagCase);
         var encodedValueFormat = EncodeForHTMLAttribute(arguments.valueFormat);
         var encodedTagClass = EncodeForHTMLAttribute(arguments.tagClass);
         var encodedTagHoverClass = EncodeForHTMLAttribute(arguments.tagHoverClass);
         var encodedValidateTags = EncodeForHTMLAttribute(arguments.validateTags);
         var encodedFieldLabel = EncodeForHTML(arguments.fieldLabel);
         var encodedMessageText = EncodeForHTML(arguments.messageText);
      </cfscript>

      <div class="tagBuilderWrapper #encodedFieldClass#">
         <label for="#encodedFieldID#_add" class="tagBuilderFieldLabel #encodedLabelClass#">#encodedFieldLabel#</label>
         <input type="text" id="#encodedFieldID#_add" name="#encodedFieldName#_add" class="tagBuilderAdd form-control-sm #encodedAddFieldClass#" placeholder="#encodedPlaceholder#" autocomplete="off"#disabledAttribute#>

         <div id="#encodedFieldID#_msg" class="tagBuilderMsg">#encodedMessageText#</div>
         <div id="#encodedFieldID#_bin" class="tagBuilderBin"></div>
         <input type="hidden" id="#encodedFieldID#" name="#encodedFieldName#" class="tagBuilder" value="#encodedFieldValue#"
            data-fieldvalue="#encodedFieldItems#"
            data-required="#req#"
            data-readonly="#readonlyValue#"
            data-autocomplete="0"
            data-tagsorting="#sortingValue#"
            data-normalizestoredcase="#normalizeStoredCaseValue#"
            data-valueformat="#encodedValueFormat#"
            data-maxtaglength="#Int(arguments.maxTagLength)#"
            data-maxtags="#Int(arguments.maxTags)#"
            <cfif Len(arguments.tagCase)>data-tagcase="#encodedTagCase#"</cfif>
            <cfif Len(Trim(arguments.tagClass))>data-tagclass="#encodedTagClass#"</cfif>
            <cfif Len(Trim(arguments.tagHoverClass))>data-taghoverclass="#encodedTagHoverClass#"</cfif>
            data-validatetags="#encodedValidateTags#">

         <cfif arguments.showHiddenButton>
            #renderShowHiddenButton(fieldID=arguments.fieldID, readonly=arguments.readonly)#
         </cfif>
      </div>

      <cfif arguments.outputConfig>
         <cfset arguments.typeahead = false>
         #renderControlConfigOptions(argumentCollection=arguments)#
      </cfif>
   </cffunction>

   <cffunction name="renderTagListTypeAheadInputField" access="public" ajaxAPI="0" output="yes" returntype="void">
      <cfargument name="fieldName" type="string" required="yes">
      <cfargument name="fieldID" type="string" required="false" default="#arguments.fieldName#">
      <cfargument name="fieldPrefix" type="string" required="false" default="">
      <cfargument name="fieldLabel" type="string" required="false" default="#arguments.fieldName#">
      <cfargument name="fieldClass" type="string" required="false" default="">
      <cfargument name="labelClass" type="string" required="false" default="">
      <cfargument name="required" type="boolean" required="false" default="false">
      <cfargument name="placeholder" type="string" required="false" default="#arguments.fieldLabel#">
      <cfargument name="autocomplete" type="boolean" required="false" default="true">
      <cfargument name="fieldValue" type="any" required="false" default="">
      <cfargument name="readonly" type="boolean" required="false" default="false">
      <cfargument name="enableTagSorting" type="boolean" required="false" default="false" hint="Enable drag sorting">
      <cfargument name="tagCase" type="string" required="false" default="" hint="Display/duplicate case: lower, upper, or capitalize">
      <cfargument name="normalizeStoredCase" type="boolean" required="false" default="false" hint="Store normalized instead of entered casing">
      <cfargument name="valueFormat" type="string" required="false" default="json" hint="json (default) or deprecated comma format">
      <cfargument name="maxTagLength" type="numeric" required="false" default="100">
      <cfargument name="maxTags" type="numeric" required="false" default="100">
      <cfargument name="tagClass" type="string" required="false" default="">
      <cfargument name="tagHoverClass" type="string" required="false" default="">
      <cfargument name="validateTags" type="string" required="false" default="" hint="Deprecated/reserved; does not enforce validation">
      <cfargument name="addFieldClass" type="string" required="false" default="">
      <cfargument name="messageText" type="string" required="false" default="No Tags Added!">
      <cfargument name="showHiddenButton" type="boolean" required="false" default="false">
      <cfargument name="outputConfig" type="boolean" required="false" default="false">

      <cfscript>
         var req = arguments.required ? 1 : 0;
         var readonlyValue = arguments.readonly ? 1 : 0;
         var sortingValue = arguments.enableTagSorting ? 1 : 0;
         var autocompleteValue = arguments.autocomplete ? 1 : 0;
         var normalizeStoredCaseValue = arguments.normalizeStoredCase ? 1 : 0;
         var disabledAttribute = arguments.readonly ? ' disabled="disabled" aria-disabled="true"' : '';

         arguments.fieldName = Trim(arguments.fieldName);
         arguments.fieldID = Trim(arguments.fieldID);
         arguments.fieldPrefix = Trim(arguments.fieldPrefix);
         arguments.labelClass = Trim(arguments.labelClass);
         arguments.tagCase = LCase(Trim(arguments.tagCase));
         arguments.valueFormat = LCase(Trim(arguments.valueFormat));

         if (Len(arguments.fieldPrefix))
            arguments.fieldID = arguments.fieldPrefix & '_' & arguments.fieldID;

         validateIdentifier(arguments.fieldName, 'fieldName');
         validateIdentifier(arguments.fieldID, 'fieldID');
         validateEnum(arguments.tagCase, ['', 'lower', 'upper', 'capitalize'], 'tagCase');
         validateEnum(arguments.valueFormat, ['json', 'comma'], 'valueFormat');
         validatePositiveInteger(arguments.maxTagLength, 'maxTagLength');
         validatePositiveInteger(arguments.maxTags, 'maxTags');

         if (arguments.required) {
            arguments.labelClass &= ' required';
            if (Len(Trim(arguments.placeholder)) && !Len(Trim(arguments.fieldLabel)))
               arguments.placeholder &= ' *';
         }

         var serializedFieldValue = serializeTagFieldValue(arguments.fieldValue, arguments.valueFormat);
         var serializedFieldItems = serializeTagFieldItems(arguments.fieldValue, arguments.valueFormat);
         var encodedFieldName = EncodeForHTMLAttribute(arguments.fieldName);
         var encodedFieldID = EncodeForHTMLAttribute(arguments.fieldID);
         var encodedFieldClass = EncodeForHTMLAttribute(arguments.fieldClass);
         var encodedLabelClass = EncodeForHTMLAttribute(arguments.labelClass);
         var encodedAddFieldClass = EncodeForHTMLAttribute(arguments.addFieldClass);
         var encodedPlaceholder = EncodeForHTMLAttribute(arguments.placeholder);
         var encodedFieldValue = EncodeForHTMLAttribute(serializedFieldValue);
         var encodedFieldItems = EncodeForHTMLAttribute(serializedFieldItems);
         var encodedTagCase = EncodeForHTMLAttribute(arguments.tagCase);
         var encodedValueFormat = EncodeForHTMLAttribute(arguments.valueFormat);
         var encodedTagClass = EncodeForHTMLAttribute(arguments.tagClass);
         var encodedTagHoverClass = EncodeForHTMLAttribute(arguments.tagHoverClass);
         var encodedValidateTags = EncodeForHTMLAttribute(arguments.validateTags);
         var encodedFieldLabel = EncodeForHTML(arguments.fieldLabel);
         var encodedMessageText = EncodeForHTML(arguments.messageText);
      </cfscript>

      <div class="tagBuilderWrapper #encodedFieldClass#">
         <label for="#encodedFieldID#_add" class="tagBuilderFieldLabel #encodedLabelClass#">#encodedFieldLabel#</label>
         <div class="typeahead__container">
            <div class="typeahead__field">
               <div class="typeahead__query">
                  <input type="text" id="#encodedFieldID#_add" name="#encodedFieldName#_add" class="tagBuilderAdd typeahead #encodedAddFieldClass#" placeholder="#encodedPlaceholder#" autocomplete="off"#disabledAttribute#>
               </div>
            </div>
         </div>

         <div id="#encodedFieldID#_msg" class="tagBuilderMsg">#encodedMessageText#</div>
         <div id="#encodedFieldID#_bin" class="tagBuilderBin"></div>
         <input type="hidden" id="#encodedFieldID#" name="#encodedFieldName#" class="tagBuilder" value="#encodedFieldValue#"
            data-fieldvalue="#encodedFieldItems#"
            data-required="#req#"
            data-readonly="#readonlyValue#"
            data-autocomplete="#autocompleteValue#"
            data-tagsorting="#sortingValue#"
            data-normalizestoredcase="#normalizeStoredCaseValue#"
            data-valueformat="#encodedValueFormat#"
            data-maxtaglength="#Int(arguments.maxTagLength)#"
            data-maxtags="#Int(arguments.maxTags)#"
            <cfif Len(arguments.tagCase)>data-tagcase="#encodedTagCase#"</cfif>
            <cfif Len(Trim(arguments.tagClass))>data-tagclass="#encodedTagClass#"</cfif>
            <cfif Len(Trim(arguments.tagHoverClass))>data-taghoverclass="#encodedTagHoverClass#"</cfif>
            data-validatetags="#encodedValidateTags#">

         <cfif arguments.showHiddenButton>
            #renderShowHiddenButton(fieldID=arguments.fieldID, readonly=arguments.readonly)#
         </cfif>
      </div>

      <cfif arguments.outputConfig>
         <cfset arguments.typeahead = true>
         #renderControlConfigOptions(argumentCollection=arguments)#
      </cfif>
   </cffunction>

   <cffunction name="renderControlConfigOptions" access="public" output="yes" returntype="void">
      <cfargument name="fieldID" type="string" required="true">
      <cfargument name="typeahead" type="boolean" required="false" default="true">
      <cfargument name="enableTagSorting" type="boolean" required="false" default="false">
      <cfargument name="tagCase" type="string" required="false" default="">
      <cfargument name="normalizeStoredCase" type="boolean" required="false" default="false">
      <cfargument name="valueFormat" type="string" required="false" default="json">
      <cfargument name="tagClass" type="string" required="false" default="">
      <cfargument name="tagHoverClass" type="string" required="false" default="">

      <cfscript>
         var encodedFieldID = EncodeForHTMLAttribute(arguments.fieldID);
         var encodedTagCase = EncodeForHTML(arguments.tagCase);
         var encodedValueFormat = EncodeForHTML(arguments.valueFormat);
         var encodedTagClass = EncodeForHTML(arguments.tagClass);
         var encodedTagHoverClass = EncodeForHTML(arguments.tagHoverClass);
      </cfscript>

      <div id="#encodedFieldID#_config" class="small">
         <hr class="mt-4">
         <div>Configured Options:</div>
         <ul>
            <li>TypeAhead: #YesNoFormat(arguments.typeahead)#</li>
            <li>Enable Tag Sorting: #YesNoFormat(arguments.enableTagSorting)#</li>
            <li>Tag Case: <cfif Len(Trim(arguments.tagCase))>#encodedTagCase#<cfelse><em>Not Set</em></cfif></li>
            <li>Normalize Stored Case: #YesNoFormat(arguments.normalizeStoredCase)#</li>
            <li>Value Format: #encodedValueFormat#<cfif arguments.valueFormat EQ 'comma'> (Deprecated)</cfif></li>
            <cfif Len(Trim(arguments.tagClass))><li>Tag Class: #encodedTagClass#</li></cfif>
            <cfif arguments.enableTagSorting AND Len(Trim(arguments.tagHoverClass))><li>Sort Hover Class: #encodedTagHoverClass#</li></cfif>
         </ul>
      </div>
   </cffunction>

   <cffunction name="renderShowHiddenButton" access="public" output="yes" returntype="void">
      <cfargument name="fieldID" type="string" required="true">
      <cfargument name="readonly" type="boolean" required="false" default="false">

      <cfset var encodedFieldID = EncodeForHTMLAttribute(arguments.fieldID)>

      <div class="row d-flex">
         <div class="col"></div>
         <div class="w-50 d-flex justify-content-end">
            <button type="button" id="#encodedFieldID#_showbtn" class="btn btn-secondary btn-sm text-right tagBuilderShowBtn"><i class="fa-regular fa-eye me-2 tagBuilderShowEye"></i><span>Show Raw Tag List</span><i class="fa-solid fa-caret-down ms-2 tagBuilderShowArrow"></i></button>
         </div>
      </div>
   </cffunction>

   <cffunction name="validateIdentifier" access="private" output="no" returntype="void">
      <cfargument name="value" type="string" required="true">
      <cfargument name="argumentName" type="string" required="true">

      <cfif NOT ReFind("^[A-Za-z_][A-Za-z0-9_.:\[\]-]*$", arguments.value)>
         <cfthrow type="TagListBuilder.InvalidArgument" message="Invalid #arguments.argumentName# value.">
      </cfif>
   </cffunction>

   <cffunction name="validateEnum" access="private" output="no" returntype="void">
      <cfargument name="value" type="string" required="true">
      <cfargument name="allowedValues" type="array" required="true">
      <cfargument name="argumentName" type="string" required="true">

      <cfif NOT ArrayFindNoCase(arguments.allowedValues, arguments.value)>
         <cfthrow type="TagListBuilder.InvalidArgument" message="Invalid #arguments.argumentName# value.">
      </cfif>
   </cffunction>

   <cffunction name="validatePositiveInteger" access="private" output="no" returntype="void">
      <cfargument name="value" type="numeric" required="true">
      <cfargument name="argumentName" type="string" required="true">

      <cfif NOT IsValid("integer", arguments.value)>
         <cfthrow type="TagListBuilder.InvalidArgument" message="#arguments.argumentName# must be a positive integer.">
      </cfif>

      <cfif arguments.value LTE 0>
         <cfthrow type="TagListBuilder.InvalidArgument" message="#arguments.argumentName# must be a positive integer.">
      </cfif>
   </cffunction>

   <cffunction name="serializeTagFieldValue" access="private" output="no" returntype="string">
      <cfargument name="fieldValue" type="any" required="true">
      <cfargument name="valueFormat" type="string" required="true">

      <cfscript>
         var items = parseTagFieldItems(arguments.fieldValue, arguments.valueFormat);
         var values = [];
         var item = '';

         for (item in items)
            ArrayAppend(values, item.value);

         return arguments.valueFormat == 'json' ? SerializeJSON(values) : ArrayToList(values);
      </cfscript>
   </cffunction>

   <cffunction name="serializeTagFieldItems" access="private" output="no" returntype="string">
      <cfargument name="fieldValue" type="any" required="true">
      <cfargument name="valueFormat" type="string" required="true">

      <cfscript>
         var items = parseTagFieldItems(arguments.fieldValue, arguments.valueFormat);
         var serializedItems = [];
         var values = [];
         var item = '';

         for (item in items) {
            ArrayAppend(values, item.value);
            if (item.hasCustomLabel)
               ArrayAppend(serializedItems, { "value"=item.value, "label"=item.label });
            else
               ArrayAppend(serializedItems, item.value);
         }

         return arguments.valueFormat == 'json' ? SerializeJSON(serializedItems) : ArrayToList(values);
      </cfscript>
   </cffunction>

   <cffunction name="parseTagFieldItems" access="private" output="no" returntype="array">
      <cfargument name="fieldValue" type="any" required="true">
      <cfargument name="valueFormat" type="string" required="true">

      <cfscript>
         var sourceItems = [];
         var items = [];
         var rawValue = '';
         var parsedValue = '';
         var item = '';
         var itemValue = '';
         var itemLabel = '';

         if (IsArray(arguments.fieldValue)) {
            sourceItems = arguments.fieldValue;
         }
         else {
            if (!IsSimpleValue(arguments.fieldValue))
               throw(type='TagListBuilder.InvalidFieldValue', message='fieldValue must be an array or serialized string.');

            rawValue = Trim(ToString(arguments.fieldValue));

            if (!Len(rawValue))
               return items;

            if (arguments.valueFormat == 'comma') {
               sourceItems = ListToArray(rawValue);
            }
            else if (IsJSON(rawValue)) {
               parsedValue = DeserializeJSON(rawValue);
               if (!IsArray(parsedValue))
                  throw(type='TagListBuilder.InvalidFieldValue', message='JSON fieldValue must be an array.');
               sourceItems = parsedValue;
            }
            else {
               sourceItems = ListToArray(rawValue);
            }
         }

         for (item in sourceItems) {
            if (IsStruct(item)) {
               if (arguments.valueFormat == 'comma')
                  throw(type='TagListBuilder.InvalidFieldValue', message='Value/label tag items require JSON storage.');
               if (!StructKeyExists(item, 'value') || !IsSimpleValue(item.value))
                  throw(type='TagListBuilder.InvalidFieldValue', message='Every tag item requires a simple value.');
               if (StructKeyExists(item, 'label') && !IsSimpleValue(item.label))
                  throw(type='TagListBuilder.InvalidFieldValue', message='Every tag item label must be a simple value.');

               itemValue = ToString(item.value);
               itemLabel = StructKeyExists(item, 'label') ? ToString(item.label) : itemValue;
               ArrayAppend(items, { value=itemValue, label=itemLabel, hasCustomLabel=true });
            }
            else {
               if (!IsSimpleValue(item))
                  throw(type='TagListBuilder.InvalidFieldValue', message='Every tag value must be a string or value/label item.');

               itemValue = ToString(item);
               if (arguments.valueFormat == 'comma' && Find(',', itemValue))
                  throw(type='TagListBuilder.InvalidFieldValue', message='Tag values cannot contain commas when comma storage is enabled.');
               ArrayAppend(items, { value=itemValue, label=itemValue, hasCustomLabel=false });
            }
         }

         return items;
      </cfscript>
   </cffunction>

</cfcomponent>
