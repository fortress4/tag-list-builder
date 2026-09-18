# Code Review Findings

Reviewed folder: `/mnt/d/web_git/tag_list_builder`

Date: 2026-06-17

## Findings

1. `js/tag-list-builder.js:294` injects raw tag text directly into HTML and attribute strings. A user-entered tag like `"><img src=x onerror=alert(1)>` will be appended unsafely into the DOM, so this is an XSS bug, not just malformed markup. The tag text should be escaped or rendered by constructing DOM nodes instead of concatenating HTML strings.

2. `js/tag-list-builder.js:222-225` stores the original entered tag in `tags_array`, but `js/tag-list-builder.js:270-276` may render a transformed version (`upper`, `lower`, `capitalize`). Removal later uses the rendered text from `js/tag-list-builder.js:128,143`, so `indexOf(itmName)` can miss and `splice(-1, 1)` removes the wrong tag. Example: add `foo` then `bar` in an `upper` field, click remove on `FOO`, and `bar` gets removed from the hidden value. Duplicate detection is also inconsistent for the same reason because `foo` and `FOO` are treated as different before normalization.

3. `js/tag-list-builder-typeahead.js:13-47` and `js/tag-list-builder-typeahead.js:49-66` hardcode `#exampleThree_add` and `#exampleFour_add`. That means the ColdFusion helpers in `components/controls.cfc` are not actually reusable for arbitrary typeahead fields: any field rendered with a different ID will never get initialized. This is a functional mismatch between the component API and the JavaScript implementation.

## Notes

- I assumed `index.cfm` is the primary entry point and `index.html` is a static demo copy.
- I did not find automated tests covering these behaviors.
