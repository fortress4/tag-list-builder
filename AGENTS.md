# AGENTS.md

## Project Summary

This repository contains a small tag-list builder UI component with two demo entry points:

- `index.cfm`: primary ColdFusion demo page using reusable CFC helpers
- `index.html`: static HTML demo copy of similar behavior

The component is built around jQuery and Bootstrap 5. It supports:

- adding/removing tags
- optional drag sorting via `html5sortable`
- optional typeahead via `jquery-typeahead`
- case normalization options: `lower`, `upper`, `capitalize`

## Main Files

- `js/tag-list-builder.js`: core tag builder behavior
- `js/tag-list-builder-typeahead.js`: typeahead initialization
- `components/controls.cfc`: ColdFusion helpers that render tag-builder markup
- `index.cfm`: server-rendered demo using `controls.cfc`
- `index.html`: static demo page
- `data/libs.json`: sample typeahead data source
- `css/`: source styles
- `dist/`: built/distributable CSS and JS copies
- `archive/`: older JS snapshots, useful for history only

## Canonical Behavior

If behavior changes, update both layers that define the contract:

- ColdFusion markup generation in `components/controls.cfc`
- browser behavior in `js/tag-list-builder.js` and `js/tag-list-builder-typeahead.js`

`index.cfm` is likely the primary entry point. `index.html` appears to be a parallel demo and can drift if changes are made in only one place.

## Important Constraints

- There are currently no automated tests in the repo.
- The git worktree may be dirty. Check `git status --short` before editing and avoid overwriting unrelated user changes.
- `dist/` exists alongside source files. If you change behavior or styling intended for distribution, verify whether matching `dist/` files also need to be updated.
- Typeahead currently depends on `data/libs.json` and CDN-hosted assets referenced by the demo pages.

## Known Risks

As of 2026-06-17, review findings are recorded in `_notes/review/code-review-2026-06-17.md`. The main issues are:

1. `js/tag-list-builder.js` renders user-provided tag text via HTML string concatenation, which is an XSS risk.
2. Tag case normalization is applied during render, but internal state stores the pre-normalized value, which can corrupt removal and duplicate checks.
3. `js/tag-list-builder-typeahead.js` hardcodes demo-specific element IDs, so the ColdFusion helper is not truly reusable for arbitrary typeahead field IDs.

Treat those as active hazards when modifying tag rendering or initialization.

## Working Guidance

- Prefer editing source files in `js/` and `css/` first, then reflect required changes into `dist/` if this repo expects distributable artifacts to stay in sync.
- When changing markup attributes or classes in `components/controls.cfc`, verify the selectors used in the JavaScript still match.
- When changing tag state logic, test these paths manually:
  - add tag
  - remove tag
  - duplicate prevention
  - sort update
  - preloaded `data-fieldvalue`
  - typeahead fields and non-typeahead fields
- If you need to review previous logic, `archive/b001` and `archive/b002` contain older JS versions.

## Minimal Manual Check

After changes, at minimum verify:

1. `index.html` still loads and basic add/remove works.
2. `index.cfm` still renders the four demo variants correctly.
3. sorted tags update the hidden field in the same order shown in the UI.
4. typeahead-enabled inputs still initialize and accept selected tags.
