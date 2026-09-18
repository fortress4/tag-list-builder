# Security Audit — 2026-09-17

## Remediation Status

The production code findings were remediated on 2026-09-17:

- ColdFusion text and attribute output now uses context-specific encoding, and structured configuration is validated.
- Browser tag rendering uses text nodes and does not interpret tag values as HTML.
- JSON arrays are the default saved format; legacy comma values migrate to JSON, while explicit deprecated comma mode rejects commas in individual tags.
- Duplicate checks use normalized keys, removal no longer derives identity from rendered text, and stored-case normalization is configurable with a default of false.
- Readonly fields disable add, remove, and sort UI operations. Server-side authorization remains the consuming application's responsibility.
- Source and `dist/` assets are synchronized by `build.ps1`, and production debug logging is disabled.
- The demos now target jQuery 4.0.0, Bootstrap 5.3.8, Bootbox 6.0.4, and HTML5 Sortable 0.14.0.

Verification passed in the browser smoke test and on Lucee 5.4.8.2. The CFML smoke test renders hostile values through the reusable helper and confirms no executable `script` or `img` element is emitted. A deployment-level Content Security Policy remains recommended defense in depth rather than a library-code fix.

## Executive Summary

The production library audit identified one high-severity conditional risk, two medium-severity risks, and three low-severity hardening issues.

The original demo pages passed trusted constants into the tag-list helpers. The most important original risk appeared when the reusable ColdFusion component received user-controlled or database-derived values; that output path is now context encoded and regression tested.

## Scope and Method

Reviewed:

- `components/controls.cfc`
- `components/base.cfc`
- `js/tag-list-builder.js`
- `js/tag-list-builder-typeahead.js`
- corresponding files under `dist/`
- `index.cfm` and `index.html`
- CDN dependency declarations
- repository history relevant to the earlier tag-rendering XSS finding

The review used static source analysis, targeted searches for browser and ColdFusion security sinks, repository-history inspection, secret-pattern checks, and a review of current upstream dependency information. Remediation was subsequently exercised on Lucee 5.4.8.2 and in a Chromium browser engine.

## Findings

### High: Unencoded CFC output can cause HTML injection and XSS

**Evidence:** `components/controls.cfc:55-70`, `components/controls.cfc:132-158`, and `components/controls.cfc:179-200`.

The component inserts string arguments directly into HTML text and attribute contexts. It does not use `EncodeForHTML()` or `EncodeForHTMLAttribute()`.

Affected arguments include:

- `fieldValue`
- `fieldLabel`
- `messageText`
- `placeholder`
- `fieldName`, `fieldID`, and `fieldPrefix`
- CSS-class arguments
- `tagCase`, `tagHoverClass`, and `validateTags`

The most likely path is a stored value passed through `fieldValue`. For example, a value shaped like the following can terminate the `data-fieldvalue` attribute and add attacker-controlled markup:

```text
"><img src=x onerror=alert(document.domain)>
```

This happens while the browser parses the server-generated HTML, before the safer JavaScript tag renderer is involved.

**Impact:** Execution of attacker-controlled JavaScript in the application origin, potentially exposing authenticated data or enabling actions as the victim.

**Conditions:** A caller must pass untrusted or insufficiently sanitized data into one of the helper arguments. The current demo calls use constants and do not provide a direct request-input path.

**Remediation:**

- Use `EncodeForHTML()` for text-node output.
- Use `EncodeForHTMLAttribute()` for attribute values.
- Validate IDs and names against a conservative identifier pattern.
- Allowlist supported CSS classes and `tagCase` values instead of accepting arbitrary strings.
- Add tests using quotes, angle brackets, ampersands, and event-handler payloads in every public string argument.

### Medium: `readonly` and `validateTags` are not enforced

**Evidence:** `components/controls.cfc:20-25`, `components/controls.cfc:64-70`, `components/controls.cfc:96-101`, and `components/controls.cfc:152-158`.

The component exposes `readonly` and `validateTags` options but only writes them to `data-*` attributes. The browser code never enforces either value. Typeahead inputs also accept arbitrary typed text instead of requiring a listed selection.

**Impact:** An integrating application could mistakenly rely on these options as authorization or whitelist controls. Attackers can edit the hidden form value directly regardless of the UI.

**Remediation:**

- Treat every submitted tag value as untrusted.
- Enforce authorization, membership, allowed characters, length, count, and uniqueness on the server.
- Either implement the documented client behavior or remove/rename options that imply enforcement.
- Document that typeahead is a suggestion mechanism, not a security boundary.

### Medium: Comma-delimited serialization permits tag-boundary injection

**Evidence:** `js/tag-list-builder.js:42-43`, `js/tag-list-builder.js:194`, and `js/tag-list-builder.js:393-403`.

The UI accepts commas inside tag text, serializes tags with `join(',')`, and later parses them with `split(',')`. A visually single tag such as `staff,admin` therefore becomes two logical values after parsing or reinitialization.

**Impact:** Data-integrity failures and possible authorization problems if downstream code assigns meaning to individual tag values.

**Remediation:**

- Prefer an unambiguous representation such as a JSON array.
- If the existing wire format must remain, reject commas in tag values on both client and server.
- Add round-trip tests covering commas, quotes, Unicode, and whitespace.

### Low: Dependency management is manual and versions are stale

**Evidence:** `index.cfm:18-22`, `index.cfm:273-281`, `index.html:11-20`, and `index.html:302-319`.

Dependencies are loaded from CDNs with fixed versions and Subresource Integrity, which reduces CDN-tampering risk. However, there is no package manifest, lockfile, automated advisory scan, or documented update process.

At review time:

- the project uses jQuery 3.6.3 while the latest supported release is 4.0.0;
- the project uses Bootstrap 5.2.3 while the current 5.x documentation is for 5.3.8;
- the project uses Bootbox 6.0.0 while 6.0.4 is available;
- Font Awesome 6.3.0 is behind the maintained Font Awesome 6 LTS patch line.

No specific applicable public vulnerability was confirmed for the pinned versions during this review. The issue is reduced maintenance visibility and delayed receipt of security fixes.

**Remediation:** Maintain a dependency inventory, establish periodic update checks, and test upgrades in a separate change. If CDN loading remains, update SRI hashes whenever versions change.

### Low: No Content Security Policy is defined in the pages

**Evidence:** `index.cfm` and `index.html` contain no CSP declaration.

A deployment-level response header may provide a policy, but none is defined in the repository. CSP would reduce the impact of a future injection defect.

**Remediation:** Configure CSP as an HTTP response header. Start in report-only mode and allow only the application origin and the specific CDN origins needed by the demos. Avoid enabling `unsafe-inline` unless a concrete compatibility need is established.

### Low: Distributable build logs tag values in debug mode

**Evidence:** `dist/js/tag-builder.js:7` and `dist/js/tag-builder.js:116-124`.

The distributable build sets `tagBuilderDebug = 1` and logs the in-memory and hidden-field tag values after sorting. This can expose values to local console capture and indicates that `dist/` is not synchronized with the source behavior.

**Remediation:** Disable debug output in distributed assets and define a repeatable process that regenerates and verifies `dist/` from source.

## Positive Findings

- Commit `f794bba` replaced HTML-string tag construction with jQuery-created elements and `.text()`. The current tag renderer at `js/tag-list-builder.js:294-306` does not directly interpret tag text as HTML.
- The matching distributable tag-rendering path also uses `.text()`.
- CDN resources use HTTPS, fixed versions, `crossorigin="anonymous"`, and Subresource Integrity hashes.
- No committed credentials or obvious API secrets were found.
- No SQL execution, `eval`, dynamic function construction, or unsafe deserialization was found.
- The primary demo does not implement a state-changing server endpoint, so CSRF is not presently applicable to the tag UI itself.

## Recommended Remediation Order

1. Encode every CFC output according to its HTML context and add injection regression tests.
2. Define and enforce the server-side tag contract, including authorization and validation.
3. Replace comma-separated serialization or explicitly prohibit commas.
4. Synchronize `dist/`, disable debug logging, and establish dependency monitoring.
5. Add a deployment-level Content Security Policy.
6. Keep developer-only build utilities excluded from production deployment artifacts.

## Verification Notes

After remediation, manually verify:

- malicious strings remain inert in labels, placeholders, messages, IDs, CSS options, and preloaded tag values;
- add, remove, duplicate prevention, sorting, and typeahead behavior still work;
- submitted values are rejected server-side when unauthorized or malformed;
- tag serialization round-trips without changing tag boundaries;
- production deployments do not expose development utilities;
- source and `dist/` contain equivalent behavior and no debug logging.
