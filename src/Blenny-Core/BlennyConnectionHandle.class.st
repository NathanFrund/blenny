"
I hold the state for a single client connection (SSE or WebSocket).

I manage:
- Unique connection identifier (UUID) for per‑tab targeting
- User ID associated with the connection
- The underlying stream (or WebSocket) for writing
- Intent set (categories the client wants to receive)
- A reference back to the bridge's connections dictionary for cleanup

I am created by BlennyTransportBridge when a client connects.
My #finalize method removes me from the bridge's registry and closes the stream.

Example usage (inside a bridge):

    handle := bridge registerUser: userId stream: socketStream intents: #(ui).
    [
        ... use handle ...
    ] ensure: [ handle finalize ]
"
Class {
	#name : 'BlennyConnectionHandle',
	#superclass : 'Object',
	#instVars : [
		'userId',
		'connectionId',
		'stream',
		'connectionsByUserId',
		'intents'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'accessing' }
BlennyConnectionHandle >> connectionId [

	^ connectionId
]

{ #category : 'accessing' }
BlennyConnectionHandle >> connectionId: anObject [

	connectionId := anObject
]

{ #category : 'accessing' }
BlennyConnectionHandle >> connectionsByUserId [

	^ connectionsByUserId
]

{ #category : 'accessing' }
BlennyConnectionHandle >> connectionsByUserId: anObject [

	connectionsByUserId := anObject
]

{ #category : 'finalization' }
BlennyConnectionHandle >> finalize [
    | userDict |
    "Remove self from the shared per-user dictionary"
    connectionsByUserId ifNotNil: [
        userDict := connectionsByUserId at: userId ifAbsent: [ nil ].
        userDict ifNotNil: [
            userDict removeKey: connectionId ifAbsent: [].
            userDict ifEmpty: [ connectionsByUserId removeKey: userId ] ] ].
    "Close the stream"
    stream ifNotNil: [
        stream close.
        stream := nil ].
]

{ #category : 'accessing' }
BlennyConnectionHandle >> intents [

	^ intents
]

{ #category : 'accessing' }
BlennyConnectionHandle >> intents: anObject [

	intents := anObject
]

{ #category : 'accessing' }
BlennyConnectionHandle >> stream [

	^ stream
]

{ #category : 'accessing' }
BlennyConnectionHandle >> stream: anObject [

	stream := anObject
]

{ #category : 'accessing' }
BlennyConnectionHandle >> userId [

	^ userId
]

{ #category : 'accessing' }
BlennyConnectionHandle >> userId: anObject [

	userId := anObject
]
