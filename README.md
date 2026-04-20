# Blenny

<p align="center">
  <img src="BlennyMascot.svg" alt="Blenny Mascot" width="250">
</p>

**Bringing the legendary live-coding productivity of Pharo to the modern, real-time web.**

Blenny is a real-time web framework for Pharo that combines WebSockets, HTMX, JWT authentication, and a modular architecture. Build reactive applications with minimal effort and maximum reliability.

## Features

- **Real-time by default** - WebSocket support for HTML and JSON endpoints
- **HTMX integration** - Build interactive UIs without writing JavaScript
- **JWT authentication** - Stateless, secure, configurable sessions
- **Pluggable modules** - Auto-discovered, zero-configuration modules
- **Multi-layer config** - Embedded defaults, file, env, and command line
- **Anti-Fragile Middleware** - Strict response contract prevents server-side crashes from mismatched return types (Strings vs. Objects)
- **Template rendering** - Mustache templates with hot reload (Conduit)
- **BlennyPublisher** - Any Pharo object can push real-time updates with one line of code

## The Blenny Philosophy

Blenny is designed so that **business logic doesn't need to know about the transport layer**. Whether you're responding to an HTTP GET, an HTMX fragment request, or pushing a real-time update over WebSocket, the code remains the same.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Browser (HTMX/WebSocket)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Middleware Pipeline                    │
│         (Logging → Auth → Security → Rate Limiting)         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         BlennyRouter                        │
│              (Routes → Module Dispatcher → 404)             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    TBlennyModule (Trait)                    │
│         (Auth helper, ZnResponse wrapping, HTMX)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Your Module Handler                    │
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

## Configuration

Create `blenny.json` in your working directory:

```json
{
  "server.port": 8081,
  "server.bind_address": "0.0.0.0",
  "auth.jwt_secret": "your-secret-key",
  "auth.session_duration_hours": 720,
  "dev_mode": true
}
```

## Documentation

- [Authentication](docs/authentication.md) - JWT setup, session duration, blacklist
- [Modules](docs/modules.md) - Creating modules, routes, publishing
- [Middleware](docs/middleware.md) - Logging, rate limiting, security headers
- [WebSockets](docs/websockets.md) - Broadcast, direct messages, HTMX
- [Configuration](docs/configuration.md) - Multi-layer config system

## Requirements

- Pharo 13+
- Dependencies managed automatically via Metacello:
  - Zinc HTTP Components
  - JSONWebToken (for JWT support)
  - Conduit (for template rendering)

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

```

```
