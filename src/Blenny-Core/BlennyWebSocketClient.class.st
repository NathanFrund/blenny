Class {
	#name : 'BlennyWebSocketClient',
	#superclass : 'Object',
	#instVars : [
		'id',
		'userId',
		'endpoint',
		'socket',
		'bridge',
		'isClosed'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'closing' }
BlennyWebSocketClient >> close [
    isClosed ifTrue: [ ^ self ].
    isClosed := true.
    [ socket close ] on: Error do: [ :ex | ].
    bridge unregisterClient: self.
]

{ #category : 'accessing' }
BlennyWebSocketClient >> endpoint [

	^ endpoint
]

{ #category : 'accessing' }
BlennyWebSocketClient >> endpoint: anObject [

	endpoint := anObject
]

{ #category : 'accessing' }
BlennyWebSocketClient >> id [

	^ id
]

{ #category : 'accessing' }
BlennyWebSocketClient >> id: anObject [

	id := anObject
]

{ #category : 'accessing' }
BlennyWebSocketClient >> isClosed [

	^ isClosed
]

{ #category : 'accessing' }
BlennyWebSocketClient >> isClosed: anObject [

	isClosed := anObject
]

{ #category : 'sending' }
BlennyWebSocketClient >> sendMessage: aString [
    isClosed ifTrue: [ ^ self ].
    [ socket sendMessage: aString ]
        on: Error
        do: [ :ex | 
            Transcript show: 'Send failed for ', userId, ': ', ex description; cr.
            self close ]
]

{ #category : 'accessing' }
BlennyWebSocketClient >> socket [
	^ socket 
]

{ #category : 'accessing' }
BlennyWebSocketClient >> userId [

	^ userId
]

{ #category : 'accessing' }
BlennyWebSocketClient >> userId: anObject [

	userId := anObject
]

{ #category : 'initialization' }
BlennyWebSocketClient >> userId: aUserId endpoint: aString socket: aWebSocket bridge: aBridge [
	id := UUID new asString.
	userId := aUserId.
	endpoint := aString.
	socket := aWebSocket.
	bridge := aBridge.
	isClosed := false.
]
