# Security Remediation Plan

Date: 2026-09-17

Source audit: `_notes/audits/security-audit-2026-09-17.md`

Status: core remediation implemented on 2026-09-17; deployment-specific CSP rollout remains an integration task.

## Goal

Resolve the production-library findings from the 2026-09-17 security audit, migrate saved tag values from comma-delimited text to JSON arrays, and preserve the behavior of the four demo variants.

## Scope

Primary implementation files:

- `components/controls.cfc`
- `js/tag-list-builder.js`
- `js/tag-list-builder-typeahead.js`
- `dist/js/tag-builder.js`
- `dist/js/tag-builder-typeahead.js`
- `index.cfm`
- `index.html`
- `README.md`

Styles may be updated if validation messages or CSP-compatible placeholder styling require them:

- `css/tag-list-builder.css`
- `dist/css/tag-builder.css`

## Non-Goals

- treating typeahead suggestions as an authorization or validation boundary;
- adding application-specific server persistence or authorization logic to this UI library;
- completing the separate Vanilla JavaScript implementation plan;
- upgrading every dependency in the same change as the critical output-encoding fix.

## Decisions

### Use JSON by default and retain deprecated comma-list support

The hidden field and `data-fieldvalue` contract will use a JSON array of strings:

```json
["staff", "admin"]
```

An empty JSON tag collection will be represented as `[]`. Commas are valid inside an individual JSON-mode tag because JSON preserves tag boundaries unambiguously.

Add an explicit storage-format option:

- CFC argument: `valueFormat`;
- markup attribute: `data-valueformat`;
- allowed values: `json` and `comma`;
- default: `json`;
- `comma` is deprecated but remains supported for existing consumers.

In JSON mode, the browser initializer may read a clearly legacy comma-delimited preloaded value during migration, but every subsequent write uses JSON. In comma mode, the component continues to read and write comma-delimited values and must reject commas within individual tags. Newly generated demos use JSON mode.

### Separate comparison, display, and stored values

Case normalization will always occur before duplicate checking and display. Storage casing will be configurable because consumers may need to preserve the value as entered.

Add a boolean CFC option and data attribute:

- CFC argument: `normalizeStoredCase`;
- markup attribute: `data-normalizestoredcase`;
- default: `false`, preserving the trimmed casing supplied by the user;
- when `false`, JSON preserves the trimmed casing supplied by the user while duplicate comparison still uses the normalized comparison key.

Each tag therefore has three explicit representations:

- `value`: the string serialized into the JSON array;
- `key`: the normalized string used for duplicate comparison;
- `label`: the normalized string displayed in the tag pill.

When `normalizeStoredCase=true`, `value`, `key`, and `label` are normally identical. With the default `false`, `value` preserves entered casing while `key` and `label` follow `tagCase`. This behavior applies to both JSON and deprecated comma storage formats.

### Define `readonly` as a UI state, not authorization

When `readonly` is enabled, the control will not allow adding, removing, or sorting tags. This is a usability contract only. Documentation will state that applications must still enforce authorization on submitted values server-side.

### Deprecate the misleading validation option

`validateTags` currently has no validation source or server contract. It will remain accepted temporarily for backwards compatibility, but its CFC hint and documentation will explicitly mark it as reserved/deprecated and non-enforcing. It must not be presented as a security control.

### Keep source and distribution artifacts synchronized

Files under `js/` remain canonical. Matching `dist/js/` files will be regenerated or copied from the source implementation during the same change and compared before completion.

## Phase 1: Context-Safe ColdFusion Rendering

Priority: immediate.

### Runtime compatibility baseline

Use the context-specific encoding functions directly:

- Adobe ColdFusion: `EncodeForHTML()` and `EncodeForHTMLAttribute()` were introduced in ColdFusion 10, making ColdFusion 10 the technical API minimum;
- Lucee: target Lucee 5.0 or newer and require the Guard/ESAPI extension that supplies the documented context-specific encoding functions.

Production deployments should run a currently supported and fully patched engine even though the functions exist in older releases.

At component initialization or in a focused compatibility check, verify that both encoding functions exist and fail with a clear configuration error if they do not. Do not silently fall back to `HTMLEditFormat()`: it is not attribute-context-specific, Adobe recommends `EncodeForHTML()` for new code, and `HTMLEditFormat()` is removed in Adobe ColdFusion 2025.

### 1. Add local encoded values in `components/controls.cfc`

For each rendering function, calculate encoded local variables before emitting markup:

- use `EncodeForHTML()` for visible text such as `fieldLabel`, `messageText`, and configuration output;
- use `EncodeForHTMLAttribute()` for IDs, names, placeholders, classes, `data-*` values, and button IDs;
- encode only at the final output boundary so the original argument values remain available for logic;
- do not HTML-encode values before passing them into JavaScript state or applying normalization.

Apply this consistently in:

- `renderTagListInputField()`;
- `renderTagListTypeAheadInputField()`;
- `renderControlConfigOptions()`;
- `renderShowHiddenButton()`.

### 2. Validate structured arguments before rendering

Add explicit validation for values with a constrained grammar:

- `fieldID`, `fieldName`, and the computed prefixed ID: allow letters, numbers, `_`, `-`, `.`, `:`, `[`, and `]` as needed for normal form names; reject control characters, whitespace in IDs, quotes, and angle brackets;
- `tagCase`: allow only empty string, `lower`, `upper`, or `capitalize`;
- `valueFormat`: allow only `json` or `comma`, defaulting to `json`;
- boolean arguments, including `normalizeStoredCase`: convert to `0` or `1`;
- CSS class arguments: trim and encode at output; optionally reject control characters, quotes, angle brackets, and backticks without restricting valid Bootstrap class combinations.

Use clear ColdFusion exceptions for invalid developer configuration rather than silently rewriting identifiers.

### 3. Preserve preloaded tag values safely

`fieldValue` must be serialized according to `valueFormat` and then HTML-attribute encoded when placed in `data-fieldvalue`. In the default JSON mode, confirm that the browser/jQuery attribute read returns JSON that can be parsed exactly once, without double decoding or double encoding.

Update the CFC argument contract so callers can safely supply either:

- a native ColdFusion array of tag strings, serialized with `SerializeJSON()` in JSON mode or joined only in deprecated comma mode;
- a JSON array string in JSON mode; or
- a comma-delimited string when `valueFormat="comma"` or during the JSON migration fallback.

New calls that omit `valueFormat` must render JSON. Comma output is permitted only when the caller explicitly selects the deprecated comma format.

### 4. Regression cases

Render both CFC helper variants using values containing:

- `"><img src=x onerror=alert(1)>`;
- single and double quotes;
- `<`, `>`, `&`, and backticks;
- non-ASCII and emoji text;
- valid Bootstrap class lists;
- invalid ID characters.

Acceptance criteria:

- no injected element or event handler appears in the DOM;
- visible text displays literally;
- valid IDs and class lists retain their expected behavior;
- invalid structured configuration produces a controlled error.

## Phase 2: Canonical Tag Validation and JSON Serialization

Priority: high; implement immediately after output encoding.

### 1. Centralize tag preparation in `js/tag-list-builder.js`

Introduce one helper responsible for producing the internal tag representation:

1. trimming surrounding whitespace;
2. retaining the trimmed entered or preloaded string as the candidate stored value;
3. applying configured case normalization to produce the comparison key and display label;
4. applying `normalizeStoredCase` to select either the normalized or preserved-case stored value;
5. returning an object containing `value`, `key`, and `label`.

Call it for:

- string elements parsed from the JSON `data-fieldvalue` array;
- newly entered values;
- values reconstructed after sorting.

Do not infer the saved value from rendered text. Maintain the three representations explicitly.

Recommended internal state:

```js
{
  value: "McDonald",
  key: "mcdonald",
  label: "mcdonald"
}
```

This example assumes `tagCase="lower"` and `normalizeStoredCase=false`.

### 2. Validate JSON structure and tag values

Add a validation helper that rejects:

- empty values;
- control characters, including CR, LF, and NUL;
- values beyond a documented maximum length.

When `valueFormat="comma"`, also reject values containing commas because that format cannot represent them unambiguously. JSON mode permits commas.

The initializer must also reject invalid saved-value structures:

- malformed JSON that claims to be JSON;
- a JSON top-level value other than an array;
- array members that are not strings;
- arrays beyond the configured tag-count limit.

Commas remain valid tag characters. For example, `["Washington, DC"]` represents one tag.

Recommended initial limits:

- maximum tag length: 100 characters;
- maximum tags per field: 100.

Keep these values as named configuration defaults rather than scattered literals. If existing consumer requirements conflict with these defaults, make the limits configurable through constrained `data-*` values before implementation.

### 3. Run duplicate detection on normalized comparison keys

Normalize first, then compare the candidate `key` against existing tag keys. For example, a lowercase field must treat `Admin` and `admin` as duplicates regardless of `normalizeStoredCase`.

Apply the same policy to preloaded values. Decide consistently whether duplicate preloaded values are ignored or cause an initialization warning; ignoring later duplicates is recommended for backwards compatibility.

### 4. Make removal independent of rendered text lookup

Store a stable internal identifier or the comparison key on each rendered tag node using jQuery `.data()`. Remove the corresponding state object rather than deriving identity from `.text()` or assuming that the label equals the serialized value.

Guard against `indexOf()` returning `-1`; never call `splice(-1, 1)`.

### 5. Serialize only validated state in the configured format

All hidden-field updates must originate from validated internal state. Do not serialize comparison keys, labels, DOM text, or the internal objects themselves.

- JSON mode: use `JSON.stringify(state.map(tag => tag.value))`.
- Deprecated comma mode: use `state.map(tag => tag.value).join(',')` only after rejecting comma-containing values.

The JSON empty state must write `[]`; deprecated comma mode retains an empty string. Sorting must serialize reordered state without reparsing rendered text.

### 6. Provide a controlled legacy-read migration

For JSON-mode preloaded values only:

1. treat an empty value as an empty array during migration;
2. attempt to parse JSON;
3. accept it only when it is an array of strings;
4. if it is clearly a legacy non-JSON value, split it using the old comma behavior;
5. normalize and validate every migrated element;
6. immediately rewrite the hidden field and `data-fieldvalue` attribute as JSON.

If a value begins like JSON but is malformed, report an initialization error rather than silently interpreting it as a comma list. Keep explicit `valueFormat="comma"` support until a future breaking release removes it; the automatic JSON-mode fallback can be removed earlier after consumers migrate.

Read the serialized value with `.attr('data-fieldvalue')`, not `.data('fieldvalue')`. jQuery may automatically coerce JSON-looking `data-*` attributes and cache the result, which would make parsing and synchronization ambiguous. Write the same format-specific serialized string to both `.val()` and `.attr('data-fieldvalue', serializedValue)`.

Acceptance criteria:

- a tag entered as `Washington, DC` remains one JSON array element;
- deprecated comma mode rejects `Washington, DC` as ambiguous;
- case-normalized duplicates are rejected;
- with `normalizeStoredCase=true`, the saved value uses the configured normalized case;
- with `normalizeStoredCase=false`, the saved value preserves entered casing while duplicate detection and labels use the configured case;
- removing any rendered tag removes exactly the matching array element;
- preloaded, added, removed, and sorted values all serialize identically to the displayed order;
- empty controls serialize as `[]`;
- valid legacy preloaded values are rewritten as JSON;
- explicit comma mode continues to read and write comma lists and is documented as deprecated;
- malformed JSON and non-string array members are rejected safely;
- JSON mode preserves Unicode, commas, quotes, and other permitted punctuation through a complete round trip;
- deprecated comma mode preserves all permitted values that do not contain its delimiter.

## Phase 3: Enforce the Readonly UI Contract

Priority: medium.

### 1. Render an appropriate input state

When `readonly=true`:

- mark the add input `disabled` or omit it from the interactive UI;
- retain the hidden field so the existing value can still be submitted if that is the established form behavior;
- add an accessible readonly description or state where appropriate.

### 2. Disable mutations in JavaScript

During initialization of a readonly field:

- do not bind the add-on-Enter behavior;
- do not render or activate remove controls;
- do not initialize sortable behavior;
- do not allow the raw-value display control to turn into an editable text input.

Add defensive checks inside mutation functions as well as at event-binding time.

### 3. Document the boundary

Update `README.md` to state:

- readonly is a client-side presentation feature;
- hidden fields and `data-*` attributes are attacker-controlled at submission time;
- consuming applications must parse the configured format defensively and authorize and validate every submitted tag on the server;
- new integrations should use JSON, while comma mode exists only for migration compatibility.

Acceptance criteria:

- readonly preloaded tags display normally;
- tags cannot be added, removed, reordered, or edited through the normal UI;
- non-readonly controls retain current behavior;
- server-side validation responsibility is explicit in documentation.

## Phase 4: Clarify Validation and Typeahead Semantics

Priority: medium.

### 1. Deprecate `validateTags` accurately

In `components/controls.cfc`:

- replace the current "enforce tag validation" hint with wording that the argument is reserved/deprecated and performs no validation;
- continue safely encoding the value if it must remain in markup for compatibility;
- do not introduce partial client-only allowlisting under this name.

In `README.md`:

- document the option as non-enforcing;
- state that typeahead results are suggestions;
- document `normalizeStoredCase`, including the difference between saved value, duplicate key, and displayed label;
- document `valueFormat="json"` as the default and `valueFormat="comma"` as deprecated;
- provide a concise server-validation checklist for integrators.

### 2. Avoid implying that typeahead selection is required

No change is required to free-text behavior unless the component later gains an explicit, separately designed `selectionRequired` contract with a trusted validation source. Do not infer security from a selected suggestion.

## Phase 5: Source/Distribution Parity and Debug Removal

Priority: complete in the same release as Phases 1–4.

### 1. Synchronize JavaScript artifacts

Bring these pairs to functional parity:

- `js/tag-list-builder.js` → `dist/js/tag-builder.js`;
- `js/tag-list-builder-typeahead.js` → `dist/js/tag-builder-typeahead.js`.

The existing distributable typeahead file contains application-specific IDs and AJAX endpoints that are not present in the current demo source. Replace that stale behavior with the canonical source behavior.

### 2. Remove production debug logging

- set debug mode off in source and distribution;
- remove unconditional configuration logging;
- ensure tag values and hidden-field contents are not written to the console by production artifacts.

### 3. Add a repeatable synchronization check

Preferred lightweight approach:

- add a repository build/check script that copies canonical source files to the expected distribution names;
- support a check-only mode that fails when source and distribution differ;
- document the command in `README.md`.

If a build script is not desired, document the exact manual copy and comparison procedure, but an automated check is preferred.

Acceptance criteria:

- source and distribution execute the same security-relevant logic;
- no demo-specific production endpoints remain in `dist/`;
- no production debug logging exposes tag values;
- the sync check detects a deliberate source/dist mismatch.

## Phase 6: jQuery 4, Bootstrap, Bootbox, and Dependency Maintenance

Priority: required compatibility-focused change after the core security fixes.

### 1. Create an explicit dependency inventory

Document for every CDN dependency:

- library name;
- pinned version;
- source URL;
- purpose;
- upstream release/advisory location;
- last review date.

Do not add an npm manifest that falsely implies the CDN files are installed or bundled unless the project adopts an actual package-based build.

### 2. Target current supported runtime versions

At the time this plan was written, the explicit migration targets are:

- full jQuery 4.0.0 or the latest available 4.x patch;
- Bootstrap 5.3.8 or the latest available 5.x patch;
- Bootbox 6.0.4 or the latest available compatible 6.x patch;
- HTML5 Sortable 0.14.0 or the latest available compatible 0.x patch.

Confirm the current releases from their official upstream sources at implementation time and pin exact versions in both demos.

Use the full jQuery build, not the slim build, because the typeahead plugin and its AJAX behavior may depend on Deferred or other modules omitted from the jQuery 4 slim build.

### 3. Update project code for jQuery 4

Review `js/tag-list-builder.js` and `js/tag-list-builder-typeahead.js` against the official jQuery 4 upgrade guide.

Required code conventions:

- use native `JSON.parse()` and `JSON.stringify()` for JSON-mode saved values;
- use `Array.isArray()`, native string `.trim()`, `typeof`, and other native replacements instead of removed jQuery utility APIs;
- use `.on('keydown', ...)`, `.on('keyup', ...)`, and `.on('click', ...)` for event registration;
- prefer `event.key === 'Enter'`, with a narrowly scoped fallback only if a supported browser requires it, instead of deprecated numeric `keyCode` logic;
- avoid undocumented jQuery collection array methods;
- use `.attr('data-fieldvalue')` for raw serialized JSON and avoid reliance on `.data()` coercion/caching;
- specify CSS units explicitly anywhere jQuery sets numeric style values;
- keep DOM creation on safe element/property APIs rather than HTML strings.

### 4. Use jQuery Migrate only as a development gate

Follow the official jQuery migration sequence:

1. load the full jQuery 4.x development build;
2. load the unminified jQuery Migrate 4.x development plugin immediately after jQuery;
3. exercise both demos and every dependency-backed behavior;
4. resolve every relevant Migrate warning in project or third-party code;
5. remove jQuery Migrate;
6. rerun the full matrix using jQuery 4.x alone.

jQuery Migrate must not be a permanent production dependency or a compatibility patch shipped by the demo pages.

### 5. Gate or replace `jquery-typeahead`

Run `jquery-typeahead` 2.11.1 under jQuery 4 with the Migrate development build and test its AJAX, selection, keyboard, cancel, and rendering paths.

If it uses removed jQuery APIs or otherwise fails without Migrate:

- first check for a maintained upstream release compatible with jQuery 4;
- if none exists, replace it with a maintained Bootstrap-compatible autocomplete component or create a narrowly scoped local compatibility patch with tests;
- do not keep jQuery Migrate in production merely to preserve the plugin;
- preserve the tag builder's public typeahead behavior and document any markup/API changes.

The typeahead-enabled variants are not considered jQuery 4 compatible until they run without Migrate.

### 6. Upgrade Bootstrap and Bootbox together

Update Bootstrap and Bootbox in both `index.cfm` and `index.html`, then verify:

- Bootbox alerts render, focus, dismiss, and restore focus correctly;
- Bootstrap modal markup and data attributes generated by Bootbox are valid for the selected Bootstrap version;
- buttons, badges, spacing, cards, and responsive layouts retain their presentation;
- no removed Bootstrap class or data-attribute convention is used;
- CSP reporting does not reveal new unexpected script or style requirements.

The component code should depend only on public Bootstrap and Bootbox behavior, not generated internal markup.

### 7. Upgrade HTML5 Sortable

Update HTML5 Sortable from 0.13.3 to 0.14.0 in both demo entry points. The library remains independent of jQuery and its documented `sortable()`, `orientation`, `hoverClass`, `placeholder`, `sortupdate`, and `e.detail.origin.items` APIs match the component's current integration.

Verify:

- horizontal dragging in both sortable demo variants;
- correct `sortupdate` item order;
- JSON hidden-field order after dragging;
- reload behavior after adding or removing tags;
- readonly fields never initialize sorting;
- current Chromium and Firefox behavior;
- the updated CDN URL, SRI hash, and `crossorigin` metadata.

HTML5 Sortable is community-maintained rather than actively developed. A possible migration to a more actively maintained sorting library is tracked separately in `_notes/plans/future-enhancements.md` and is not part of this remediation.

### 8. Upgrade remaining dependencies separately

After the required jQuery, Bootstrap, and Bootbox targets pass:

1. update Font Awesome within the maintained 6.x LTS line;
2. update html5sortable after confirming its API and event payload compatibility;
3. review `jquery-typeahead` independently if it was not already replaced during the jQuery 4 migration.

### 9. Update integrity metadata

For every CDN change:

- use the upstream-published production URL;
- calculate or copy the matching SRI hash from a trusted source;
- retain `crossorigin="anonymous"`;
- update both `index.cfm` and `index.html` together.

Acceptance criteria:

- both demos load the pinned full jQuery 4.x build;
- no jQuery Migrate script is present in the finished pages;
- the browser console contains no Migrate warnings during the migration pass and no runtime errors afterward;
- typeahead, Bootbox alerts, sorting, and all core tag operations work under jQuery 4.x;
- both demos load the pinned latest compatible Bootstrap 5.x and Bootbox 6.x releases;
- both demos load HTML5 Sortable 0.14.0 and preserve sorting behavior;
- CDN URLs, SRI hashes, and `crossorigin` attributes match in `index.cfm` and `index.html`;
- README dependency versions match the actual demo assets.

Official migration references:

- [jQuery 4.0 upgrade guide](https://jquery.com/upgrade-guide/4.0/)
- [jQuery 4.0 release notes](https://blog.jquery.com/2026/01/17/jquery-4-0-0/)
- [jQuery Migrate](https://github.com/jquery/jquery-migrate)
- [Bootstrap current 5.x documentation](https://getbootstrap.com/docs/5.3/getting-started/introduction/)
- [Bootbox changelog](https://github.com/bootboxjs/bootbox/blob/master/CHANGELOG.md)
- [HTML5 Sortable package](https://www.npmjs.com/package/html5sortable)

## Phase 7: Content Security Policy

Priority: defense in depth after compatibility testing.

### 1. Define the deployment policy

Prefer an HTTP response header over a `<meta>` element. Begin with `Content-Security-Policy-Report-Only` in the environment that serves `index.cfm`.

The initial policy should account for:

- scripts from the application origin, cdnjs, and jsDelivr;
- styles from the application origin and the two CDN providers;
- fonts loaded by Font Awesome;
- same-origin JSON requests to `data/libs.json`;
- image sources used by the demo.

Do not add `unsafe-inline` to `script-src`; the current pages do not require inline browser scripts.

### 2. Resolve style compatibility before enforcement

The sortable placeholder currently includes an inline `style` attribute, and third-party widgets may set inline positioning styles. Move project-owned inline styles into CSS. Observe report-only violations from third-party behavior before choosing the narrowest viable `style-src` policy.

### 3. Document static-host limitations

`index.html` may be served from a host where repository code cannot set HTTP headers. Document the recommended host configuration. Use a CSP `<meta>` element only if an enforcing policy for the static demo is required and tested.

Acceptance criteria:

- report-only mode shows no unexplained script-source violations;
- the demos function without `unsafe-inline` in `script-src`;
- the final policy is delivered as a response header where deployment control exists;
- CSP configuration remains deployment documentation rather than a promise made by the reusable JavaScript library.

## Phase 8: Verification

### Automated/static checks

- run a JavaScript syntax check on source and distribution files;
- search rendered CFC output sites to confirm all argument interpolation is context encoded;
- compare source and distribution artifacts;
- scan the repository for new HTML-string construction involving tag values;
- verify all CDN URLs have matching SRI and `crossorigin` attributes.

### Manual browser matrix

Test `index.html` and `index.cfm` in at least one Chromium browser and Firefox:

1. add a normal tag;
2. reject an empty tag;
3. add a tag containing a comma and confirm it remains one JSON element;
4. reject a normalized duplicate;
5. remove first, middle, and last tags;
6. sort tags and confirm JSON array order in the hidden field;
7. initialize preloaded JSON values;
8. migrate a legacy comma-delimited preloaded value and confirm the field is rewritten as JSON;
9. reject malformed JSON, non-array JSON, and non-string array members;
10. verify lower, upper, and capitalize modes with stored-case normalization enabled;
11. disable stored-case normalization and verify JSON preserves entered casing while duplicates still compare using normalized keys;
12. sort preserved-case values and verify JSON retains each original stored value in the new order;
13. exercise typeahead and free-text entry;
14. verify readonly controls cannot mutate;
15. show and hide the raw JSON value where allowed;
16. select deprecated comma mode and verify comma-list read/write behavior;
17. verify comma mode rejects tags containing commas;
18. repeat core behavior with the `dist/` scripts.

### Security payload matrix

Test malicious input through both interactive entry and CFC preloaded arguments:

- HTML elements and event handlers;
- quotes and malformed attributes;
- JSON syntax characters, commas, and newline/control characters;
- long values and excessive tag counts;
- duplicate values differing only by configured case normalization, with stored-case normalization both enabled and disabled;
- Unicode and emoji.

Acceptance criteria:

- payloads are displayed as inert text or rejected according to the documented contract;
- no unexpected DOM nodes, event attributes, or script execution occur;
- JSON-mode hidden values contain only arrays of validated stored strings;
- deprecated comma-mode hidden values contain only validated strings that cannot contain the delimiter;
- all four demo variants remain operational.

## Change Packaging

Use small reviewable changes in this order:

1. CFC context encoding and structured-argument validation;
2. canonical tag normalization, JSON migration/serialization, and mutation safety;
3. readonly behavior and validation/typeahead documentation;
4. `dist/` synchronization and debug removal;
5. jQuery 4, current Bootstrap 5.x, current Bootbox 6.x, and remaining dependency upgrades;
6. CSP deployment guidance and rollout.

Do not combine dependency major-version migration with the XSS fix. This keeps the urgent correction easy to review, test, and release.

## Final Completion Criteria

The remediation is complete when:

- all CFC output is context encoded;
- structured arguments are validated;
- JSON is the default saved-value format, deprecated comma lists remain available through an explicit option, duplicate checks use normalized keys, and stored casing follows `normalizeStoredCase` with a default of `false`;
- readonly behavior is consistently enforced in the UI;
- `validateTags` and typeahead are no longer represented as security controls;
- source and distribution artifacts are synchronized and debug-safe;
- the demos run on full jQuery 4.x without jQuery Migrate;
- typeahead and all other jQuery plugins pass under jQuery 4.x or are replaced;
- the demos use the latest verified compatible Bootstrap 5.x and Bootbox 6.x releases;
- dependency versions and review procedures are documented;
- a CSP deployment path is documented and tested;
- the full manual and security regression matrix passes.
