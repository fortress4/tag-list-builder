# Future Enhancements

This file records possible improvements that are intentionally outside the active remediation plan.

## Add a Vanilla JavaScript Build and Demo

### Goal

Provide a dependency-light implementation of the tag-list builder that does not require jQuery, Bootbox, or jquery-typeahead. Keep the existing jQuery implementation available for current consumers rather than replacing it in a breaking change.

Suggested artifacts:

- `js/tag-list-builder-vanilla.js` as the canonical source;
- `dist/js/tag-builder-vanilla.js` as the synchronized distribution file;
- `index-vanilla.html` as a standalone demo covering the same four primary variants;
- dedicated vanilla browser-smoke coverage under `tests/`.

### Required behavior parity

The vanilla implementation should preserve the established public contract:

- JSON arrays as the default saved-value format;
- temporary legacy comma-value reads followed by JSON rewrites;
- deprecated explicit `valueFormat="comma"` support;
- `normalizeStoredCase=false` by default;
- normalized duplicate checking with independently preserved stored casing;
- safe text-only tag rendering with no HTML interpretation;
- add, remove, readonly, maximum length, maximum count, and show-raw behavior;
- preloaded values and deterministic hidden-field updates;
- sortable tag order when the sorting dependency is enabled;
- the existing `data-*` configuration attributes and ColdFusion-generated markup where practical.

### Dependency replacements

- Use native DOM APIs, event delegation, `classList`, `dataset`/`getAttribute`, and `JSON` methods instead of jQuery.
- Replace Bootbox validation alerts with an accessible native validation-message component or a small project-owned dialog implementation.
- Replace jquery-typeahead with a native or maintained framework-independent autocomplete implementation. A basic `<datalist>` may be considered only if its accessibility, styling, remote-data, and selection behavior meet project requirements.
- Keep Bootstrap as an optional presentation dependency; the core tag behavior should not depend on Bootstrap JavaScript.
- Reuse HTML5 Sortable initially because it has no jQuery dependency, subject to the separate sorting-library reevaluation below.

### Design constraints

- Do not maintain two unrelated behavior specifications. Extract or clearly mirror normalization, validation, migration, and serialization rules, with shared fixture data where feasible.
- Avoid global mutable state where possible. Prefer one instance per tag-builder element and expose a small documented initialization API.
- Support multiple arbitrary field IDs and dynamically initialized controls.
- Emit documented custom events for add, remove, reorder, validation failure, and value change if consumers need integration hooks.
- Remain compatible with a strict Content Security Policy: no inline event handlers, evaluated code, or HTML-string rendering of untrusted values.
- Keep the vanilla and jQuery demos visually comparable so behavior differences are easy to detect.

### Acceptance criteria

- The vanilla demo passes the same security payload, JSON migration, casing, duplicate, readonly, limit, removal, and sorting tests as the jQuery demo.
- It runs without jQuery, jquery-typeahead, Bootbox, or jQuery Migrate present.
- The ColdFusion helper can render markup usable by either implementation without weakening output encoding.
- Source and `dist/` parity is enforced by `build.ps1 -Check`.
- Current Chromium and Firefox are tested, including keyboard-only operation and basic mobile/touch behavior.
- Documentation explains how to choose between the legacy jQuery build and the vanilla build without loading both on the same control.

## Add Bloodhound/Typeahead Compatibility

Evaluate optional compatibility with the Bloodhound suggestion engine and the typeahead.js UI ecosystem. This should be an adapter or integration layer, not a mandatory dependency of the core tag builder.

The evaluation should cover:

- compatibility of the maintained Bloodhound/typeahead.js release or fork with jQuery 4;
- whether Bloodhound can serve as a data engine for the future vanilla autocomplete without requiring the jQuery typeahead UI;
- local datasets, `prefetch`, remote queries, request caching, rate limiting, and asynchronous result handling;
- configurable datum display and stored-value fields instead of assuming suggestions are plain strings;
- adding a selected suggestion through the same normalization, duplicate, length, count, and serialization path used for manually entered tags;
- multiple independent tag builders and arbitrary field IDs on one page;
- keyboard navigation, screen-reader behavior, focus management, loading state, empty results, and request failures;
- safe suggestion rendering with text nodes or explicitly sanitized templates;
- cancellation or suppression of stale remote responses;
- CSP compatibility and the ability to self-host all required assets;
- a dedicated demo variant and browser-smoke fixtures for local, prefetched, and remote suggestions.

Bloodhound suggestions must remain a usability feature, not an authorization boundary. Applications must continue validating submitted tag values on the server even when the UI requires selection from suggestions.

If the original typeahead.js project is not sufficiently maintained or cannot run cleanly with jQuery 4, compare maintained forks and framework-independent alternatives before adopting a compatibility shim. Do not add jQuery Migrate as a permanent production dependency.

## Reevaluate the Sorting Library

### Background

The project currently uses HTML5 Sortable. The active remediation plan targets version 0.14.0, which preserves the APIs used by the tag-list builder and has no jQuery dependency.

The upstream project describes itself as community-maintained and not actively developed. That does not require an immediate replacement, but it increases the long-term risk of browser regressions, unresolved accessibility limitations, and delayed security or compatibility fixes.

### Future evaluation

Periodically review whether HTML5 Sortable still meets the project’s requirements. If replacement becomes appropriate, compare actively maintained, framework-independent libraries such as SortableJS against the existing behavior.

Evaluation criteria:

- active maintenance and documented browser support;
- no jQuery dependency;
- keyboard and assistive-technology accessibility;
- touch and mobile support;
- horizontal tag sorting;
- stable reorder events with the complete resulting item order;
- ability to disable sorting for readonly controls;
- CSP compatibility;
- small production footprint and no unnecessary dependencies;
- straightforward CDN and self-hosted distribution options;
- license compatibility.

### Migration constraints

Any replacement must preserve:

- the existing `.tagBuilderBin` markup contract where practical;
- tag order in the JSON hidden-field value;
- add/remove/sort interaction across all four demo variants;
- source and `dist/` parity;
- current Bootstrap presentation;
- graceful behavior when sorting is disabled.

Treat a sorting-library replacement as an isolated compatibility change with its own browser, touch, keyboard, readonly, JSON-order, and CSP regression testing. Do not combine it with urgent security fixes.
