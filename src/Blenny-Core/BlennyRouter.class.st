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
		'registerHandler'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'accessing' }
BlennyRouter >> cookieAt: aKey from: request [
    "Extract cookie value from request"
    | cookieHeader cookies |
    cookieHeader := request headers at: 'Cookie' ifAbsent: [ ^ nil ].
    cookies := Dictionary new.
    (cookieHeader splitOn: '; ') do: [ :pair |
        | key value |
        key := (pair copyUpTo: $=).
        value := (pair copyAfter: $=).
        cookies at: key put: value ].
    ^ cookies at: aKey ifAbsent: [ nil ]
]

{ #category : 'accessing' }
BlennyRouter >> dataBridge [
	^ dataBridge
]

{ #category : 'accessing' }
BlennyRouter >> dataBridge: aBridge [
	dataBridge := aBridge 
]

{ #category : 'as yet unclassified' }
BlennyRouter >> ensureResponse: anObject [
    anObject ifNil: [ ^ ZnResponse serverError: 'Empty response from handler' ].
    (anObject isKindOf: ZnResponse) ifTrue: [ ^ anObject ].
    (anObject isString) ifTrue: [ ^ ZnResponse ok: (ZnEntity html: anObject) ].
    ^ ZnResponse serverError: 'Handler returned invalid response type'

]

{ #category : 'as yet unclassified' }
BlennyRouter >> extractTokenFrom: request [
    "Extract JWT token from URL or cookie"
    | token |
    token := request uri queryAt: 'token' ifAbsent: [ nil ].
    token ifNil: [ token := self cookieAt: 'session' from: request ].
    ^ token
]

{ #category : 'handlers' }
BlennyRouter >> handleNotFound: request [
    ^ ZnResponse notFound: request uri pathPrintString
]

{ #category : 'public' }
BlennyRouter >> handleRequest: request [

	| path |
	path := request uri pathPrintString.

	"1. WebSocket and static routes (direct handlers)"
	(path beginsWith: '/ws/') ifTrue: [ ^ self handleWebSocket: request ].
	(path beginsWith: '/static/') ifTrue: [ ^ self handleStatic: request ].

	"2. Home route"
	(path = '/' or: [ path isEmpty ]) ifTrue: [
			^ self ensureResponse:
				  (renderer renderPage: 'index' context: Dictionary new) ].

	"3. Login routes"
	(path = '/login' and: [ request method = #GET ]) ifTrue: [
		^ self ensureResponse: (loginHandler handleGet: request) ].
	(path = '/login' and: [ request method = #POST ]) ifTrue: [
		^ self ensureResponse: (loginHandler handlePost: request) ].

	"4. Register routes"
	(path = '/register' and: [ request method = #GET ]) ifTrue: [
		^ self ensureResponse: (registerHandler handleGet: request) ].
	(path = '/register' and: [ request method = #POST ]) ifTrue: [
		^ self ensureResponse: (registerHandler handlePost: request) ].

	"5. Logout route - accept GET or POST"
	(path = '/logout' and: [
		 request method = #GET or: [ request method = #POST ] ]) ifTrue: [
		^ self ensureResponse: (logoutHandler handlePost: request) ].

	"6. 404"
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
]

{ #category : 'accessing' }
BlennyRouter >> rootPath: aRootPath [

rootPath := aRootPath 
]
