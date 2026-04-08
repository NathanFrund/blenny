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

{ #category : 'public' }
BlennyRouter >> handleRequest: request [

	| uri path segments |
	uri := request uri.
	path := uri pathPrintString.
	segments := uri segments asArray. "Ensure it's an array"

	"--- WebSocket Routes ---"
	(segments notEmpty and: [ segments first = 'ws' ]) ifTrue: [
			| token userId wsType bridge |
			wsType := (segments size > 1 and: [ segments second isString ])
				          ifTrue: [ segments second ]
				          ifFalse: [ 'html' ].

			"Extract and validate token"
			token := request uri queryAt: 'token' ifAbsent: [ nil ].
			Transcript show: 'Token received: ', (token ifNil: ['NIL']); cr.
			
			userId := self validateToken: token.
			Transcript show: 'UserID from validation: ', (userId  ifNil: ['NIL']); cr.

			userId ifNil: [
					Transcript
						show: 'Authentication failed - invalid token: ' , token;
						cr.
					^ ZnResponse unauthorized: 'Invalid or missing token' ].

			((request headers at: 'Upgrade' ifAbsent: [ '' ]) asLowercase
				 includesSubstring: 'websocket')
				ifTrue: [
						Transcript
							show:
								'WebSocket upgrade - User: ' , userId , ' Type: ' , wsType;
							cr.

						bridge := wsType = 'html'
							          ifTrue: [ htmlBridge ]
							          ifFalse: [ dataBridge ].

						bridge ifNil: [
								Transcript
									show: 'ERROR: Bridge is nil for type: ' , wsType;
									cr.
								^ ZnResponse serverError: 'WebSocket bridge not configured' ].

						^ (ZnWebSocketDelegate handler: [ :webSocket |
							   bridge handleWebSocket: webSocket forUser: userId ])
							  handleRequest: request ]
				ifFalse: [ ^ ZnResponse badRequest: request ] ].


	"--- Home Route ---"
	(path = '/' or: [ segments isEmpty ]) ifTrue: [
			Transcript
				show: 'Matched Home';
				cr.
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

{ #category : 'authentication' }
BlennyRouter >> validateToken: aToken [
    "Simple token validation - replace with database/auth service later"
    aToken ifNil: [ ^ nil ].
    
    aToken = 'alice-token' ifTrue: [ ^ 'alice' ].
    aToken = 'bob-token' ifTrue: [ ^ 'bob' ].
    aToken = 'charlie-token' ifTrue: [ ^ 'charlie' ].
    
    ^ nil
]

{ #category : 'accessing' }
BlennyRouter >> webApp [
	^ webApp 
]

{ #category : 'accessing' }
BlennyRouter >> webApp: aWebApp [
	webApp := aWebApp 
]
