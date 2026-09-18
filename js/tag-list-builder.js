/*
   tag-list-builder.js
   v0.2.0
*/

var tags_array = Object.create(null);
var tagBuilderDebug = 0;
var tbTagSequence = 0;

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
               throw new Error(validationError);
            }

            if (!tb_hasDuplicate(tb_field_id, preparedTag.key)) {
               tags_array[tb_field_id].push(preparedTag);
               tb_renderTag(tb_field, tb_bin, preparedTag);
            }
         });

         tb_writeStoredValue(tb_field);
         tb_updateEmptyState(tb_field, tb_bin, tb_msg);
      }
      catch (error) {
         tags_array[tb_field_id] = [];
         tb_showInitializationError(tb_bin, tb_msg, error.message);
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

   $('.tagBuilderBin').on('click', '.removeTag', function() {
      var removeIcon = $(this);
      var tagItem = removeIcon.closest('.tagBuilderTag');
      var tagBin = tagItem.parent();
      var fieldInput = tagBin.next('.tagBuilder');
      var fieldId = fieldInput.attr('id');
      var fieldWrapper = tagBin.parent('.tagBuilderWrapper');
      var fieldMsg = fieldWrapper.find('.tagBuilderMsg');
      var tagKey = tagItem.data('tag-key');

      if (tbConfig[fieldId].readonly) {
         return;
      }

      var tagIndex = tags_array[fieldId].findIndex(function(tag) {
         return tag.key === tagKey;
      });

      if (tagIndex === -1) {
         return;
      }

      tags_array[fieldId].splice(tagIndex, 1);
      tagItem.remove();
      tb_writeStoredValue(fieldInput);
      tb_updateEmptyState(fieldInput, tagBin, fieldMsg);

      if (tbConfig[fieldId].tagSorting === 1) {
         sortable(tagBin);
      }
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
      tb_writeStoredValue(field);

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

   var preparedTag = tb_prepareTag(field, addField.val());
   var validationError = tb_validatePreparedTag(field, preparedTag, tags_array[fieldId].length);

   if (validationError) {
      tb_alert(validationError);
      return;
   }

   if (tb_hasDuplicate(fieldId, preparedTag.key)) {
      tb_alert('Tag must be unique.');
      return;
   }

   tags_array[fieldId].push(preparedTag);
   tb_renderTag(field, container, preparedTag);
   tb_writeStoredValue(field);
   addField.val('');
   tb_updateEmptyState(field, container, message);

   if (tbConfig[fieldId].tagSorting === 1) {
      sortable(container);
   }

   if (tbConfig[fieldId].autoComplete) {
      addField.parents('.typeahead__container').removeClass('cancel');
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
      return 'Please enter a tag.';
   }

   if (/[\u0000-\u001F\u007F]/.test(tag.value)) {
      return 'Tags cannot contain control characters.';
   }

   if (tag.value.length > config.maxTagLength) {
      return 'Tags cannot exceed ' + config.maxTagLength + ' characters.';
   }

   if (config.valueFormat === 'comma' && tag.value.indexOf(',') !== -1) {
      return 'Tags cannot contain commas when comma storage is enabled.';
   }

   if (currentCount >= config.maxTags) {
      return 'No more than ' + config.maxTags + ' tags are allowed.';
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

function tb_writeStoredValue(field) {
   var serializedValue = tb_serializeStoredValues(field);
   field.val(serializedValue).attr('data-fieldvalue', serializedValue);
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

function tb_showInitializationError(container, message, errorMessage) {
   container.addClass('d-none');
   message.text('Unable to initialize tags: ' + errorMessage).removeClass('d-none').addClass('text-danger');
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
