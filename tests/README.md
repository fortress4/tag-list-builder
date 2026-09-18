# Browser smoke test

The browser smoke test covers safe tag rendering, JSON serialization, legacy comma-value migration, deprecated comma output, readonly behavior, typeahead initialization, custom events, the imperative JavaScript API, and separate stored values/display labels against the pinned demo dependencies.

Prepare the ignored local dependency cache, serve the repository root over HTTP, and open `tests/browser-smoke.html`:

```powershell
.\tests\prepare-browser-assets.ps1
python -m http.server 8765
```

The page prints a JSON report at the bottom. A successful run ends with `"passed": true`.

When the repository is served through ColdFusion, open `tests/cfml-smoke.cfm` as well. It renders hostile values through the reusable helper and returns a JSON report; `passed` must be true.
