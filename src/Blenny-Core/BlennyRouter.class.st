Class {
	#name : 'BlennyRouter',
	#superclass : 'Object',
	#instVars : [
		'webApp',
		'rootPath',
		'htmlBridge',
		'dataBridge'
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

{ #category : 'public' }
BlennyRouter >> handleRequest: request [
    | uri path segments |
    uri := request uri.
    path := uri pathPrintString.
    segments := uri segments asArray.  "Ensure it's an array"

    "Debug"
    Transcript show: 'Request path: ', path; cr.
    
"--- WebSocket Routes ---"
(segments notEmpty and: [ segments first = 'ws' ]) ifTrue: [
    | userId wsType bridge |
    
    wsType := (segments size > 1 and: [ segments second isString ])
        ifTrue: [ segments second ]
        ifFalse: [ 'html' ].

	bridge := wsType = 'html' 
    ifTrue: [ htmlBridge ]
    ifFalse: [ dataBridge ].

bridge ifNil: [
    Transcript show: 'ERROR: Bridge is nil for type: ', wsType; cr.
    ^ ZnResponse serverError: 'WebSocket bridge not configured' ].
    
    userId := request uri queryAt: 'userId' ifAbsent: [ nil ].
    
    ((request headers at: 'Upgrade' ifAbsent: [ '' ]) asLowercase includesSubstring: 'websocket') 
    ifTrue: [
        Transcript show: 'WebSocket upgrade - User: ', (userId ifNil: ['MISSING']), ' Type: ', wsType; cr.
        
        "Select the appropriate bridge"
        bridge := wsType = 'html' 
            ifTrue: [ htmlBridge ]
            ifFalse: [ dataBridge ].
        
        ^ (ZnWebSocketDelegate handler: [ :webSocket |
            bridge handleWebSocket: webSocket forUser: userId ]) 
            handleRequest: request ]
    ifFalse: [
        ^ ZnResponse badRequest: request ] ].


    "--- Home Route ---"
    (path = '/' or: [ segments isEmpty ]) ifTrue: [
        Transcript show: 'Matched Home'; cr.
        ^ ZnResponse ok: (ZnEntity html: (webApp renderPage: 'index')) ].

    "--- Static Asset Route ---"
    (segments notEmpty and: [ segments first = 'static' ]) ifTrue: [
        | diskFile subSegments |
        subSegments := segments allButFirst.
        diskFile := subSegments
            inject: rootPath asFileReference
            into: [ :parent :segment | parent / segment ].
        
        diskFile exists ifTrue: [
            ^ ZnResponse ok: (ZnEntity
                with: diskFile binaryReadStream contents
                type: (ZnMimeType forFilenameExtension: diskFile extension)) ].
        
        ^ ZnResponse notFound: path ].

    "--- Fallback ---"
    ^ ZnResponse notFound: path
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

{ #category : 'accessing' }
BlennyRouter >> webApp [
	^ webApp 
]

{ #category : 'accessing' }
BlennyRouter >> webApp: aWebApp [
	webApp := aWebApp 
]
