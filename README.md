# Bootstrap TagListBuilder

Current component release: `v0.3.1` (also recorded in `version.json` and `package.json`).

The package metadata declares the browser libraries as peer dependencies. jQuery and Bootstrap are required by the supported implementation and presentation; Bootbox, HTML5 Sortable, and jQuery Typeahead are optional peers used only by the corresponding alert, sorting, and typeahead features. The demos load these dependencies from pinned CDNs instead of installing them from npm.

Inspired by [thebigtank's](https://github.com/thebigtank) ["tags builder with jquery"](https://github.com/thebigtank/tags-builder-with-jquery) tutorial.

Dependencies:

1. [Bootstrap 5.x](https://getbootstrap.com/) (tested with 5.3.8)
2. [jQuery 4.x](https://jquery.com/) (tested with 4.0.0)
3. [Font Awesome 6.x](https://fontawesome.com/) (tested with 6.3.0)
4. [HTML5 Sortable 0.14.x](https://lukasoppermann.github.io/html5sortable/) (tested with 0.14.0)
5. [BootboxJS 6.x](https://bootboxjs.com/) (tested with 6.0.4)
6. [jQuery Typeahead Search](http://www.runningcoder.org/jquerytypeahead/) (tested with 2.11.1) **

** jQuery Typeahead Search is only required when using the typeahead option.

ColdFusion/CFML is not required to use the tag-list builder. The component runs in a normal HTML page using the browser dependencies listed above; `index.html` is the standalone example. Copy the required CSS and JavaScript assets and use the same HTML/data-attribute contract in any server-side framework or static site.

View the [Demo](https://fortress4.github.io/tag-list-builder/) page.

Warning: This is a work in progress.

## Saved values

Tag values are stored as a JSON array by default, which safely supports commas inside a tag:

```json
["Washington, DC", "Indianapolis"]
```

JSON mode accepts an existing legacy comma-separated value once and immediately rewrites it as JSON. The deprecated `valueFormat="comma"` option remains available for server-side consumers that still require comma-separated output; tags containing commas are rejected in that mode.

Case normalization is always applied before duplicate checking. `normalizeStoredCase` defaults to `false`, so entered casing is preserved in the saved value. Set it to `true` to save the normalized casing shown by `tagCase`.

## Loading saved values

Server-rendered forms can provide saved values through the hidden field's `value` and `data-fieldvalue` attributes. JSON is the default format:

```html
<input type="hidden" id="aliases" name="aliases" class="tagBuilder"
   value='["one","two"]' data-fieldvalue='["one","two"]'
   data-valueformat="json">
```

The CFML helpers accept a JSON string, legacy comma-delimited string, or array through `fieldValue`:

```cfml
<cfset controls.renderTagListInputField(
   fieldName="aliases",
   fieldValue=["one", "two"]
)>
```

To submit stable IDs while displaying human-readable labels, pass value/label items. This form submits `["lib-101","lib-202"]` while rendering the labels:

```cfml
<cfset controls.renderTagListInputField(
   fieldName="libraries",
   fieldValue=[
      { value="lib-101", label="Bootstrap" },
      { value="lib-202", label="jQuery" }
   ]
)>
```

Value/label items require JSON storage. Case normalization applies to `label` only; `value` is preserved as the submitted identifier.

## JavaScript Methods API

Call `tagBuilder()` on the stored `.tagBuilder` input after ready-time initialization. Read methods return data from the first selected field; mutation methods return the jQuery collection and can be chained.

| Method | Argument | Returns | Behavior |
| --- | --- | --- | --- |
| `tagBuilder('get')` | None | `string[]` | Returns a copy of the saved values in display order. |
| `tagBuilder('getItems')` | None | `{ value, label }[]` | Returns copies of the stored IDs and rendered labels in display order. |
| `tagBuilder('set', values)` | Array of strings or items | jQuery collection | Atomically replaces all tags and emits an update with reason `set`. |
| `tagBuilder('add', value)` | String or item | jQuery collection | Validates and adds one tag, then emits `add` and `update`. |
| `tagBuilder('remove', value)` | Stored value string | jQuery collection | Removes the tag with the matching ID/value, then emits `remove` and `update`. |
| `tagBuilder('clear')` | None | jQuery collection | Removes all tags and emits an update with reason `clear`. |
| `tagBuilder('refresh')` | None | jQuery collection | Rereads `data-fieldvalue`, rerenders, and emits an update with reason `refresh`. |
| `tagBuilder('config')` | None | Object | Returns a copy of the resolved field configuration. |

Examples:

```js
var values = $('#aliases').tagBuilder('get');
var items = $('#aliases').tagBuilder('getItems');

$('#aliases')
   .tagBuilder('set', ['one', 'two'])
   .tagBuilder('add', 'three')
   .tagBuilder('remove', 'one');

$('#aliases').attr('data-fieldvalue', '["saved","values"]');
$('#aliases').tagBuilder('refresh');

$('#libraries').tagBuilder('set', [
   { value: 'lib-101', label: 'Bootstrap' },
   { value: 'lib-202', label: 'jQuery' }
]);

$('#libraries').tagBuilder('add', {
   value: 'lib-303',
   label: 'HTML5 Sortable'
});
```

A custom autocomplete can pass its selected record directly to the item API:

```js
function selectLibrary(result) {
   $('#libraries').tagBuilder('add', {
      value: String(result.id),
      label: result.name
   });
}
```

Mutations use the same case normalization, limits, duplicate checks, rendering, and serialization as keyboard input. For value/label items, identity and duplicate checking use `value`, while the tag area renders `label`. The hidden input and `get()` contain only stored values; `getItems()` returns both properties. Label metadata remains in `data-fieldvalue` so `refresh` can rerender it.

`set` is atomic: if any supplied value is invalid or duplicated, the existing list is retained and a `tagBuilder:reject` event is emitted. Passing an unsupported argument shape throws a `TypeError`.

The `readonly` option disables user-driven add, remove, and sort behavior. It is not an authorization boundary and does not block deliberate calls to the JavaScript methods API.

## Events API

The builder dispatches native, bubbling `CustomEvent`s on the stored `.tagBuilder` input. Each payload is available through `event.detail` and contains plain strings or copied arrays rather than internal tag objects.

| Event | Fired when | `event.detail` |
| --- | --- | --- |
| `tagBuilder:init` | Initialization succeeds | `{ fieldId, values, items, migrated }` |
| `tagBuilder:update` | The stored value changes | `{ fieldId, values, items, previous, previousItems, reason, serialized }` |
| `tagBuilder:add` | One tag is accepted | `{ fieldId, value, item, values, items }` |
| `tagBuilder:remove` | One tag is removed | `{ fieldId, value, item, values, items }` |
| `tagBuilder:sort` | Tags are reordered | `{ fieldId, values, items, previous, previousItems }` |
| `tagBuilder:reject` | Input is refused | `{ fieldId, value, item, reason, message }` |
| `tagBuilder:error` | Initialization or refresh parsing fails | `{ fieldId, message }` |

### Event reasons

`tagBuilder:update` uses these `reason` values:

- `init`: initial rendering, including legacy-value migration
- `add`: one value was added
- `remove`: one value was removed
- `sort`: displayed values were reordered
- `set`: values were replaced through the methods API
- `clear`: values were cleared through the methods API
- `refresh`: `data-fieldvalue` was reread through the methods API

`tagBuilder:reject` uses `empty`, `controlCharacters`, `maxTagLength`, `comma`, `maxTags`, `duplicate`, or `itemFormat`. Its `message` property contains the corresponding human-readable validation message.

### Event ordering and initialization

Specific events are dispatched before the general update event:

```text
tagBuilder:add    -> tagBuilder:update (reason: add)
tagBuilder:remove -> tagBuilder:update (reason: remove)
tagBuilder:sort   -> tagBuilder:update (reason: sort)
tagBuilder:init   -> tagBuilder:update (reason: init)
```

Initialization events are deferred until the current ready callback completes. A listener registered in a later `$(function () {})` callback can therefore receive `tagBuilder:init` and its corresponding update.

### Listening with JavaScript

```js
document.getElementById('aliases').addEventListener('tagBuilder:update', function (event) {
   validateAliases(event.detail.values);
});
```

### Listening with jQuery

jQuery 4 exposes the native payload as `event.detail`. The `originalEvent` fallback supports jQuery versions that wrap it differently:

```js
$('#aliases').on('tagBuilder:update', function (event) {
   var data = event.detail || (event.originalEvent && event.originalEvent.detail);
   validateAliases(data.values);
});
```

A host can listen for both successful changes and rejected input:

```js
$('#aliases').on('tagBuilder:update', function (event) {
   var data = event.detail || event.originalEvent.detail;
   validateAliasesOnServer(data.values);
}).on('tagBuilder:reject', function (event) {
   var data = event.detail || event.originalEvent.detail;
   $('#aliasError').text(data.message);
});
```

Methods and events are integration surfaces, not authorization controls. Applications must still validate values, limits, and permissions on the server.

## CFML Development Tools

CFML is used only to develop the example layout. `index.cfm` uses `components/controls.cfc` to render the demo controls, while `index.html` provides the standalone HTML version.

These tools are optional and are not a runtime dependency of the JavaScript tag-list builder. If you use or modify the CFML development tools, they require Adobe ColdFusion 10+ or Lucee 5+ with ESAPI/ESAPI Encoder support because the helpers use `EncodeForHTML` and `EncodeForHTMLAttribute`.

## Options

- Autocomplete/typeahead
  - Requires the typeahead markup wrapper and jQuery Typeahead Search library.
  - The sample data request is configured in `js/tag-list-builder-typeahead.js`.
- `tagCase`: `lower`, `upper`, `capitalize`, or blank.
- `normalizeStoredCase`: save normalized casing when true; defaults to false.
- `valueFormat`: `json` by default; deprecated `comma` output is supported.
- `maxTagLength`: maximum characters per tag; defaults to 100.
- `maxTags`: maximum number of tags; defaults to 100.
- `readonly`: disables add, remove, and sort UI behavior. It is not an authorization control.
- `validateTags`: deprecated/reserved and does not enforce validation.

Hidden fields and `data-*` attributes are controlled by the browser. Applications must parse the selected format defensively and enforce authorization, allowed values, length, count, and uniqueness again on the server. Typeahead results are suggestions, not a trusted allowlist.

## Tests

See `tests/README.md` for the browser smoke test. It covers jQuery 4 initialization, typeahead initialization, safe text rendering, JSON migration, comma output, and readonly behavior.

Run `./build.ps1` to copy canonical source assets into `dist/`, or `./build.ps1 -Check` to fail when distribution files are out of date.



