# Vanilla JS Alternate Implementation Plan

Date: 2026-06-17

## Goal

Add a Bootstrap-based Vanilla JS version of the tag list builder as an alternate implementation.

Do not replace the current jQuery version.

This note is a plan only. Do not create the Vanilla demo page or implementation files yet.

## Scope

The new implementation should:

- require no jQuery
- preserve the current Bootstrap-based presentation
- coexist with the current jQuery implementation
- reuse the current markup/data-attribute contract where practical
- avoid breaking existing `index.cfm`, `index.html`, `js/`, or `dist/` jQuery consumers

## Non-Goals

- removing jQuery from the existing implementation
- changing the default implementation away from jQuery
- rewriting the project into a framework
- solving every existing bug as part of the initial Vanilla port

## Proposed Deliverables

### New source files

- `js/tag-list-builder-vanilla.js`
- `css/tag-list-builder-vanilla.css` only if the current CSS cannot be reused cleanly

### New distribution files

- `dist/js/tag-builder-vanilla.js`
- `dist/css/tag-builder-vanilla.css` only if a separate CSS artifact is needed

### New demo entry points

- `index-js.html`
- optionally `index-vanilla.cfm` if a ColdFusion demo is useful for parity

Status:

- deferred
- document only for now
- do not create these files until implementation work is explicitly requested

### Documentation updates

- `README.md`
- `AGENTS.md`

## Compatibility Strategy

The safest approach is to keep the current HTML structure and data attributes as the shared contract.

Existing attributes already used by the jQuery implementation:

- `data-fieldvalue`
- `data-required`
- `data-readonly`
- `data-autocomplete`
- `data-tagsorting`
- `data-tagcase`
- `data-tagclass`
- `data-taghoverclass`
- `data-validatetags`

The Vanilla implementation should read the same attributes where possible so `components/controls.cfc` does not need a parallel markup system.

## Implementation Selection

Add an explicit implementation selector to the rendered control markup, for example:

- `data-implementation="jquery"`
- `data-implementation="vanilla"`

Recommended default:

- keep jQuery as the default for backwards compatibility

Recommended behavior:

- jQuery script initializes only controls marked `jquery` or with no explicit implementation
- Vanilla script initializes only controls marked `vanilla`

This prevents both implementations from attaching to the same control.

## Phased Work Plan

### Phase 1: Shared contract and demo split

1. Review `components/controls.cfc` and identify the minimum markup changes needed to support an implementation selector.
2. Add an optional CFC argument such as `implementation="jquery"`.
3. Emit `data-implementation` in rendered controls.
4. Keep existing demo pages working unchanged.
5. Add a new standalone demo page for Vanilla usage instead of mixing both implementations into one page initially.
   - Planning note: do not create this page yet.

### Phase 2: Vanilla core behavior

Implement a first-pass `js/tag-list-builder-vanilla.js` with:

- initialize each `.tagBuilder` control marked for Vanilla
- read config from data attributes
- preload tags from `data-fieldvalue`
- add tag on Enter
- remove tag on click
- update the hidden field after each change
- show/hide empty-state message
- show/hide raw tag list button
- apply `lower`, `upper`, and `capitalize` case transforms

Important requirement:

- build tag DOM nodes with safe DOM APIs, not HTML string concatenation

### Phase 3: Sorting support

Implement sorting in the Vanilla path without jQuery.

Recommended approach:

- use native HTML5 drag-and-drop

Alternative:

- continue using a non-jQuery sortable helper if native drag/drop becomes too brittle

Phase 3 tasks:

1. Make tag pills draggable when `data-tagsorting="1"`.
2. Provide a visible placeholder or drag state.
3. Persist the visual order back into the hidden field.
4. Preserve Bootstrap styling and existing hover-class behavior where possible.

### Phase 4: Typeahead support

Do not block the initial Vanilla release on autocomplete.

Implement typeahead separately after the core tag builder works.

Options:

1. Native `datalist`
   - simplest
   - limited UX
   - minimal dependency footprint

2. Small non-jQuery autocomplete library
   - better UX
   - adds another dependency

3. Custom lightweight autocomplete
   - highest control
   - highest implementation cost

Recommendation:

- start with core tag builder first
- evaluate whether `datalist` is sufficient for this project before adding a custom solution

## File-Level Checklist

### `components/controls.cfc`

- add optional implementation argument
- render `data-implementation`
- verify selectors and class names remain compatible with current JS
- decide whether typeahead wrapper markup should be shared or implementation-specific

### `js/tag-list-builder-vanilla.js`

- define control initialization
- define config parsing
- define normalized tag value handling
- render tags safely via DOM APIs
- support remove interactions
- support hidden field sync
- support raw value toggle
- add sorting hooks
- later add autocomplete hooks

### `index-js.html`

- include Bootstrap
- include current shared CSS if possible
- exclude jQuery
- include only the Vanilla JS implementation
- demonstrate the same four variants if possible:
  - tag sorting
  - no sorting
  - typeahead with sorting
  - typeahead without sorting

Current status:

- planned only
- not to be created during planning

### `index-vanilla.cfm`

- optional
- useful only if ColdFusion consumers need a full server-rendered example

### `README.md`

- document the two implementations
- document dependencies for each
- document feature parity status
- document demo entry points

### `AGENTS.md`

- record which files are canonical for the Vanilla path
- note whether `dist/` must stay in sync

## Design Notes

### Normalize before storing

The Vanilla implementation should normalize tag text before:

- duplicate checks
- storage in internal state
- rendering
- hidden field serialization

This avoids the current mismatch in the jQuery implementation where rendered values and internal values can diverge.

### Prefer event delegation

Use event delegation from the wrapper/bin where practical to keep listener count low and simplify dynamic tag removal.

### Keep config parsing explicit

Avoid implicit truthiness bugs from string attributes like `"0"` and `"1"`.

Helpers should parse these values intentionally.

### Preserve CSS contract where possible

Reuse existing classes like:

- `.tagBuilderWrapper`
- `.tagBuilderBin`
- `.tagBuilderMsg`
- `.tagBuilderTag`
- `.tagBuilderShowBtn`

This reduces CSS churn and keeps the Bootstrap look consistent.

## Risks

1. The current markup and JS are tightly coupled, so small markup changes in `controls.cfc` can break the jQuery implementation if not tested carefully.
2. Typeahead is currently demo-specific and hardcoded in the jQuery version, so parity in the Vanilla version may require first clarifying the desired generic API.
3. Native drag-and-drop behavior may require more cross-browser polish than the current library-backed approach.
4. If `dist/` is treated as checked-in release output, every source change may need mirrored updates.

## Recommended Rollout

1. Add `data-implementation` support in `components/controls.cfc`.
2. Build the Vanilla core with no typeahead and no sorting first.
3. Add a dedicated `index-vanilla.html` demo.
4. Add sorting support.
5. Add autocomplete support last.
6. Update docs after feature parity is clear.

## Manual Verification Matrix

Verify both implementations separately.

### Core

- add a tag
- remove a tag
- prevent empty tags
- prevent duplicates
- preload from `data-fieldvalue`
- confirm hidden field matches rendered order

### Case handling

- no tag case
- `lower`
- `upper`
- `capitalize`

### Sorting

- sorting enabled
- sorting disabled
- reorder updates hidden value correctly

### Raw value toggle

- toggle hidden/text field state
- confirm displayed raw value matches current tag list

### Typeahead

- enabled controls initialize
- suggestions appear
- selected value becomes a tag
- non-typeahead controls still work normally

## Suggested First Implementation Cut

The best first milestone is:

- a working Vanilla implementation for non-typeahead controls
- no jQuery dependency
- no sorting yet
- one standalone demo page proving add/remove/state sync/case handling

That gets the architecture in place before taking on drag-and-drop and autocomplete complexity.

Execution note:

- do not start this milestone until implementation is explicitly requested
