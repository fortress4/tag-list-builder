# Bootstrap TagListBuilder

Current component release: `v0.2.0` (also recorded in `version.json` and `package.json`).

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



