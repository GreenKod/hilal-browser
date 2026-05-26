# Hilal Privacy Levels

> **Note:** The privacy‑level UI is now provided via a *prefs overlay* (`prefs/browser/components/preferences/hilal.inc.xhtml`). The original `0013‑hilal‑privacy‑levels.patch` has been removed from the series; the same UI is injected at build time.

Hilal privacy levels are hardening profiles, not anonymity promises. They are
designed to move Hilal toward LibreWolf-style defaults while keeping the tradeoffs
visible to users.

## What Hilal Does Not Claim

- Hilal does not hide your public IP address.
- Hilal does not replace Tor Browser.
- Hilal does not make every website anonymous.
- Hilal does not guarantee that all fingerprinting is impossible.
- Hilal does not guarantee site compatibility at stricter levels.

## Balanced (LibreWolf-like)

This is the default level. It enables strict tracking protection, Resist
Fingerprinting, HTTPS-only mode, URL query stripping, WebGL blocking, safer
referrer handling, disk-cache reduction, search/form suggestion reduction, and
cookie/cache cleanup on shutdown.

WebRTC remains enabled for compatibility, but local host candidates are reduced
and proxy-aware behavior is enabled where Firefox supports it.

Expected breakage:
- Some sites may ask for canvas or fingerprinting-related access.
- Some sites may behave differently because WebGL is disabled.
- Saved passwords and form autofill are disabled.
- Sessions may not persist because cookies/storage are cleared on close.

## Strict

Strict includes Balanced and additionally enables First Party Isolation and
disables WebRTC entirely.

Expected breakage:
- Video calls and peer-to-peer web apps may fail.
- Some login and embedded flows may break because of stronger isolation.

## Maximum Local Hardening

Maximum includes Strict and additionally disables JavaScript, blocks camera,
microphone, and location by default, disables browsing history, and clears
browsing history/download history on close.

Expected breakage:
- Many modern websites will not work.
- Account dashboards, checkout flows, maps, media sites, and web apps may fail.

## LibreWolf Alignment Notes

LibreWolf documents these relevant defaults and goals:

- Strict Tracking Protection and uBlock Origin.
- Native URL tracking parameter stripping.
- dFPI / Total Cookie Protection.
- Resist Fingerprinting.
- WebGL disabled as a fingerprinting vector.
- Referrer trimming.
- Search and form history disabled.
- Link prefetching and speculative connections disabled.
- HTTPS-only mode.
- PDF scripting disabled.
- Telemetry disabled.
- No claim that the browser hides public IP; Tor Browser is recommended when
  anonymity is the goal.

Hilal should use the same style of public language: clear, limited, and specific.
