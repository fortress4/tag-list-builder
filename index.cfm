<!---
   index.cfm
--->
<cfscript>
   controlsCFC = createObject("component","components.controls");
</cfscript>

<!DOCTYPE html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="description" content="">
    <meta name="author" content="">
    <link rel="icon" href="images/favicon.ico">

    <title>Bootstrap TagListBuilder</title>

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB" crossorigin="anonymous" referrerpolicy="no-referrer" />

    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.3.0/css/all.min.css" integrity="sha512-SzlrxWUlpfuzQ+pcUCosxcglQRNAq/DZjVsC0lE40xsADsfeQoEypE+enwcOiGjk/bSuGGKHEyjSoQ1zVisanQ==" crossorigin="anonymous" referrerpolicy="no-referrer" />

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/jquery-typeahead@2.11.1/dist/jquery.typeahead.min.css" integrity="sha256-v9xSYLU+r7kTI8gK714wGSObfWX0rrcWFZvPil8qZEw=" crossorigin="anonymous">

    <link rel="stylesheet" href="css/tag-list-builder.css">
    <link rel="stylesheet" href="css/tag-list-builder-typeahead.css">
  </head>

  <body>

    <div class="container">

      <div class="header clearfix">
        <nav>
          <!---<ul class="nav nav-pills float-right">
            <li class="nav-item">
              <a class="nav-link active" href="#">Home <span class="sr-only">(current)</span></a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#">About</a>
            </li>
            <li class="nav-item">
              <a class="nav-link" href="#">Contact</a>
            </li>
          </ul>--->
        </nav>
       <!--- <h3 class="text-muted">Project name</h3>--->
      </div>

      <div class="jumbotron">
         <h1 class="display-3">Bootstrap TagListBuilder</h1>
         <!---<h2 class="display-6">(TagListBuilder)</h2>--->
        <!---<p class="lead">Cras justo odio, dapibus ac facilisis in, egestas eget quam. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.</p>--->
        <!---<p><a class="btn btn-lg btn-success" href="#" role="button">Sign up today</a></p>--->
      </div>

      <!--- // ROW 1 --->
      <div class="row">
         <div class="col-lg-6">

            <div class="card border border-2 rounded-3 m-2 p-4">

               <div class="card-body">
                  <h5 class="card-title">Tag Sorting</h5>

                  <!--- Start: TagBuilder Field and Bin --->
                  <cfscript>
                     fieldArgs = {
                        fieldName="exampleOne",
                        fieldLabel = '',
                        required = false,
                        readonly = false,
                        placeholder = "Add a Tag",
                        fieldValue = "",
                           // autoComplete = false,
                        tagCase = "capitalize",
                        enableTagSorting = true,
                        //tagClass = 'bg-danger',
                        //tagHoverClass = 'bg-primary',
                           // validateTags = 'global',  // global/local/custom
                           // validateTagsSrc = 'resourceList',
                           // validateTagsFilter = '',
                        addFieldClass = '',
                        messageText = 'Add Tags',

                        showHiddenButton = true,
                        outputConfig = true   // TODO add to controls
                     };
                     //useLowerCaseTags = false,
                     //WriteDump(var=fieldArgs,expand=false);
                   </cfscript>
                   <cfoutput>#controlsCFC.renderTagListInputField(argumentCollection=fieldArgs)#</cfoutput>
                   <div id="exampleOne_events" class="mt-3 small tagBuilderEventIndicator" aria-live="polite">
                      <span class="text-muted">Last event:</span>
                      <span class="badge bg-secondary" data-event-name>Waiting</span>
                      <span class="ms-2 text-muted" data-event-count>0 events</span>
                      <code class="d-block mt-1 text-break" data-event-detail>No events fired yet.</code>
                   </div>
                  <!---<div class="tagBuilderWrapper">
                     <label class="tagBuilderFieldLabel"></label>
                     <input type="text" id="exampleOne_add" name="exampleOne_add" class="tagBuilderAdd form-control-sm " placeholder="Add a Tag">

                     <div id="exampleOne_msg" class="tagBuilderMsg">Add Tags</div>
                     <div id="exampleOne_bin" class="tagBuilderBin d-none"></div>
                     <input type="hidden" id="exampleOne" name="exampleOne" class="tagBuilder" value=""
                        data-fieldvalue=""
                        data-required="0"
                        data-readonly="0"
                        data-autocomplete="0"
                        data-tagcase="capitalize"
                        data-tagsorting="1"
                        data-validatetags="global">
                  </div>--->
                  <!--- End: TagBuilder Field and Bin --->
               </div>
            </div>

         </div>
         <div class="col-lg-6">

            <div class="card border border-2 rounded-3 m-2 p-4">

                  <h5 class="card-title">No Tag Sorting</h5>
                  <!--- Start: TagBuilder Field and Bin --->
                  <cfscript>
                     fieldArgs = {
                        fieldName="exampleTwo",
                        fieldLabel = '',
                        required = false,
                        readonly = false,
                        placeholder = "Add a Tag",
                        fieldValue = "",
                           // autoComplete = false,
                        enableTagSorting = false,
                        tagCase = "",
                        tagClass = 'bg-primary',
                        tagHoverClass = 'bg-danger',
                           // validateTags = 'global',  // global/local/custom
                           // validateTagsSrc = 'resourceList',
                           // validateTagsFilter = '',
                        addFieldClass = '',
                        messageText = 'Add Tags',

                        showHiddenButton = true,
                        outputConfig = true   // TODO add to controls
                     };
                     //useLowerCaseTags = false,
                     //WriteDump(var=fieldArgs,expand=false);
                   </cfscript>
                   <cfoutput>#controlsCFC.renderTagListInputField(argumentCollection=fieldArgs)#</cfoutput>
                   <div id="exampleTwo_events" class="mt-3 small tagBuilderEventIndicator" aria-live="polite">
                      <span class="text-muted">Last event:</span>
                      <span class="badge bg-secondary" data-event-name>Waiting</span>
                      <span class="ms-2 text-muted" data-event-count>0 events</span>
                      <code class="d-block mt-1 text-break" data-event-detail>No events fired yet.</code>
                   </div>
                  <!---<div class="tagBuilderWrapper">
                     <label class="tagBuilderFieldLabel"></label>
                     <input type="text" id="exampleTwo_add" name="exampleTwo_add" class="tagBuilderAdd form-control-sm " placeholder="Add a Tag">

                     <div id="exampleTwo_msg" class="tagBuilderMsg">Add Tags</div>
                     <div id="exampleTwo_bin" class="tagBuilderBin d-none"></div>
                     <input type="hidden" id="exampleTwo" name="exampleTwo" class="tagBuilder" value=""
                        data-fieldvalue=""
                        data-required="0"
                        data-readonly="0"
                        data-autocomplete="0"
                        data-tagcase="lowercase"
                        data-tagsorting="0"
                        data-validatetags="global">
                  </div>--->
                  <!--- End: TagBuilder Field and Bin --->
            </div>

         </div>
      </div>

      <!--- // ROW 2 --->
      <div class="row">
         <div class="col-lg-6">

            <div class="card border border-2 rounded-3 m-2 p-4">

               <div class="card-body">
                  <h5 class="card-title">Typeahead with Tag Sorting</h5>

                  <!--- Start: TagBuilder Field and Bin --->
                  <cfscript>
                     fieldArgs = {
                        fieldName="exampleThree",
                        fieldLabel = '',
                        required = false,
                        readonly = false,
                        placeholder = "Add a Tag",
                        fieldValue = "",
                        enableTagSorting = true,
                        tagCase = "upper",
                        tagClass = 'bg-info',
                        tagHoverClass = 'bg-danger',
                           // validateTags = 'global',  // global/local/custom
                           // validateTagsSrc = 'resourceList',
                           // validateTagsFilter = '',
                        addFieldClass = '',
                        messageText = 'Add Tags',

                        showHiddenButton = true,
                        outputConfig = true   // TODO add to controls
                     };
                     //useLowerCaseTags = false,
                     //WriteDump(var=fieldArgs,expand=false);
                   </cfscript>
                   <cfoutput>#controlsCFC.renderTagListTypeAheadInputField(argumentCollection=fieldArgs)#</cfoutput>
                   <div id="exampleThree_events" class="mt-3 small tagBuilderEventIndicator" aria-live="polite">
                      <span class="text-muted">Last event:</span>
                      <span class="badge bg-secondary" data-event-name>Waiting</span>
                      <span class="ms-2 text-muted" data-event-count>0 events</span>
                      <code class="d-block mt-1 text-break" data-event-detail>No events fired yet.</code>
                   </div>
                  <!--- End: TagBuilder Field and Bin --->

               </div>
            </div>

         </div>
         <div class="col-lg-6">

            <div class="card border border-2 rounded-3 m-2 p-4">

                  <h5 class="card-title">Typeahead with No Tag Sorting</h5>

                  <!--- Start: TagBuilder Field and Bin --->
                  <cfscript>
                     fieldArgs = {
                        fieldName="exampleFour",
                        fieldLabel = '',
                        required = false,
                        readonly = false,
                        placeholder = "Add a Tag",
                        fieldValue = "",
                        enableTagSorting = false,
                        tagCase = "lower",
                        tagClass = 'bg-success',
                        tagHoverClass = 'bg-warning',
                           // validateTags = 'global',  // global/local/custom
                           // validateTagsSrc = 'resourceList',
                           // validateTagsFilter = '',
                        addFieldClass = '',
                        messageText = 'Add Tags',

                        showHiddenButton = true,
                        outputConfig = true   // TODO add to controls
                     };
                   </cfscript>
                   <cfoutput>#controlsCFC.renderTagListTypeAheadInputField(argumentCollection=fieldArgs)#</cfoutput>
                   <div id="exampleFour_events" class="mt-3 small tagBuilderEventIndicator" aria-live="polite">
                      <span class="text-muted">Last event:</span>
                      <span class="badge bg-secondary" data-event-name>Waiting</span>
                      <span class="ms-2 text-muted" data-event-count>0 events</span>
                      <code class="d-block mt-1 text-break" data-event-detail>No events fired yet.</code>
                   </div>
                   <!--- End: TagBuilder Field and Bin --->

            </div>
         </div>
      </div>

      <!--- // ROW 3 --->
       <div class="row">
          <div class="col-12">
             <div class="card border border-2 rounded-3 m-2 p-4">
                <div class="card-body">
                   <h5 class="card-title">JavaScript-loaded Values and Events</h5>
                   <p class="card-text text-muted">
                      This field starts empty. Its initial tags are added with <code>tagBuilder('set', values)</code>
                      after initialization, and the indicator shows each public event as it fires.
                   </p>

                   <cfscript>
                      fieldArgs = {
                         fieldName = "exampleFive",
                         fieldLabel = "JavaScript API Example",
                         required = false,
                         readonly = false,
                         placeholder = "Add a Tag",
                         fieldValue = "",
                         enableTagSorting = true,
                         tagCase = "",
                         tagClass = "bg-dark",
                         tagHoverClass = "bg-warning",
                         addFieldClass = "",
                         messageText = "Values will be loaded by JavaScript",
                         showHiddenButton = true,
                         outputConfig = true
                      };
                   </cfscript>
                   <cfoutput>#controlsCFC.renderTagListInputField(argumentCollection=fieldArgs)#</cfoutput>

                   <div id="exampleFive_events" class="mt-3 small tagBuilderEventIndicator" aria-live="polite">
                      <span class="text-muted">Last event:</span>
                      <span class="badge bg-secondary" data-event-name>Waiting</span>
                      <span class="ms-2 text-muted" data-event-count>0 events</span>
                      <code class="d-block mt-1 text-break" data-event-detail>No events fired yet.</code>
                   </div>

                   <div class="d-flex flex-wrap gap-2 mt-3" aria-label="JavaScript tag builder examples">
                      <button type="button" class="btn btn-primary btn-sm" data-example-five-action="set">Set example values</button>
                      <button type="button" class="btn btn-success btn-sm" data-example-five-action="add">Add a value</button>
                      <button type="button" class="btn btn-outline-primary btn-sm" data-example-five-action="refresh">Refresh saved values</button>
                      <button type="button" class="btn btn-outline-danger btn-sm" data-example-five-action="clear">Clear values</button>
                   </div>
                </div>
             </div>
          </div>
      </div>

      <!---<div class="row marketing">
        <div class="col-lg-6">
          <h4>Subheading</h4>
          <p>Donec id elit non mi porta gravida at eget metus. Maecenas faucibus mollis interdum.</p>

          <h4>Subheading</h4>
          <p>Morbi leo risus, porta ac consectetur ac, vestibulum at eros. Cras mattis consectetur purus sit amet fermentum.</p>

          <h4>Subheading</h4>
          <p>Maecenas sed diam eget risus varius blandit sit amet non magna.</p>
        </div>

        <div class="col-lg-6">
          <h4>Subheading</h4>
          <p>Donec id elit non mi porta gravida at eget metus. Maecenas faucibus mollis interdum.</p>

          <h4>Subheading</h4>
          <p>Morbi leo risus, porta ac consectetur ac, vestibulum at eros. Cras mattis consectetur purus sit amet fermentum.</p>

          <h4>Subheading</h4>
          <p>Maecenas sed diam eget risus varius blandit sit amet non magna.</p>
        </div>
      </div>--->

      <footer class="footer">
         <cfoutput><p>&copy; #Year(Now())# Bootstrap TagListBuilder</p></cfoutput>
      </footer>

    </div> <!-- /container -->

    <script src="https://code.jquery.com/jquery-4.0.0.min.js" integrity="sha384-fgGyf7Mo7DURSOMnOy7ed+dkq5Job205Gnzu6QIg0BOHKaqt4D76Dt8VlDCzcMHV" crossorigin="anonymous" referrerpolicy="no-referrer"></script>

    <script>
      (function() {
         var eventNames = ['init', 'update', 'add', 'remove', 'sort', 'reject', 'error'];
         var eventCounts = Object.create(null);
         var eventBadgeClasses = {
            init: 'bg-info text-dark',
            update: 'bg-primary',
            add: 'bg-success',
            remove: 'bg-warning text-dark',
            sort: 'bg-info text-dark',
            reject: 'bg-danger',
            error: 'bg-danger'
         };

         document.querySelectorAll('.tagBuilderEventIndicator').forEach(function(indicator) {
            var fieldId = indicator.id.replace(/_events$/, '');
            var field = document.getElementById(fieldId);
            var config = document.getElementById(fieldId + '_config');

            if (config) {
               config.insertAdjacentElement('beforebegin', indicator);
            }
            else if (field && field.parentElement) {
               field.parentElement.insertAdjacentElement('afterend', indicator);
            }
         });

         function showTagBuilderEvent(event) {
            var fieldId = event.target && event.target.id;
            var indicator = fieldId ? document.getElementById(fieldId + '_events') : null;

            if (!indicator) {
               return;
            }

            var eventName = event.type.replace('tagBuilder:', '');
            eventCounts[fieldId] = (eventCounts[fieldId] || 0) + 1;
            indicator.querySelector('[data-event-name]').textContent = event.type;
            indicator.querySelector('[data-event-name]').className = 'badge ' + eventBadgeClasses[eventName];
            indicator.querySelector('[data-event-detail]').textContent = JSON.stringify(event.detail);

            var history = indicator.querySelector('[data-event-history]');
            if (!history) {
               history = document.createElement('div');
               history.className = 'd-flex flex-wrap gap-1 mt-2';
               history.setAttribute('data-event-history', '');
               history.setAttribute('aria-label', 'Recent tag builder events');
               indicator.querySelector('[data-event-detail]').insertAdjacentElement('beforebegin', history);
            }

            var historyItem = document.createElement('span');
            historyItem.className = 'badge ' + eventBadgeClasses[eventName];
            historyItem.textContent = eventName === 'update' && event.detail.reason
               ? eventName + ':' + event.detail.reason
               : eventName;
            history.appendChild(historyItem);

            while (history.children.length > 8) {
               history.removeChild(history.firstElementChild);
            }

            var count = indicator.querySelector('[data-event-count]');
            if (count) {
               count.textContent = eventCounts[fieldId] + (eventCounts[fieldId] === 1 ? ' event' : ' events');
            }
         }

         eventNames.forEach(function(name) {
            document.addEventListener('tagBuilder:' + name, showTagBuilderEvent);
         });
      }());
    </script>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js" integrity="sha384-FKyoEForCGlyvwx9Hj09JcYn3nv7wiPVlz7YYwJrWVcXK/BmnVDxM+D2scQbITxI" crossorigin="anonymous" referrerpolicy="no-referrer"></script>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/html5sortable/0.14.0/html5sortable.min.js" integrity="sha384-cZfTSiLzVQDaBN1hjURm6ODfx0fOTGTXsYmUXLq97heMPd6gsXI/NlPgIUg4mj07" crossorigin="anonymous" referrerpolicy="no-referrer"></script>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootbox.js/6.0.4/bootbox.min.js" integrity="sha384-sEKDF42n+J1rv9zPsx1WjN0wH4m6lBxfyXa74WJls1fYFLeqsFc+SwNktG6hiv78" crossorigin="anonymous" referrerpolicy="no-referrer"></script>

    <script src="https://cdn.jsdelivr.net/npm/jquery-typeahead@2.11.1/dist/jquery.typeahead.min.js" integrity="sha256-HQvzpKdugcSoVwponjVtzqQ+dpijVZYbuvodUpcGAIs=" crossorigin="anonymous"></script>

    <script src="js/tag-list-builder.js"></script>
    <script src="js/tag-list-builder-typeahead.js"></script>
    <script>
      $(function() {
         window.setTimeout(function() {
            $('#exampleFive').tagBuilder('set', ['Loaded by JavaScript', 'Event hooks', 'Version 0.3.0']);
         }, 0);

         $('[data-example-five-action]').on('click', function() {
            var field = $('#exampleFive');
            var action = $(this).attr('data-example-five-action');

            if (action === 'set') {
               field.tagBuilder('set', ['Loaded by JavaScript', 'Saved values', 'Rendered tags']);
            }
            else if (action === 'add') {
               field.tagBuilder('add', 'Added at ' + new Date().toLocaleTimeString());
            }
            else if (action === 'refresh') {
               field.attr('data-fieldvalue', JSON.stringify(['Refreshed value', 'From data-fieldvalue']));
               field.tagBuilder('refresh');
            }
            else if (action === 'clear') {
               field.tagBuilder('clear');
            }
         });
      });
    </script>
</body>
</html>
