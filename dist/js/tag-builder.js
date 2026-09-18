/*
   tag-list-builder.js
   v0.3.0
*/

var tags_array = Object.create(null);
var tagBuilderDebug = 0;
var tbTagSequence = 0;
var tbPendingInitEvents = [];

var tbConfig = Object.create(null);
tbConfig.default = {
   tagSorting: 0,
   autoComplete: 0,
   tagCase: '',
   tagClass: 'bg-primary',
   tagHoverClass: 'bg-warning',
   readonly: 0,
   normalizeStoredCase: 0,
   valueFormat: 'json',
   maxTagLength: 100,
   maxTags: 100
};

$(function() {
   $('.tagBuilder').each(function(i, obj) {
      var tb_field = $(obj);
      var tb_field_id = tb_field.attr('id');
      var tb_wrapper = tb_field.parent('.tagBuilderWrapper');
      var tb_bin = tb_wrapper.find('.tagBuilderBin');
      var tb_msg = tb_wrapper.find('.tagBuilderMsg');
      var tb_add_field = tb_wrapper.find('.tagBuilderAdd');

      tb_initConfig(tb_field);
      tags_array[tb_field_id] = [];
      tb_msg.data('empty-message', tb_msg.text());

      try {
         var initialValues = tb_parseStoredValues(tb_field);

         $.each(initialValues, function(index, value) {
            var preparedTag = tb_prepareTag(tb_field, value);
            var validationError = tb_validatePreparedTag(tb_field, preparedTag, tags_array[tb_field_id].length);

            if (validationError) {
               throw new Error(validationError.message);
            }

            if (!tb_hasDuplicate(tb_field_id, preparedTag.key)) {
               tags_array[tb_field_id].push(preparedTag);
               tb_renderTag(tb_field, tb_bin, preparedTag);
            }
         });

         var migrated = tb_isLegacyStoredValue(tb_field);
         tb_writeStoredValue(tb_field, 'init', true);
         tb_updateEmptyState(tb_field, tb_bin, tb_msg);
         tb_pendingInitEvent(tb_field, migrated);
      }
      catch (error) {
         tags_array[tb_field_id] = [];
         tb_showInitializationError(tb_field, tb_bin, tb_msg, error.message);
      }

      if (tbConfig[tb_field_id].readonly) {
         tb_add_field.prop('disabled', true).attr('aria-disabled', 'true');
      }
      else {
         tb_add_field.on('keydown', function(event) {
            if (event.key === 'Enter') {
               event.preventDefault();
            }
         });

         tb_add_field.on('keyup', function(event) {
            if (event.key === 'Enter') {
               event.preventDefault();
               tb_addTag(tb_field, tb_bin, tb_msg, tb_add_field, event);
            }
         });
      }

      if (tbConfig[tb_field_id].tagSorting === 1 && !tbConfig[tb_field_id].readonly) {
         tb_initializeSortable(tb_field, tb_bin);
      }
   });

   window.setTimeout(function() {
      $.each(tbPendingInitEvents, function(index, pending) {
         tb_emit(pending.field, 'init', { values: tb_currentValues(pending.field.attr('id')), migrated: pending.migrated });
         pending.emitUpdate();
      });
      tbPendingInitEvents = [];
   }, 0);

   $('.tagBuilderBin').on('click', '.removeTag', function() {
      var removeIcon = $(this);
      var tagItem = removeIcon.closest('.tagBuilderTag');
      var tagBin = tagItem.parent();
      var fieldInput = tagBin.next('.tagBuilder');
      var fieldId = fieldInput.attr('id');
      var tagKey = tagItem.data('tag-key');

      if (tbConfig[fieldId].readonly) {
         return;
      }

      tb_removeTagByKey(fieldInput, tagKey);
   });

   $('.tagBuilderShowBtn').on('click', function() {
      var fieldButton = $(this);
      var fieldWrapper = fieldButton.parents('.tagBuilderWrapper');
      var fieldInput = fieldWrapper.find('.tagBuilder');
      var fieldInputType = fieldInput.attr('type');

      if (fieldInputType === 'hidden') {
         fieldInput.attr('type', 'text').prop('readonly', true);
         fieldButton.find('.tagBuilderShowEye').removeClass('fa-eye').addClass('fa-eye-slash');
         fieldButton.find('.tagBuilderShowArrow').removeClass('fa-caret-down').addClass('fa-caret-up');
         fieldButton.find('span').text('Hide Raw Tag List');
      }
      else if (fieldInputType === 'text') {
         fieldInput.attr('type', 'hidden');
         fieldButton.find('.tagBuilderShowEye').removeClass('fa-eye-slash').addClass('fa-eye');
         fieldButton.find('.tagBuilderShowArrow').removeClass('fa-caret-up').addClass('fa-caret-down');
         fieldButton.find('span').text('Show Raw Tag List');
      }
   });
});

function tb_initializeSortable(field, container) {
   var fieldId = field.attr('id');
   var sortableContainers = sortable(container, {
      orientation: 'horizontal',
      hoverClass: tbConfig[fieldId].tagHoverClass,
      placeholder: '<span class="tagBuilderPH badge rounded-pill bg-secondary p-2 me-2 mb-1">&nbsp;</span>'
   });

   if (!sortableContainers.length) {
      return;
   }

   sortableContainers[0].addEventListener('sortupdate', function(event) {
      var previousValues = tb_currentValues(fieldId);
      var reorderedTags = [];
      var items = event.detail.origin.items;

      $.each(items, function(index, item) {
         var tagKey = $(item).data('tag-key');
         var tag = tags_array[fieldId].find(function(candidate) {
            return candidate.key === tagKey;
         });

         if (tag) {
            reorderedTags.push(tag);
         }
      });

      if (reorderedTags.length !== tags_array[fieldId].length) {
         return;
      }

      tags_array[fieldId] = reorderedTags;
      tb_emit(field, 'sort', { values: tb_currentValues(fieldId), previous: previousValues });
      tb_writeStoredValue(field, 'sort', false, previousValues);

      if (tagBuilderDebug) {
         console.debug('Tag order updated for field:', fieldId);
      }
   });
}

function tb_addTag(field, container, message, addField, event) {
   var fieldId = field.attr('id');

   if (event.key !== 'Enter' || tbConfig[fieldId].readonly) {
      return;
   }

   event.preventDefault();
   event.stopPropagation();

   if (!tb_addValue(field, addField.val())) {
      return;
   }

   addField.val('');

   if (tbConfig[fieldId].autoComplete) {
      addField.parents('.typeahead__container').removeClass('cancel');
   }
}

$.fn.tagBuilder = function(action, value) {
   var method = action || 'get';
   var firstField = this.first();

   if (method === 'get') {
      tb_requireInitialized(firstField);
      return tb_currentValues(firstField.attr('id'));
   }

   if (method === 'config') {
      tb_requireInitialized(firstField);
      return $.extend({}, tbConfig[firstField.attr('id')]);
   }

   if (['set', 'add', 'remove', 'clear', 'refresh'].indexOf(method) === -1) {
      throw new Error('Unknown tagBuilder method: ' + method);
   }

   return this.each(function() {
      var field = $(this);
      tb_requireInitialized(field);

      if (method === 'set') {
         tb_replaceValues(field, value, 'set');
      }
      else if (method === 'add') {
         tb_addValue(field, value);
      }
      else if (method === 'remove') {
         tb_removeTagByKey(field, tb_prepareTag(field, value).key);
      }
      else if (method === 'clear') {
         tb_replaceValues(field, [], 'clear');
      }
      else if (method === 'refresh') {
         tb_refreshValues(field);
      }
   });
};

function tb_requireInitialized(field) {
   var fieldId = field.attr('id');
   if (!field.length || !fieldId || !tbConfig[fieldId] || !tags_array[fieldId]) {
      throw new Error('tagBuilder must be called on an initialized .tagBuilder field.');
   }
}

function tb_fieldParts(field) {
   var wrapper = field.parent('.tagBuilderWrapper');
   return {
      container: wrapper.find('.tagBuilderBin'),
      message: wrapper.find('.tagBuilderMsg')
   };
}

function tb_addValue(field, inputValue) {
   var fieldId = field.attr('id');
   var previousValues = tb_currentValues(fieldId);
   var preparedTag = tb_prepareTag(field, inputValue);
   var validationError = tb_validatePreparedTag(field, preparedTag, tags_array[fieldId].length);

   if (validationError) {
      tb_reject(field, preparedTag.value, validationError.code, validationError.message);
      return false;
   }

   if (tb_hasDuplicate(fieldId, preparedTag.key)) {
      tb_reject(field, preparedTag.value, 'duplicate', 'Tag must be unique.');
      return false;
   }

   var parts = tb_fieldParts(field);
   tags_array[fieldId].push(preparedTag);
   tb_renderTag(field, parts.container, preparedTag);
   tb_emit(field, 'add', { value: preparedTag.value, values: tb_currentValues(fieldId) });
   tb_writeStoredValue(field, 'add', false, previousValues);
   tb_updateEmptyState(field, parts.container, parts.message);
   tb_refreshSortable(field, parts.container);
   return true;
}

function tb_removeTagByKey(field, tagKey) {
   var fieldId = field.attr('id');
   var tagIndex = tags_array[fieldId].findIndex(function(tag) {
      return tag.key === tagKey;
   });

   if (tagIndex === -1) {
      return false;
   }

   var previousValues = tb_currentValues(fieldId);
   var removedValue = tags_array[fieldId][tagIndex].value;
   tags_array[fieldId].splice(tagIndex, 1);

   var parts = tb_fieldParts(field);
   parts.container.find('.tagBuilderTag').filter(function() {
      return $(this).data('tag-key') === tagKey;
   }).remove();

   tb_emit(field, 'remove', { value: removedValue, values: tb_currentValues(fieldId) });
   tb_writeStoredValue(field, 'remove', false, previousValues);
   tb_updateEmptyState(field, parts.container, parts.message);
   tb_refreshSortable(field, parts.container);
   return true;
}

function tb_replaceValues(field, values, reason) {
   if (!Array.isArray(values)) {
      throw new TypeError('tagBuilder set expects an array of string values.');
   }

   var fieldId = field.attr('id');
   var preparedTags = [];

   for (var index = 0; index < values.length; index++) {
      if (typeof values[index] !== 'string') {
         throw new TypeError('tagBuilder values must be strings.');
      }

      var preparedTag = tb_prepareTag(field, values[index]);
      var validationError = tb_validatePreparedTag(field, preparedTag, preparedTags.length);

      if (validationError) {
         tb_reject(field, preparedTag.value, validationError.code, validationError.message);
         return false;
      }

      if (preparedTags.some(function(tag) { return tag.key === preparedTag.key; })) {
         tb_reject(field, preparedTag.value, 'duplicate', 'Tag must be unique.');
         return false;
      }

      preparedTags.push(preparedTag);
   }

   var previousValues = tb_currentValues(fieldId);
   var parts = tb_fieldParts(field);
   tags_array[fieldId] = preparedTags;
   parts.container.empty();
   parts.message.removeClass('text-danger');

   $.each(preparedTags, function(tagIndex, tag) {
      tb_renderTag(field, parts.container, tag);
   });

   tb_writeStoredValue(field, reason || 'set', false, previousValues);
   tb_updateEmptyState(field, parts.container, parts.message);
   tb_refreshSortable(field, parts.container);
   return true;
}

function tb_refreshValues(field) {
   try {
      return tb_replaceValues(field, tb_parseStoredValues(field), 'refresh');
   }
   catch (error) {
      tb_emit(field, 'error', { message: error.message });
      return false;
   }
}

function tb_refreshSortable(field, container) {
   var fieldId = field.attr('id');
   if (tbConfig[fieldId].tagSorting === 1 && !tbConfig[fieldId].readonly) {
      sortable(container);
   }
}

function tb_prepareTag(field, inputValue) {
   var fieldId = field.attr('id');
   var enteredValue = String(inputValue == null ? '' : inputValue).trim();
   var normalizedValue = tb_applyTagCase(enteredValue, tbConfig[fieldId].tagCase);

   return {
      value: tbConfig[fieldId].normalizeStoredCase ? normalizedValue : enteredValue,
      key: normalizedValue,
      label: normalizedValue
   };
}

function tb_validatePreparedTag(field, tag, currentCount) {
   var fieldId = field.attr('id');
   var config = tbConfig[fieldId];

   if (!tag.value.length) {
      return { code: 'empty', message: 'Please enter a tag.' };
   }

   if (/[\u0000-\u001F\u007F]/.test(tag.value)) {
      return { code: 'controlCharacters', message: 'Tags cannot contain control characters.' };
   }

   if (tag.value.length > config.maxTagLength) {
      return { code: 'maxTagLength', message: 'Tags cannot exceed ' + config.maxTagLength + ' characters.' };
   }

   if (config.valueFormat === 'comma' && tag.value.indexOf(',') !== -1) {
      return { code: 'comma', message: 'Tags cannot contain commas when comma storage is enabled.' };
   }

   if (currentCount >= config.maxTags) {
      return { code: 'maxTags', message: 'No more than ' + config.maxTags + ' tags are allowed.' };
   }

   return '';
}

function tb_hasDuplicate(fieldId, tagKey) {
   return tags_array[fieldId].some(function(tag) {
      return tag.key === tagKey;
   });
}

function tb_parseStoredValues(field) {
   var fieldId = field.attr('id');
   var valueFormat = tbConfig[fieldId].valueFormat;
   var rawValue = field.attr('data-fieldvalue');
   rawValue = rawValue == null ? '' : String(rawValue).trim();

   if (!rawValue.length) {
      return [];
   }

   if (valueFormat === 'comma') {
      return rawValue.split(',');
   }

   var parsedValue;

   try {
      parsedValue = JSON.parse(rawValue);
   }
   catch (error) {
      var firstCharacter = rawValue.charAt(0);

      if (firstCharacter === '[' || firstCharacter === '{') {
         throw error;
      }

      return rawValue.split(',');
   }

   if (!Array.isArray(parsedValue)) {
      throw new Error('Saved JSON tag values must be an array.');
   }

   parsedValue.forEach(function(value) {
      if (typeof value !== 'string') {
         throw new Error('Every saved JSON tag value must be a string.');
      }
   });

   return parsedValue;
}

function tb_serializeStoredValues(field) {
   var fieldId = field.attr('id');
   var values = tags_array[fieldId].map(function(tag) {
      return tag.value;
   });

   if (tbConfig[fieldId].valueFormat === 'comma') {
      return values.join(',');
   }

   return JSON.stringify(values);
}

function tb_writeStoredValue(field, reason, deferEvents, previousOverride) {
   var fieldId = field.attr('id');
   var previous = previousOverride || tb_currentValues(fieldId);
   var serializedValue = tb_serializeStoredValues(field);
   field.val(serializedValue).attr('data-fieldvalue', serializedValue);

   var emitUpdate = function() {
      tb_emit(field, 'update', {
         values: tb_currentValues(fieldId),
         previous: previous,
         reason: reason || 'set',
         serialized: serializedValue
      });
   };

   if (deferEvents) {
      tbPendingInitEvents.push({ field: field, migrated: false, emitUpdate: emitUpdate });
   }
   else {
      emitUpdate();
   }
}

function tb_renderTag(field, container, tag) {
   var fieldId = field.attr('id');
   var config = tbConfig[fieldId];
   var tagClassList = '';
   var titleText = 'Tag: ' + tag.label;
   var tagId = fieldId + '_tag_' + (++tbTagSequence);

   if (config.tagSorting === 1 && !config.readonly) {
      tagClassList += ' dragTag';
      titleText = 'Drag to sort tag: ' + tag.label;
   }

   if (config.tagClass !== '') {
      tagClassList += ' ' + config.tagClass;
   }

   var tagNode = $('<span></span>', {
      id: tagId,
      'class': 'tagBuilderTag badge rounded-pill p-2 me-2 mb-1' + tagClassList,
      title: titleText
   }).text(tag.label).data('tag-key', tag.key);

   if (!config.readonly) {
      var removeIcon = $('<i></i>', {
         'class': 'removeTag fa-regular fa-circle-xmark ms-2',
         title: 'Click X to remove tag: ' + tag.label,
         role: 'button',
         tabindex: 0,
         'aria-label': 'Remove tag: ' + tag.label
      });

      tagNode.append(removeIcon);
   }

   container.append(tagNode);
}

function tb_updateEmptyState(field, container, message) {
   var fieldId = field.attr('id');

   if (tags_array[fieldId].length) {
      message.addClass('d-none');
      container.removeClass('d-none');
   }
   else {
      message.text(message.data('empty-message')).removeClass('d-none');
      container.addClass('d-none');
   }
}

function tb_showInitializationError(field, container, message, errorMessage) {
   container.addClass('d-none');
   message.text('Unable to initialize tags: ' + errorMessage).removeClass('d-none').addClass('text-danger');
   tb_emit(field, 'error', { message: errorMessage });
}

function tb_currentValues(fieldId) {
   return (tags_array[fieldId] || []).map(function(tag) { return tag.value; });
}

function tb_emit(field, name, detail) {
   var element = field && field[0];
   if (!element || typeof window.CustomEvent !== 'function') {
      return;
   }

   detail = detail || {};
   detail.fieldId = field.attr('id');

   try {
      element.dispatchEvent(new window.CustomEvent('tagBuilder:' + name, {
         detail: detail,
         bubbles: true
      }));
   }
   catch (error) {
      if (tagBuilderDebug && window.console && typeof window.console.warn === 'function') {
         window.console.warn('Tag Builder event listener failed:', error);
      }
   }
}

function tb_pendingInitEvent(field, migrated) {
   var pending = tbPendingInitEvents[tbPendingInitEvents.length - 1];
   if (pending && pending.field[0] === field[0]) {
      pending.migrated = migrated;
   }
}

function tb_isLegacyStoredValue(field) {
   var rawValue = field.attr('data-fieldvalue');
   if (tbConfig[field.attr('id')].valueFormat !== 'json' || rawValue == null || !String(rawValue).trim().length) {
      return false;
   }

   var trimmedValue = String(rawValue).trim();
   try {
      JSON.parse(trimmedValue);
      return false;
   }
   catch (error) {
      return trimmedValue.charAt(0) !== '[' && trimmedValue.charAt(0) !== '{';
   }
}

function tb_reject(field, value, reason, message) {
   tb_emit(field, 'reject', { value: value, reason: reason, message: message });
   tb_alert(message);
}

function tb_alert(message) {
   if (window.bootbox && typeof window.bootbox.alert === 'function') {
      window.bootbox.alert({
         title: 'Tag Builder Error',
         message: message,
         backdrop: true
      });
   }
   else {
      window.alert(message);
   }
}

function tb_initConfig(field) {
   var fieldId = field.attr('id');
   tbConfig[fieldId] = {};

   tbConfig[fieldId].autoComplete = tb_readBooleanAttribute(field, 'data-autocomplete', tbConfig.default.autoComplete);
   tbConfig[fieldId].tagSorting = tb_readBooleanAttribute(field, 'data-tagsorting', tbConfig.default.tagSorting);
   tbConfig[fieldId].readonly = tb_readBooleanAttribute(field, 'data-readonly', tbConfig.default.readonly);
   tbConfig[fieldId].normalizeStoredCase = tb_readBooleanAttribute(field, 'data-normalizestoredcase', tbConfig.default.normalizeStoredCase);
   tbConfig[fieldId].tagCase = tb_readEnumAttribute(field, 'data-tagcase', ['', 'lower', 'upper', 'capitalize'], tbConfig.default.tagCase);
   tbConfig[fieldId].valueFormat = tb_readEnumAttribute(field, 'data-valueformat', ['json', 'comma'], tbConfig.default.valueFormat);
   tbConfig[fieldId].tagClass = tb_readStringAttribute(field, 'data-tagclass', tbConfig.default.tagClass);
   tbConfig[fieldId].tagHoverClass = tb_readStringAttribute(field, 'data-taghoverclass', tbConfig.default.tagHoverClass);
   tbConfig[fieldId].maxTagLength = tb_readPositiveIntegerAttribute(field, 'data-maxtaglength', tbConfig.default.maxTagLength);
   tbConfig[fieldId].maxTags = tb_readPositiveIntegerAttribute(field, 'data-maxtags', tbConfig.default.maxTags);
}

function tb_readBooleanAttribute(field, attributeName, defaultValue) {
   var value = field.attr(attributeName);

   if (value == null || value === '') {
      return defaultValue;
   }

   value = String(value).toLowerCase();
   return value === '1' || value === 'true' || value === 'yes' ? 1 : 0;
}

function tb_readEnumAttribute(field, attributeName, allowedValues, defaultValue) {
   var value = field.attr(attributeName);

   if (value == null) {
      return defaultValue;
   }

   value = String(value).toLowerCase();
   return allowedValues.indexOf(value) !== -1 ? value : defaultValue;
}

function tb_readStringAttribute(field, attributeName, defaultValue) {
   var value = field.attr(attributeName);
   return value == null || value === '' ? defaultValue : String(value);
}

function tb_readPositiveIntegerAttribute(field, attributeName, defaultValue) {
   var value = Number.parseInt(field.attr(attributeName), 10);
   return Number.isInteger(value) && value > 0 ? value : defaultValue;
}

function tb_applyTagCase(value, tagCase) {
   if (tagCase === 'lower') {
      return value.toLowerCase();
   }

   if (tagCase === 'upper') {
      return value.toUpperCase();
   }

   if (tagCase === 'capitalize') {
      return tb_capitalizeStr(value);
   }

   return value;
}

function tb_capitalizeStr(value) {
   var result = value;
   result = tb_capitalizeBySeparator(result, ' ');
   result = tb_capitalizeBySeparator(result, '/');
   result = tb_capitalizeBySeparator(result, '(');
   return result;
}

function tb_capitalizeBySeparator(value, separator) {
   return value.split(separator).map(function(part) {
      return part.charAt(0).toUpperCase() + part.slice(1);
   }).join(separator);
}
