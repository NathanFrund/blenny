"
I am the HTTP request router for Blenny.

I handle:
- Routing HTTP requests to handlers
- WebSocket upgrade requests
- Static file serving
- Module-registered routes
- Authentication via cookie/URL token

Routes are checked in this order:
1. Module-registered routes (registerGet:/registerPost:)
2. WebSocket (/ws/*)
3. Static files (/static/*)
4. Home (/)
5. Login/Register/Logout
6. 404
"
Class {
	#name : 'BlennyRouter',
	#superclass : 'Object',
	#instVars : [
		'rootPath',
		'renderer',
		'htmlBridge',
		'dataBridge',
		'loginHandler',
		'logoutHandler',
		'registerHandler',
		'routes',
		'globalMiddleware'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

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

{ #category : 'accessing' }
BlennyRouter >> dataBridge [
	^ dataBridge
]

{ #category : 'accessing' }
BlennyRouter >> dataBridge: aBridge [
	dataBridge := aBridge 
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
	Transcript show: 'Router extractTokenFrom called'; cr.
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
	
	"1. Check module-registered routes first"
    routes do: [ :route |
        (path = (route at: 'path') and: [ request method = (route at: 'method') ]) ifTrue: [
            ^ self ensureResponse: ((route at: 'handler') value: request) ] ].

	"2. WebSocket and static routes (direct handlers)"
	(path beginsWith: '/ws/') ifTrue: [ ^ self handleWebSocket: request ].
	(path beginsWith: '/static/') ifTrue: [ ^ self handleStatic: request ].

	"3. Home route"
	(path = '/' or: [ path isEmpty ]) ifTrue: [
			^ self ensureResponse:
				  (renderer renderPage: 'index' context: Dictionary new) ].

	"4. Login routes"
	(path = '/login' and: [ request method = #GET ]) ifTrue: [
		^ self ensureResponse: (loginHandler handleGet: request) ].
	(path = '/login' and: [ request method = #POST ]) ifTrue: [
		^ self ensureResponse: (loginHandler handlePost: request) ].

	"5. Register routes"
	(path = '/register' and: [ request method = #GET ]) ifTrue: [
		^ self ensureResponse: (registerHandler handleGet: request) ].
	(path = '/register' and: [ request method = #POST ]) ifTrue: [
		^ self ensureResponse: (registerHandler handlePost: request) ].

	"6. Logout route - accept GET or POST"
	(path = '/logout' and: [
		 request method = #GET or: [ request method = #POST ] ]) ifTrue: [
		^ self ensureResponse: (logoutHandler handlePost: request) ].

	"7. 404"
	^ ZnResponse notFound: path
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
    | token userId wsType bridge |
    
    wsType := (request uri segments size > 1 and: [ request uri segments second isString ])
        ifTrue: [ request uri segments second ]
        ifFalse: [ 'html' ].
    
    token := self extractTokenFrom: request.
    token ifNil: [ ^ ZnResponse unauthorized: 'Missing token' ].
    
    userId := loginHandler authProvider validateToken: token.
    userId ifNil: [ ^ ZnResponse unauthorized: 'Invalid token' ].
    
    ((request headers at: 'Upgrade' ifAbsent: [ '' ]) asLowercase includesSubstring: 'websocket')
        ifFalse: [ ^ ZnResponse badRequest: request ].
    
    bridge := wsType = 'html' ifTrue: [ htmlBridge ] ifFalse: [ dataBridge ].
    bridge ifNil: [ ^ ZnResponse serverError: 'Bridge not configured' ].
    
    ^ (ZnWebSocketDelegate handler: [ :webSocket |
        bridge handleWebSocket: webSocket forUser: userId ]) 
        handleRequest: request
]

{ #category : 'accessing' }
BlennyRouter >> htmlBridge [
	^ htmlBridge
]

{ #category : 'accessing' }
BlennyRouter >> htmlBridge: aBridge [
	htmlBridge := aBridge
]

{ #category : 'initialization' }
BlennyRouter >> initializeWith: aDictionary [

	renderer := aDictionary at: 'renderer'.
	loginHandler := aDictionary at: 'loginHandler'.
	registerHandler := aDictionary at: 'registerHandler'.
	logoutHandler := aDictionary at: 'logoutHandler'.
	htmlBridge := aDictionary at: 'htmlBridge'.
	dataBridge := aDictionary at: 'dataBridge'.
	rootPath := aDictionary at: 'rootPath' ifAbsent: [ nil ].
	routes := OrderedCollection new.
	globalMiddleware := OrderedCollection new.
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

{ #category : 'middleware' }
BlennyRouter >> use: aMiddleware [
    "Add global middleware"
    globalMiddleware add: aMiddleware.
]
