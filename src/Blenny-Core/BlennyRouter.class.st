Class {
	#name : 'BlennyRouter',
	#superclass : 'Object',
	#instVars : [
		'webApp',
		'rootPath',
		'htmlBridge',
		'dataBridge',
		'token',
		'userId'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'as yet unclassified' }
BlennyRouter >> authenticatedUserIdFrom: request [
    "Implement based on your session/auth system"
    "This is a placeholder - replace with your actual auth logic"
    | session |
    session := request cookieAt: 'session' ifAbsent: [ ^ nil ].
    "Validate session and return user ID"
    ^ session  "Return user ID or nil"
]

{ #category : 'accessing' }
BlennyRouter >> dataBridge [
	^ dataBridge
]

{ #category : 'accessing' }
BlennyRouter >> dataBridge: aBridge [
	dataBridge := aBridge 
]

{ #category : 'handlers' }
BlennyRouter >> handleHome: request [
    Transcript show: 'Matched Home'; cr.
    ^ ZnResponse ok: (ZnEntity html: (webApp renderPage: 'index'))
]

{ #category : 'handlers' }
BlennyRouter >> handleLogin: request [
    | query username password sessionId |
    
    Transcript show: '=== LOGIN START ==='; cr.
    
    query := request uri query.
    Transcript show: 'Query: ', query asString; cr.
    
    username := query at: 'username' ifAbsent: [ nil ].
    Transcript show: 'Username: ', (username ifNil: ['NIL']); cr.
    
    password := query at: 'password' ifAbsent: [ nil ].
    Transcript show: 'Password: ', (password ifNil: ['NIL']); cr.
    
    username ifNil: [ 
        Transcript show: 'Missing username'; cr.
        ^ ZnResponse statusCode: 400 ].
    password ifNil: [ 
        Transcript show: 'Missing password'; cr.
        ^ ZnResponse statusCode: 400 ].
    
    Transcript show: 'Calling authenticate...'; cr.
    sessionId := webApp authProvider authenticate: username password: password.
    Transcript show: 'SessionId result: ', (sessionId ifNil: ['NIL']); cr.
    
    sessionId ifNil: [ 
        Transcript show: 'Authentication failed'; cr.
        ^ ZnResponse statusCode: 401 ].
    
    Transcript show: 'Returning session ID'; cr.
    ^ ZnResponse ok: (ZnEntity text: sessionId)
]

{ #category : 'handlers' }
BlennyRouter >> handleNotFound: request [
    ^ ZnResponse notFound: request uri pathPrintString
]

{ #category : 'public' }
BlennyRouter >> handleRequest: request [
    | path |
    path := request uri pathPrintString.
    Transcript show: 'Path: ', path; cr.
    
    "Login"
    (path = '/login' and: [ request method = #GET ]) ifTrue: [
        Transcript show: '→ Login'; cr.
        ^ self handleLogin: request ].
    
    "WebSocket"
    (path beginsWith: '/ws/') ifTrue: [
        Transcript show: '→ WebSocket'; cr.
        ^ self handleWebSocket: request ].
    
    "Home"
    (path = '/' or: [ path isEmpty ]) ifTrue: [
        Transcript show: '→ Home'; cr.
        ^ self handleHome: request ].
    
    "Static"
    (path beginsWith: '/static/') ifTrue: [
        Transcript show: '→ Static'; cr.
        ^ self handleStatic: request ].
    
    "404"
    Transcript show: '→ 404'; cr.
    ^ self handleNotFound: request
]

{ #category : 'handlers' }
BlennyRouter >> handleStatic: request [
    | uri path segments diskFile subSegments |
    uri := request uri.
    path := uri pathPrintString.
    segments := uri segments asArray.
    subSegments := segments allButFirst.
    diskFile := subSegments
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
    | segments token userId wsType bridge |
    
    segments := request uri segments asArray.
    wsType := (segments size > 1 and: [ segments second isString ])
        ifTrue: [ segments second ]
        ifFalse: [ 'html' ].
    
    "Extract and validate token"
    token := request uri queryAt: 'token' ifAbsent: [ nil ].
    Transcript show: 'Token received: ', (token ifNil: ['NIL']); cr.
    
    token ifNil: [
        Transcript show: 'Authentication failed - missing token'; cr.
        ^ ZnResponse unauthorized: 'Missing token' ].
    
    userId := webApp authProvider validateToken: token.
    Transcript show: 'UserID from validation: ', (userId ifNil: ['NIL']); cr.
    
    userId ifNil: [
        Transcript show: 'Authentication failed - invalid token: ', token; cr.
        ^ ZnResponse unauthorized: 'Invalid or missing token' ].
    
    ((request headers at: 'Upgrade' ifAbsent: [ '' ]) asLowercase includesSubstring: 'websocket')
        ifFalse: [ ^ ZnResponse badRequest: request ].
    
    Transcript show: 'WebSocket upgrade - User: ', userId, ' Type: ', wsType; cr.
    
    bridge := wsType = 'html'
        ifTrue: [ htmlBridge ]
        ifFalse: [ dataBridge ].
    
    bridge ifNil: [
        Transcript show: 'ERROR: Bridge is nil for type: ', wsType; cr.
        ^ ZnResponse serverError: 'WebSocket bridge not configured' ].
    
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

{ #category : 'accessing' }
BlennyRouter >> rootPath: aRootPath [

rootPath := aRootPath 
]

{ #category : 'authentication' }
BlennyRouter >> validateToken: aToken [
    ^ webApp authProvider validateToken: aToken
]

{ #category : 'accessing' }
BlennyRouter >> webApp [
	^ webApp 
]

{ #category : 'accessing' }
BlennyRouter >> webApp: aWebApp [
	webApp := aWebApp 
]
