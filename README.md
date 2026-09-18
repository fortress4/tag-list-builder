# Bootstrap TagListBuilder

Inspired by [thebigtank's](https://github.com/thebigtank) ["tags builder with jquery"](https://github.com/thebigtank/tags-builder-with-jquery) tutorial.

Dependencies:

1. [Bootstrap 5.x](https://getbootstrap.com/) (tested with 5.3.8)
2. [jQuery 4.x](https://jquery.com/) (tested with 4.0.0)
3. [Font Awesome 6.x](https://fontawesome.com/) (tested with 6.3.0)
4. [HTML5 Sortable 0.14.x](https://lukasoppermann.github.io/html5sortable/) (tested with 0.14.0)
5. [BootboxJS 6.x](https://bootboxjs.com/) (tested with 6.0.4)
6. [jQuery Typeahead Search](http://www.runningcoder.org/jquerytypeahead/) (tested with 2.11.1) **

** jQuery Typeahead Search is only required when using the typeahead option.

View the [Demo](https://fortress4.github.io/tag-list-builder/) page.

Warning: This is a work in progress.

## Saved values

Tag values are stored as a JSON array by default, which safely supports commas inside a tag:

```json
["Washington, DC", "Indianapolis"]
```

JSON mode accepts an existing legacy comma-separated value once and immediately rewrites it as JSON. The deprecated `valueFormat="comma"` option remains available for server-side consumers that still require comma-separated output; tags containing commas are rejected in that mode.

Case normalization is always applied before duplicate checking. `normalizeStoredCase` defaults to `false`, so entered casing is preserved in the saved value. Set it to `true` to save the normalized casing shown by `tagCase`.

## ColdFusion requirements

The reusable helpers use `EncodeForHTML` and `EncodeForHTMLAttribute`. Supported runtimes are Adobe ColdFusion 10+ and Lucee 5+ with its ESAPI/ESAPI Encoder support available.

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



