/* tag-list-builder-typeahead.js */
$(function() {
   $('.tagBuilderAdd.typeahead').each(function() {
      var input = $(this);

      if (input.prop('disabled')) {
         return;
      }

      input.typeahead({
         minLength: 1,
         order: 'asc',
         maxItem: 20,
         dynamic: true,
         offset: false,
         hint: false,
         source: {
            alias: {
               ajax: {
                  type: 'GET',
                  url: 'data/libs.json',
                  dataType: 'json'
               }
            }
         },
         debug: false
      });
   });
});
