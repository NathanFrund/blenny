"
I am the HTTP request router for Blenny (SSE‑first, WebSocket‑optional).

I handle:
- Routing HTTP requests to handlers
- Server‑Sent Events (/sse) – always available
- WebSocket upgrade requests – only if WebSockets are enabled
- Static file serving
- Module-registered routes
- Authentication via cookie/URL token

Routes are checked in this order:
1. Module-registered routes
2. SSE (/sse)
3. WebSocket (/ws/*) – conditional
4. Static files (/static/*)
5. Home (/)
6. Login/Register/Logout
7. 404

I rely on the BlennyWebApp reference to access the current transports.
"
Class {
	#name : 'BlennyRouter',
	#superclass : 'Object',
	#instVars : [
		'rootPath',
		'renderer',
		'app',
		'routes',
		'globalMiddleware'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'accessing' }
BlennyRouter >> app [
   ^ app
]

{ #category : 'middleware' }
BlennyRouter >> applyGlobalMiddlewareTo: aBlock [
    | wrapped |
    wrapped := aBlock.
    globalMiddleware reverseDo: [ :mw | 
        | previousHandler |
        "This temporary variable captures the state for THIS specific closure"
        previousHandler := wrapped. 
        wrapped := [ :req | mw value: previousHandler value: req ] ].
    ^ wrapped
]

{ #category : 'authentication' }
BlennyRouter >> ensureResponse: anObject [
    anObject ifNil: [ ^ ZnResponse serverError: 'Empty response from handler' ].
    (anObject isKindOf: ZnResponse) ifTrue: [ ^ anObject ].
    (anObject isString) ifTrue: [ ^ ZnResponse ok: (ZnEntity html: anObject) ].
    ^ ZnResponse serverError: 'Handler returned invalid response type'

]

{ #category : 'authentication' }
BlennyRouter >> extractTokenFrom: request [
    "Extract JWT token from URL or cookie"
    | token |
    token := request uri queryAt: 'token' ifAbsent: [ nil ].
    token ifNil: [ token := BlennyMiddleware extractTokenFromCookie: request ].
    ^ token
]

{ #category : 'handlers' }
BlennyRouter >> handleNotFound: request [
    ^ ZnResponse notFound: request uri pathPrintString
]

{ #category : 'handlers' }
BlennyRouter >> handleRequest: request [
   | path |
   path := request uri pathPrintString.

   "1. Module-registered routes"
   routes do: [ :route |
      (path = (route at: 'path') and: [ request method = (route at: 'method') ]) ifTrue: [
         ^ self ensureResponse: ((route at: 'handler') value: request) ] ].

   "2. SSE endpoint – always available"
   (path beginsWith: '/sse') ifTrue: [ ^ self handleSSE: request ].

   "3. WebSocket endpoint – only if WebSocket bridge is enabled"
   (path beginsWith: '/ws') ifTrue: [ ^ self handleWebSocket: request ].

   "4. Static files"
   (path beginsWith: '/static/') ifTrue: [ ^ self handleStatic: request ].

   "5. Home"
   (path = '/' or: [ path isEmpty ]) ifTrue: [
      ^ self ensureResponse: (renderer renderPage: 'index' context: Dictionary new) ].

   "9. 404"
   ^ ZnResponse notFound: path
]

{ #category : 'handlers' }
BlennyRouter >> handleSSE: request [
   | userId intents bridge entity response |
   
   "Ask BlennyWebApp instance to validate the token"
   userId := app authProvider validateToken: (self extractTokenFrom: request).
   userId ifNil: [ ^ ZnResponse unauthorized: 'Invalid or missing token' ].
   
   intents := self intentsFromRequest: request defaults: #(ui).
   bridge := self sseBridge.

   entity := BlennyLiveEntity updateBlock: [ :socketStream |
      self runSSEStream: socketStream forUser: userId withBridge: bridge intents: intents.
   ].

   response := ZnResponse ok: entity.
   response headers
      at: 'Content-Type' put: 'text/event-stream; charset=utf-8';
      at: 'Cache-Control' put: 'no-cache';
      at: 'Connection' put: 'keep-alive'.
   ^ response

]

{ #category : 'handlers' }
BlennyRouter >> handleStatic: request [
    | path segments diskFile |
    path := request uri pathPrintString.
    segments := request uri segments asArray.
    diskFile := segments allButFirst
        inject: rootPath asFileReference
        into: [ :parent :segment | parent / segment ].
    
    diskFile exists ifTrue: [
        ^ ZnResponse ok: (ZnEntity
            with: diskFile binaryReadStream contents
            type: (ZnMimeType forFilenameExtension: diskFile extension)) ].
    
    ^ ZnResponse notFound: path
]

{ #category : 'handlers' }
BlennyRouter >> handleWebSocket: request [

	| path token userId bridge intents handlerBlock |
	path := request uri pathPrintString.
	path ~= '/ws' ifTrue: [ ^ ZnResponse notFound: path ].

	token := self extractTokenFrom: request.
	token ifNil: [ ^ ZnResponse unauthorized: 'Missing token' ].
	userId := app authProvider validateToken: token.
	userId ifNil: [ ^ ZnResponse unauthorized: 'Invalid token' ].

	((request headers at: 'Upgrade' ifAbsent: [ '' ]) asLowercase
		 includesSubstring: 'websocket') ifFalse: [
		^ ZnResponse badRequest: request ].

	bridge := app transportNamed: 'ws'.
	bridge ifNil: [ ^ ZnResponse notFound: 'WebSocket not enabled' ].

	intents := self intentsFromRequest: request defaults: #( all ).

	handlerBlock := [ :webSocket |
		| handle |
		handle := bridge
			registerUser: userId
			stream: webSocket
			intents: intents.
		[
			[
				[
					webSocket runWith: [ :msg |
						StringSignal emit: ('WS received from {1}: {2}' format: {
							userId.
							msg asString }) ]
				] on: ConnectionClosed, SocketError do: [ :ex |
					"Normal drop - exit cleanly"
				]
			] on: Error do: [ :ex |
				"Log legitimate bugs to terminal without popping up UI windows"
				Stdio stderr nextPutAll: 'WS Unexpected Error: ' , ex description; cr.
			]
		] ensure: [
			"Execute defensively. If an error occurs during termination cleanup, ignore it."
			[ handle finalize ] on: Exception do: [ :ex | ].
			[ webSocket close ] on: Exception do: [ :ex | ]
		]
	].

	"We use a separate background execution context for the delegate so it doesn't run on the main listener"
	^ (ZnWebSocketDelegate handler: handlerBlock) handleRequest: request
]

{ #category : 'initialization' }
BlennyRouter >> initializeWith: aDictionary [
   renderer := aDictionary at: 'renderer'.
   app := aDictionary at: 'app'.               "Reference to the BlennyWebApp"
   rootPath := aDictionary at: 'rootPath' ifAbsent: [ nil ].
   routes := OrderedCollection new.
   globalMiddleware := OrderedCollection new.
]

{ #category : 'handlers' }
BlennyRouter >> intentsFromRequest: request defaults: aCollection [
   ^ (request uri queryAt: 'intent' ifAbsent: [ nil ])
      ifNotNil: [ :s | (s substrings: ',') collect: #asSymbol ]
      ifNil: [ aCollection ]
]

{ #category : 'module-registration' }
BlennyRouter >> registerGet: aPath handler: aBlock [
    | wrappedHandler |
    wrappedHandler := self applyGlobalMiddlewareTo: aBlock.
    routes add: { 
        'method' -> #GET. 
        'path' -> aPath. 
        'handler' -> wrappedHandler 
    } asDictionary.
]

{ #category : 'module-registration' }
BlennyRouter >> registerPost: aPath handler: aBlock [
    | wrappedHandler |
    wrappedHandler := self applyGlobalMiddlewareTo: aBlock.
    routes add: { 
        'method' -> #POST. 
        'path' -> aPath. 
        'handler' -> wrappedHandler 
    } asDictionary.
]

{ #category : 'accessing' }
BlennyRouter >> rootPath: aRootPath [

rootPath := aRootPath 
]

{ #category : 'accessing' }
BlennyRouter >> routes [ 
	^ routes.
]

{ #category : 'handlers' }
BlennyRouter >> runSSEStream: socketStream forUser: userId withBridge: bridge intents: intents [
    | handle |
    handle := bridge registerUser: userId stream: socketStream intents: intents.
    [
        "Give the client a moment to be ready for signals"
        (Delay forMilliseconds: 100) wait.

        bridge
            directMessage: (Dictionary new
                at: #signals put: { #connected -> true } asDictionary;
                at: #category put: #ui;
                yourself)
            to: userId.

        "Idle forever: Datastar holds the connection; a periodic comment prevents proxy timeouts"
        [ true ] whileTrue: [
            (Delay forSeconds: 15) wait.
            socketStream nextPutAll: ': keep-alive'; nextPutAll: String crlf; nextPutAll: String crlf; flush ]
    ] ensure: [
        handle finalize.
    ].
]

{ #category : 'accessing' }
BlennyRouter >> sseBridge [
   "The always‑present SSE bridge"
   ^ app sseBridge
]

{ #category : 'middleware' }
BlennyRouter >> use: aMiddleware [
    "Add global middleware"
    globalMiddleware add: aMiddleware.
]

{ #category : 'accessing' }
BlennyRouter >> wsBridge [
   "The optional WebSocket sidecar, if enabled"
   ^ app optionalTransports
      detect: [ :each | each isKindOf: BlennyWebSocketBridge ]
      ifNone: [ nil ]
]
