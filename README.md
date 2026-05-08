# Blenny

<p align="center">
  <img src="BlennyMascot.svg" alt="Blenny Mascot" width="250">
</p>

**Bringing the legendary live-coding productivity of Pharo to the modern, real-time web.**

Blenny is a real-time web framework for Pharo that combines **Server‑Sent Events**, optional WebSockets, HTMX, JWT authentication, and a modular architecture. 

Build reactive applications with minimal effort and maximum reliability.

## Features

- **SSE‑first by default** – resilient, auto‑reconnecting, browser‑native push with zero custom JavaScript
- **Pluggable transport encoders** – plain SSE for HTMX / vanilla, or Datastar for hypermedia gloss
- **Optional WebSockets** – enable bidirectional channels when you need them
- **HTMX integration** – build interactive UIs without writing JavaScript
- **JWT authentication** – stateless, secure, configurable sessions
- **Pluggable modules** – auto‑discovered, zero‑configuration modules
- **Multi‑layer config** – embedded defaults, file (blenny.json), env, and command line
- **Anti‑Fragile Middleware** – strict response contract prevents server‑side crashes
- **Template rendering** – Mustache templates with hot reload (Conduit)
- **BlennyPublisher** – any Pharo object can push real‑time updates with one line of code

## The Blenny Philosophy

Blenny is designed so that **business logic doesn't need to know about the transport layer**. 

Whether you're responding to an HTTP GET, an HTMX fragment request, or pushing a real-time update over WebSocket, the code remains the same.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Browser (HTMX / Datastar)                  │
│                 SSE connection always active                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Middleware Pipeline                     │
│         (Logging → Auth → Security → Rate Limiting)         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        BlennyRouter                         │
│      (Routes → SSE handler → Module Dispatcher → 404)       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    BlennyTransportBridge                    │
│         (BlennySSEBridge / BlennyWebSocketBridge)           │
│            Encoder strategy plugs in at runtime             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    TBlennyModule (Trait)                    │
│          (Auth helper, ZnResponse wrapping, HTMX)           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Your Module Handler                     │
│                    (Pure business logic)                    │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### Installation

```smalltalk
Metacello new
    baseline: 'Blenny';
    repository: 'github://NathanFrund/Blenny:main/src';
    onConflict: [ :ex | ex useIncoming ];
    onUpgrade: [ :ex | ex useIncoming ];
    load.
```
### Loading the Datastar Plugin (optional)

If you want the richer hypermedia events (`datastar-patch-elements`, `datastar-merge-signals`), include the `Datastar` group when installing Blenny:

```smalltalk
Metacello new
    baseline: 'Blenny';
    repository: 'github://NathanFrund/Blenny:main/src';
    onConflict: [ :ex | ex useIncoming ];
    onUpgrade: [ :ex | ex useIncoming ];
    load: 'Datastar'.
```

Make sure you set `sse.encoder` as outlined below.   

### Start a server

```smalltalk
"Start the server (default port 8081)"
app := BlennyWebApp new.
app startOn: nil port: 8081.

"Broadcast to all connected clients"
BlennyPublisher broadcastHtml: '<div class="alert">Hello world!</div>'

"Direct message to a specific user"
BlennyPublisher directHtml: '<div>Private message</div>' toUser: 'alice'
```

### Enable WebSockets (optional)

```smalltalk
app enableWebSocketsWithDefaultIntents: #(all).
```

This creates two endpoints:

* `/ws/html` - sends raw HTML (HTMX-ready)
* `/ws/data` - sends the full message dictionary as JSON

Clients connect exactly like they would in Blenny's previous WebSocket-only era, but now WebSockets are entirely opt-in. 

Without the call above, `/ws/*` returns a 404.

### Create a module

```smalltalk
Object subclass: #DashboardModule
    uses: TBlennyModule

DashboardModule >> registerRoutesOn: aRouter
    aRouter registerGet: '/dashboard' handler: [ :req |
        self handleDashboard: req ].

DashboardModule >> handleDashboard: request
    | user |
    "The Trait provides the user and handles the redirect if missing"
    user := self authenticatedUserFrom: request.
    user ifNil: [ ^ ZnResponse redirect: '/login' ].

    "The Trait automatically detects if this is an HTMX request
     and wraps the result in a proper ZnResponse object"
    ^ self renderPage: 'dashboard'
        context: { 'username' -> user } asDictionary
        request: request
```

## Connection Intents

Each real‑time connection can subscribe to one or more **intents** – categories of messages
it wants to receive. Clients specify their intents via the `?intent=` query parameter
(comma‑separated). Available intents:

- `ui` – HTML fragments and signal updates intended for DOM patches
- `command` – bidirectional request/response traffic (e.g., WebSocket API calls)
- `notification` – system alerts, toasts, or other notification‑style messages
- `all` – receive every message, regardless of category

**Defaults per endpoint**

| Endpoint | Default intents | Behavior |
|----------|----------------|----------|
| `/sse` | `ui` | Receives only UI updates unless overridden |
| `/ws/html`, `/ws/data` | `all` | Backward‑compatible – receives everything |

**Examples**

`/sse` → UI updates only 

`/sse?intent=ui,notification` → UI updates and notifications

`/ws/html?intent=command` → only command‑category messages

`/ws/data?intent=all` → everything (explicit default)

A single user can open multiple connections with different intents (e.g., an SSE stream
for live UI patches and a WebSocket for chat commands) without receiving duplicate updates.

**Publishing with a custom category**

Every message you publish carries a `#category` key. To target a specific intent group,
include the matching category. For example, to send a Datastar script (which will be
delivered as a `datastar-execute-script` event) only to connections subscribed to
`command`:

```smalltalk
BlennyPublisher publishMessage: {
    #script -> 'console.log("Ran command!")'.
    #category -> #command
} asDictionary toUser: 'alice'.
```

The intent filter acts before the encoder, so you can use this pattern with any payload
(HTML, signals, scripts) and any transport.

## SSE and Encoders
Blenny ships with a **brand‑neutral standard encoder** that produces plain SSE (event: message), compatible with HTMX and vanilla EventSource.

To switch to **Datastar** (rich hypermedia events), set the sse.encoder key in your blenny.json:

```json
{
  "sse.encoder": "DatastarSSEEncoder"
}
```

The Datastar‑Pharo‑SDK is loaded automatically when you include the `Blenny-Datastar` package or the `Datastar` group in your Metacello load.

The core framework remains completely independent of Datastar – it’s a first‑class opt‑in.

## Configuration

Create `blenny.json` in your working directory. The file only needs to contain the values you want to override; everything else falls back to the embedded defaults.

```json
{
  "server.port": "8080"
}
```

The configuration system now uses a **composite provider** that automatically merges sources in this order:

1. Command line arguments
2. Environment variables
3. `blenny.json`
4. Embedded defaults

A key missing from a higher-priority source automatically falls through to the next one.

No more duplication.

## Logging

Blenny uses **Beacon** for all runtime logging. By default, log entries are written to `logs/blenny-YYYYMMDD.log` in the image directory.

## Documentation

- [Authentication](https://github.com/NathanFrund/blenny/wiki/Authentication) - JWT setup, session duration, blacklist
- [Modules](https://github.com/NathanFrund/blenny/wiki/Modules) - Creating modules, routes, publishing
- [Middleware](https://github.com/NathanFrund/blenny/wiki/Middleware) - Logging, rate limiting, security headers
- [WebSockets](https://github.com/NathanFrund/blenny/wiki/WebSockets) - Broadcast, direct messages, HTMX
- [Configuration](https://github.com/NathanFrund/blenny/wiki/Configuration) - Multi-layer config system

## Requirements

- Pharo 13+
- Dependencies managed automatically via Metacello:
  - Zinc HTTP Components
  - JSONWebToken (for JWT support)
  - Conduit (for template rendering)
  - Datastar-Pharo-SDK (optional, for Datastar encoder)

## Why Pharo?

Pharo offers live object-oriented programming, hot code reloading, and a pure object environment. Blenny brings these strengths to web development, allowing you to build and debug real-time applications.

## Why the name Blenny?

Inspired by [Goby](https://github.com/NathanFrund/Goby) (my Go web framework), Blenny is its smaller, friendlier cousin. It is named after the tailspot blenny, a small, curious fish that is always watching the reef.

## License

MIT License

Copyright (c) 2026 Nathan Frund

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
