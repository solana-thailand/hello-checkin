---
name: dioxus-web-on-workers
description: Serve a Dioxus web (WASM) app from Cloudflare Workers static assets, with a small Worker only for the API, on the free plan.
depends-on: dioxus
---

# A Dioxus web app on Cloudflare Workers

Learned on ktv-rs (Dioxus 0.7.1 web, in production at ktv-rs.solana-thailand.workers.dev; Solana Developer
Thailand). For the bundle size and page-shift rules, see the `cloudflare-wasm-dapp` skill.

## Assets first, the Worker only for the API

Build the web app into a directory (`dx build` output, e.g. `./dist`) and let Workers static assets serve it.
Run the Worker only for API paths:

```jsonc
"assets": {
  "directory": "./dist",
  "not_found_handling": "single-page-application",  // client-side routes fall back to index.html
  "run_worker_first": ["/api/*"]                     // everything else never wakes the Worker
}
```

## State per room, on the free plan

Keep shared live state (for example a phone remote for one screen) in one Durable Object per room. On the
Workers Free plan, declare it as a SQLite-backed class:

```jsonc
"durable_objects": { "bindings": [{ "name": "ROOM", "class_name": "Room" }] },
"migrations": [{ "tag": "v1", "new_sqlite_classes": ["Room"] }]
```

## Hashed asset names

The Dioxus build emits hashed file names (`app_bg-dxh….wasm`), loaded by `app-dxh….js`. To measure what users
download, follow the JS loader to the wasm; the HTML does not reference it directly.
