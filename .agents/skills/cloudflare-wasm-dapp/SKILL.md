---
name: cloudflare-wasm-dapp
description: Ship a Rust → WebAssembly dApp on Cloudflare Workers without the bundle silently growing, the page shifting, or local previews breaking.
depends-on: worker
---

# A Rust/WASM dApp on Cloudflare Workers

Learned on BeThere (workers-rs `worker` 0.8 + a Leptos CSR frontend) and ktv-rs (Dioxus web), both in production
(Solana Developer Thailand).
Framework-neutral: these hold for any Rust frontend compiled to wasm.

## Measure the bundle the way it is served

- Cloudflare compresses static assets with brotli on the fly at a low quality. Measure the wasm with
  **brotli quality 4**, not 11: on 22 Sep 2026 the served wasm was 1,675,993 bytes; locally q4 gave
  1,646,742 (within 2%) and q11 gave 1,288,797 (28% low). Print q11 too: the gap is what precompressing at
  build time would save. Checked again on a second app (ktv-rs, Dioxus, 8 Oct 2026): served 569,569
  bytes; local q4 570,933 (within 0.3%).
- Gate on **growth against a committed baseline**, not on an invented ceiling. The failure to catch is "nobody
  noticed the bundle grew"; every visitor downloads it, often on mobile data, before they see anything.
- The Worker's own size limit is defined on gzip: measure the worker bundle with gzip, the frontend with brotli.

## Pages that fill in by script

- A section built by script after first paint shifts everything below it (we measured CLS 0.136 on one empty
  state). Ship the final layout as static markup and let script fill only text, or reserve the measured final
  height (both languages, every breakpoint).
- Re-run Lighthouse several times: a shift that depends on whether paint beats the script is intermittent.

## Local previews

- A canvas that draws an image loaded from a `file://` URL is tainted, and `getImageData` throws. If anyone
  opens your pages from disk, inline the image as a data URI.

## D1

- Read prod D1 for numbers through a read-only wrapper that refuses anything but `SELECT`, and print aggregates
  only. A D1 backup `.sql` holds full rows: never print a range of it.
