/*
   tag-builder.js
*/

// declare variable to hold the value from input field
var tags_array = {};
var tagBuilderDebug = 1;

$(function() {

   // Init each of the tagBuilder Field Groups
   $('.tagBuilder').each(function(i, obj) {
      //console.log('tb_fields: ', i, obj);

      var tb_field = $(obj);
      var tb_field_id = tb_field.attr('id');
      var tb_sortTags = tb_field.data('tagsorting');
      var tb_autoComplete = tb_field.data('autocomplete');

      tags_array[tb_field_id] = [];

      // console.log('tb_field: ', i, obj);
      // console.log('tb_field_id: ', tb_field_id);
      // console.log('tb_sortTags: ', tb_sortTags);
      // console.log('tags_array: ', tb_field_id, tags_array[tb_field_id]);

      var tb_wrapper = tb_field.parent('.tagBuilderWrapper');

      var tb_bin = tb_wrapper.find('.tagBuilderBin');
      // var tb_bin = tb_field.prevAll('.tagBuilderBin');
      // var tb_bin_id = tb_bin.attr('id');

      // console.log('tb_bin: ',tb_bin);
      // console.log('tb_bin_id: ',tb_bin_id);

      var tb_msg = tb_wrapper.find('.tagBuilderMsg');
      //var tb_msg = tb_field.prevAll('.tagBuilderMsg');
      //var tb_msg_id = tb_msg.attr('id');

      // console.log('tb_msg: ',tb_msg);
      // console.log('tb_msg_id: ',tb_msg_id);

      var tb_add_field = tb_wrapper.find('.tagBuilderAdd');
      //var tb_add_field_id = tb_add_field.attr('id');

      // console.log('tb_add_field: ',tb_add_field);
      // console.log('tb_add_field_id: ',tb_add_field_id);

      // Populate the tags field with the current values
      var fldValue = tb_field.data('fieldvalue');
      var fldValueArr = [];

      if ( fldValue.trim().length )
         fldValueArr = fldValue.split(',');

      //console.log('fldValueArr: ',fldValueArr);

      if ( fldValueArr.length > 0 ) {
         tb_msg.addClass('d-none');
         tb_bin.removeClass('d-none');

         $.each(fldValueArr, function(index, value){
            tags_array[tb_field_id].push(value);
            tb_renderTag(tb_field,tb_bin,value,tb_sortTags);
         });
         tb_addTagToHiddenField(tb_field,fldValueArr);
      }
      else {
         tb_msg.removeClass('d-none');
         tb_bin.addClass('d-none');
      }

      // Add Field KeyDown Event (block submit)
      tb_add_field.keydown(function(e) {
        if (e.keyCode == 13)
            e.preventDefault();

         //if ( autocomplete )
         //addfield.prev('.typeahead__cancel-button').removeClass('d-none');
         // addfield.prev('.typeahead__cancel-button').css('visibility', 'visible');
      });

      // Add Field KeyUp Event
      tb_add_field.keyup(function(e) {
         if (e.keyCode == 13) {
            e.preventDefault();

            //console.log('tb_add_field:', tb_add_field);

            tb_addTag(tb_field,tb_bin,tb_msg,tb_add_field,e);
         }
      });

      if ( tb_sortTags == 1 )
      {
         sortable(tb_bin, {
             orientation: 'horizontal',
             hoverClass: 'bg-warning',
             placeholder: '<span class="tagBuilderPH badge rounded-pill bg-secondary p-2 me-2 mb-1" style="width:90px">&nbsp;</span>',
         });

         sortable(tb_bin)[0].addEventListener('sortupdate', function(e) {
             var itemsArr = e.detail.origin.items;
             var tagArr = [];

             $.each( itemsArr, function( key, value ) {
                itemText = $(value).text();
                tagArr.push(itemText);
             });

             tags_array[tb_field_id] = tagArr;

             var fldValues = tagArr.join(',');
             tb_field.val(fldValues).data('fieldvalue',fldValues);

             // Sort Debug output
             if ( tagBuilderDebug )
             {
                console.log('tags_array: ',tb_field_id,tags_array[tb_field_id]);
                var dataAttr = tb_field.data('fieldvalue');
                console.log('data-fieldvalue: ',dataAttr);
                var dataVal = tb_field.val();
                console.log('hidden value: ',dataVal);
              }
         });
      }
      //console.log('tags_array: ', tags_array);
    });

   // CLick the X in the Tag item
   $('.tagBuilderBin').on('click', 'i', function() {
      var tagItm = $(this).parent();
      var itmName = tagItm.text();
      var tagBin = tagItm.parent();
      var fldInput = tagBin.next('.tagBuilder');
      var fldId = fldInput.attr('id');
      var fldWrapper = tagBin.parent('.tagBuilderWrapper');
      var fldMsg = fldWrapper.find('.tagBuilderMsg');
      var sortTags = fldInput.data('tagsorting');

      // console.log('tagItm: ',tagItm);
      // console.log('fldWrapper: ',fldWrapper);

      tags_array[fldId].splice(tags_array[fldId].indexOf(itmName), 1);
      tagItm.remove();
      tb_removeTagFromHiddenField(fldInput,tags_array[fldId]);

      if ( tags_array[fldId] == 0 ) {
         fldMsg.removeClass('d-none');
         tagBin.addClass('d-none');
      }

      if ( sortTags == 1 )
         sortable(fldInput); // Refresh the Sortable Container
   });

   $('.tagBuilderShowBtn').click(function() {
       var fldBtn = $(this);
       var fldWrapper = fldBtn.parents('.tagBuilderWrapper');
       var fldInput = fldWrapper.find('.tagBuilder');

       if ( fldInput.hasClass('d-none') ) {
          fldInput.removeClass('d-none');
          fldBtn.find('.tagBuilderShowEye').removeClass('fa-eye').addClass('fa-eye-slash');
          fldBtn.find('.tagBuilderShowArrow').removeClass('fa-caret-down').addClass('fa-caret-up');
          fldBtn.find('span').text('Hide Raw Tag List');
       }
       else {
         fldInput.addClass('d-none');
         fldBtn.find('.tagBuilderShowEye').removeClass('fa-eye-slash').addClass('fa-eye');
         fldBtn.find('.tagBuilderShowArrow').removeClass('fa-caret-up').addClass('fa-caret-down');
         fldBtn.find('span').text('Show Raw Tag List');
       }
   });

});

function tb_addTag(field,container,msgdiv,addfield,event) {

   // console.log('ADD TAG: event.keyCode:', event.keyCode);
   //console.log('field: ', field);
   // console.log('container: ', container);
   // console.log('msgdiv: ', msgdiv);
   // console.log('addfield: ', addfield);

   var field_id = field.attr('id');
   var sort_tags = field.data('tagsorting');
   var autocomplete = field.data('autocomplete');
   var new_tag = addfield.val().trim();

   //console.log('new_tag: ', new_tag);
//debugger;

   if (event.keyCode == 13) {
      event.preventDefault();
      event.stopPropagation();

      //let index = tags_array[field_id].indexOf(new_tag);
      //console.log('index:', index);

      if ( new_tag === "" ) {
          //alert("please enter a tag!");
          bootbox.alert({
                  title: "Tag Builder Error!",
                  message: "Please enter a tag!",
                  backdrop: true
               });
      }
      else if ( tags_array[field_id].indexOf(new_tag) > -1 ) {
          //alert("must be a unique tag!");
          //addfield.val("");
           bootbox.alert({
                  title: "Tag Builder Error!",
                  message: "Tag must be a unique!",
                  backdrop: true
               });
      }
      else {
          tags_array[field_id].push(new_tag);

          tb_renderTag(field,container,new_tag,sort_tags);
          tb_addTagToHiddenField(field,tags_array[field_id]);
          addfield.val('');



          if ( tags_array[field_id].length ) {
             msgdiv.addClass('d-none');
             container.removeClass('d-none');
          }

          //if ( sort_tags == 1)
          //  sortable(container); // Refresh the Sortable Container

          // If autocomplete is enabled
          if ( autocomplete )
            addfield.parents('.typeahead__container ').removeClass('cancel');
      }

      //console.log('tags_array:', field_id, tags_array[field_id]);
   }
}

function tb_renderTag(field,container,tagText,sortTags) {
   tagText = typeof tagText !== 'undefined' ? tagText : 'New Tag';
   sortTags = typeof sortTags !== 'undefined' ? sortTags : 0; // Set to true of sortable option is set

   //console.log('tagText:', tagText);

   if ( tagText.length > 0  )
      tagText = tagText.toLowerCase();

   // console.log('tagText (LC): ', tagText);

   var fieldID = field.attr('id');
   var regex = /[^A-Za-z0-9]/g;
   var tagTextID = tagText.replace(regex, "-");
   var tagID = fieldID + '_' + tagTextID;
   var tagClass = '';
   var titleText = 'Tag: ' + tagText;

   if ( sortTags == 1 )
   {
      tagClass = ' dragTag';
      titleText = 'Drag to sort tag: ' + tagText;
   }

   var tagNode = $('<span></span>', {
      id: tagID,
      'class': 'tagBuilderTag badge rounded-pill bg-primary p-2 me-2 mb-1' + tagClass,
      title: titleText
   }).text(tagText);

   var removeIcon = $('<i></i>', {
      'class': 'removeTag fa-regular fa-circle-xmark ms-2',
      title: 'Click X to remove tag: ' + tagText
   });

   tagNode.append(removeIcon);
   container.append(tagNode);

   if ( sortTags == 1)
      sortable(container); // Refresh the Sortable Container
}

/*function tb_addTagItem(field,data) {

}*/

/*function tb_removeTagItem(field,data) {

}*/

function tb_addTagToHiddenField(field,data) {
   var fldValues = data.join(',');
//console.log('fldValues:', fldValues);

   field.val(fldValues).data('fieldvalue',fldValues);
}

function tb_removeTagFromHiddenField(field,data) {
   var fldValues = data.join(',');

   field.val(fldValues).data('fieldvalue',fldValues);
}


