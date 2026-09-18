# Event Listener API — Plan

**Status:** Implemented
**Created:** 2026-09-18
**Target release:** v0.3.0 (additive; no behavior change for existing consumers)
**Affects:** `js/tag-list-builder.js`, `dist/js/tag-builder.js`, `README.md`, `tests/browser-smoke.html`,
`version.json`, `package.json`

---

## 1. Goal

Give host applications a documented way to observe tag-list-builder activity — value changes, adds,
removes, reorders, and rejected input — without reaching into the component's internals.

Today there is no such contract. The only observable surface is the hidden field's value, and the
only hook points are module-level function names, which are not part of any published API.

---

## 2. Why now

A real consumer broke on the 0.1 → 0.2 upgrade.

The Scripts Data Manager app (`D:\web_git\scripts_data_mgr`) runs live alias validation against a
server endpoint every time an alias tag changes. With no event to listen to, it did this:

```js
window.tb_addTagToHiddenField      = triggerUpdateWrapper(window.tb_addTagToHiddenField);
window.tb_removeTagFromHiddenField = triggerUpdateWrapper(window.tb_removeTagFromHiddenField);
```

It wrapped two internal globals so it could re-trigger them as `tagBuilder:update` events on the
field. In v0.2.0 those functions no longer exist. The wrappers become no-ops, and the app's
validation **silently stops running** — no console error, no visible failure, just validation that
quietly never fires on add or remove.

That is the cost of having no extension surface: consumers invent one from internals, and a routine
refactor breaks them without warning. Any host that wants to react to tag changes — validation,
dirty-form tracking, live previews, analytics, dependent field updates — has the same problem.

The forthcoming vanilla build (`_notes/plans/future-enhancements.md`) already lists "emit documented
custom events for add, remove, reorder, validation failure, and value change if consumers need
integration hooks." This plan is that item, specified and brought forward to the jQuery build, so both
implementations ship the *same* contract rather than inventing two.

---

## 3. Current state

### 3.1 The single choke point

`tb_writeStoredValue(field)` (`js/tag-list-builder.js:316`) is the **only** function that changes the
stored value:

```js
function tb_writeStoredValue(field) {
   var serializedValue = tb_serializeStoredValues(field);
   field.val(serializedValue).attr('data-fieldvalue', serializedValue);
}
```

It is called from exactly four places:

| Call site | Line | Cause |
|---|---|---|
| initializer, after parsing `data-fieldvalue` | 54 | `init` — also where a legacy comma value is rewritten as JSON |
| `.removeTag` click handler | 109 | `remove` |
| `sortupdate` listener in `tb_initializeSortable()` | 170 | `sort` |
| `tb_addTag()` | 203 | `add` |

This is the ideal emit point: **no code path can change the value without announcing it**, which is
precisely the guarantee the old wrapper approach could not make.

### 3.2 Where input is rejected

- `tb_addTag()` (`:178`) calls `tb_alert(validationError)` for the result of
  `tb_validatePreparedTag()` — empty, control characters, over `maxTagLength`, a comma under
  `valueFormat="comma"`, or over `maxTags` — and `tb_alert('Tag must be unique.')` for duplicates.
- `tb_alert()` (`:376`) shows a Bootbox alert, falling back to `window.alert`.
- Initialization failures go to `tb_showInitializationError()` (`:371`), which writes into the
  message element and clears the field's tags.

A host that wants inline messaging instead of a modal (the SDM alias case) currently cannot
intercept any of this.

### 3.3 State shape

- `tags_array[fieldId]` — an array of `{ value, key, label }`. `value` is what gets saved, `key` and
  `label` are the case-normalized forms used for duplicate checking and display.
- `tbConfig[fieldId]` — the resolved per-field config.

Both are module-level objects keyed by field id. **Events must expose plain strings, never these
internal objects**, or the event payload becomes another accidental API tied to internal shape.

---

## 4. Proposed API

### 4.1 Events

All events are dispatched **on the stored input element** (`.tagBuilder`) and **bubble**.

| Event | Fired when | `detail` |
|---|---|---|
| `tagBuilder:init` | a field finished initializing successfully | `{ fieldId, values, migrated }` |
| `tagBuilder:update` | the stored value changed, for any reason | `{ fieldId, values, previous, reason }` |
| `tagBuilder:add` | one tag was accepted | `{ fieldId, value, values }` |
| `tagBuilder:remove` | one tag was removed | `{ fieldId, value, values }` |
| `tagBuilder:sort` | tags were reordered | `{ fieldId, values, previous }` |
| `tagBuilder:reject` | input was refused | `{ fieldId, value, reason, message }` |
| `tagBuilder:error` | initialization failed | `{ fieldId, message }` |

Common fields:

- `fieldId` — the stored input's `id`.
- `values` — a **copy** of the saved values, in order (`tags_array[id].map(t => t.value)`).
- `previous` — `values` as they were before the change.
- `serialized` — include on `update`: the exact string written to the field, so a host never has to
  re-serialize or guess the `valueFormat`.

`reason` values:

- on `update`: `'init' | 'add' | 'remove' | 'sort'` (leave room for `'clear'` / `'set'` when the
  imperative API lands).
- on `reject`: `'empty' | 'controlCharacters' | 'maxTagLength' | 'comma' | 'maxTags' | 'duplicate'` —
  a stable machine-readable code, with the human sentence carried separately in `message`.

`migrated: true` on `init` when the stored value was read as a legacy comma list and rewritten as
JSON. Hosts that track dirty state need this: the field's value changes at load with no user action.

### 4.2 Ordering

Specific event first, then the general one — so a listener bound only to `tagBuilder:update` always
sees a settled field:

```
tb_addTag  ->  tagBuilder:add  ->  tagBuilder:update (reason 'add')
remove     ->  tagBuilder:remove -> tagBuilder:update (reason 'remove')
sortupdate ->  tagBuilder:sort  -> tagBuilder:update (reason 'sort')
init       ->  tagBuilder:init  -> tagBuilder:update (reason 'init')
```

### 4.3 Dispatch mechanism — native `CustomEvent`

Emit with `element.dispatchEvent(new CustomEvent(name, { detail: payload, bubbles: true }))`, not
`$(field).trigger(name, [payload])`.

Reason: a jQuery-triggered event is invisible to `addEventListener`, while a native bubbling event is
visible to **both** jQuery `.on()` handlers and native listeners. The planned vanilla build must emit
the same contract (§2), and CSP-conscious hosts should not be forced to load jQuery to listen.

Document the jQuery access pattern explicitly, because jQuery's normalized event object may not carry
`detail` through:

```js
$('#props_aliasList').on('tagBuilder:update', function(event) {
   var data = event.detail || (event.originalEvent && event.originalEvent.detail);
   validate(data.values);
});
```

Verify in the smoke test which form actually works under jQuery 4 and put the working one in the
README. If `event.detail` proves unreliable, add the payload to `jQuery.event.addProp('detail', …)`
guidance rather than switching the dispatch mechanism.

### 4.4 The initialization timing problem

This needs deciding, because it decides whether `tagBuilder:init` is usable at all.

The component initializes inside `$(function() { … })`. A host binding its listener in its own
`$(function() { … })`, registered after the component's script tag, runs **after** initialization has
already happened — so both direct and delegated listeners miss `tagBuilder:init` and the
`reason: 'init'` update. An event nobody can hear is worse than no event, because it looks like it
works until a field's initial state matters.

Options:

1. **Dispatch init events asynchronously** — collect them during the ready loop and flush on
   `setTimeout(…, 0)` after every field is initialized. Any listener bound in any ready handler is
   attached by then. *(Recommended — smallest change, no ordering rules for hosts to get wrong.)*
2. **Require early binding** — document that `tagBuilder:init` must be bound before the component's
   script tag, via a delegated `document` listener. Works, but it is exactly the kind of implicit
   ordering rule that breaks quietly.
3. **Provide a readiness hook** — `$.tagBuilder.ready(callback)` that replays for already-initialized
   fields. More surface area; option 1 covers the need.

Whichever is chosen, `$.fn.tagBuilder('get')` (§4.5) gives a late listener a way to read current state
without an event, so no host is stuck.

### 4.5 Imperative API (phase 2)

A minimal instance API, so hosts can drive a field instead of writing `data-fieldvalue` and
re-initializing:

```
$('#field').tagBuilder('get')            -> ['a','b']
$('#field').tagBuilder('set', ['a','b'])  // replaces; fires update, reason 'set'
$('#field').tagBuilder('add', 'c')        // same validation path as typed input
$('#field').tagBuilder('remove', 'a')
$('#field').tagBuilder('clear')           // fires update, reason 'clear'
$('#field').tagBuilder('refresh')         // re-read data-fieldvalue and re-render
$('#field').tagBuilder('config')         -> a copy of the resolved config
```

Every mutating call must run the same normalize → validate → duplicate-check → serialize path as
typed input, and emit the same events. Anything less creates a second, divergent way to change state.

### 4.6 Explicit non-goals

- **No cancelable `beforeadd`.** The obvious use case (SDM: "is this alias already owned by another
  resource?") is an async server call, so a synchronous veto cannot answer it. Cancelable events are
  reconsidered only alongside an async validation hook, which is out of scope here.
- **No replacement of `tb_alert`.** `tagBuilder:reject` lets a host render its own message, but the
  built-in alert still fires. Suppressing it (a `data-suppressalerts` option, or honouring
  `preventDefault()` on `reject`) is a follow-up decision — see §9.
- **Internal functions stay internal.** `tb_*` functions and `tags_array` / `tbConfig` are not
  promoted to public API. The events are the contract; that is the whole point.
- No new dependencies.

---

## 5. Implementation sketch

One helper, used everywhere:

```js
function tb_emit(field, name, detail) {
   var element = field[0];
   if (!element || typeof window.CustomEvent !== 'function') {
      return;
   }
   detail.fieldId = field.attr('id');
   element.dispatchEvent(new CustomEvent('tagBuilder:' + name, { detail: detail, bubbles: true }));
}

function tb_currentValues(fieldId) {
   return (tags_array[fieldId] || []).map(function(tag) { return tag.value; });
}
```

Changes:

1. `tb_writeStoredValue(field, reason)` — capture `previous` before writing, emit `update` after.
   Give `reason` a default (`'set'`) so no existing call site can throw, and pass the real reason from
   each of the four call sites (§3.1).
2. `tb_addTag()` — emit `add` before the `update`, and emit `reject` at both existing `tb_alert()`
   sites, carrying the machine-readable reason. `tb_validatePreparedTag()` should return
   `{ code, message }` instead of a bare string so the code is not re-derived by matching on English
   text; keep a string-compatible shape or update both call sites.
3. Remove handler — emit `remove` before the `update`.
4. `tb_initializeSortable()` `sortupdate` — emit `sort` before the `update`.
5. Initializer — record whether the parsed value was a legacy comma migration, emit `init`
   (+ deferred flush per §4.4).
6. `tb_showInitializationError()` — emit `error`.
7. Keep `tagBuilderDebug` console output as-is.

Guard every emit so a host exception cannot break the builder: wrap the dispatch in `try/catch` and,
when `tagBuilderDebug` is on, log the failure.

---

## 6. Compatibility

- Purely additive. No existing option, attribute, markup contract or behavior changes.
- No renames, so nothing that works on 0.2.0 stops working.
- Version bump to **0.3.0** in `version.json`, `package.json`, and the `/* v0.2.0 */` header comment
  in `js/tag-list-builder.js` (the dist copy carries the same header).
- `build.ps1` copies source → dist (note the rename: `js/tag-list-builder.js` → `dist/js/tag-builder.js`);
  `build.ps1 -Check` must pass.

---

## 7. Documentation

Add an **Extension API / Events** section to `README.md` covering:

- the event table (§4.1), the payload shape, and the ordering guarantee (§4.2);
- that events are native `CustomEvent`s that bubble, with the working jQuery access pattern (§4.3);
- the init-timing rule that results from §4.4;
- a worked example — a host validating values on `tagBuilder:update` and rendering its own message on
  `tagBuilder:reject` — which is the SDM alias case and the reason this exists;
- a short note that events are for integration, **not** authorization: the existing warning that
  applications must re-validate on the server applies unchanged.

---

## 8. Testing

Extend `tests/browser-smoke.html` (it already covers jQuery 4 init, typeahead init, safe text
rendering, JSON migration, comma output and readonly). Add:

| Case | Asserts |
|---|---|
| Add a tag | `add` then `update`, `reason: 'add'`, `values` includes it, `serialized` matches the field |
| Remove a tag | `remove` then `update`, `reason: 'remove'`, `previous` still has it |
| Reorder (sorting enabled) | `sort` then `update`, `values` in the new order |
| Init from JSON | one `init`, `migrated: false` |
| Init from a legacy comma value | `init` with `migrated: true`, and the field already rewritten as JSON |
| Each rejection | `reject` with the right `reason` code for empty, control chars, `maxTagLength`, `maxTags`, duplicate, and comma-in-comma-mode |
| Bad `data-fieldvalue` | `error` with a message; the field still renders its empty state |
| Listener bound in a later `$(function(){})` | still receives `init` (the §4.4 fix) |
| Native `addEventListener` on the field | receives the same events with `detail` intact |
| Listener throws | the builder still adds/removes the tag |
| Two builders on one page | events carry the right `fieldId` and do not cross-fire |
| Readonly field | no `add` / `remove` / `sort` events |

Plus the manual checks from `AGENTS.md` (`index.html`, `index.cfm` four variants, sorted order,
typeahead), since `index.cfm` and `index.html` both define the contract.

---

## 9. Open questions

1. **Init timing** — confirm the deferred flush (§4.4, option 1).
2. **`detail` through jQuery 4** — verify `event.detail` vs `event.originalEvent.detail` and document
   the one that works.
3. **Suppressing the built-in alert** — should a host that handles `tagBuilder:reject` be able to stop
   the Bootbox alert (`preventDefault()`, or a `data-suppressalerts` attribute)? SDM wants inline
   errors, not a modal, so this will come up immediately.
4. **`tb_validatePreparedTag()` return shape** — change it to `{ code, message }`, or keep the string
   and map to codes at the emit site?
5. **Imperative API (§4.5)** — included in 0.3.0.
6. **Event name prefix** — `tagBuilder:` matches what the old SDM integration used and reads well;
   confirm before it becomes public API and hard to change.
7. **Vanilla build** — commit now to the same event names and payloads for the planned vanilla
   implementation (`_notes/plans/future-enhancements.md`), so the contract is implementation-neutral.

---

## 10. Phases

1. `tb_emit()` + `tagBuilder:update` from `tb_writeStoredValue()` with a real `reason` from all four
   call sites. *(This alone unblocks the SDM integration.)*
2. `add`, `remove`, `sort`, `init`, `error`, plus the init-timing fix.
3. `reject` with machine-readable reason codes, and the §9.3 alert decision.
4. README section, smoke-test coverage, `dist/` sync, version bump to 0.3.0.
5. Imperative API (§4.5).
