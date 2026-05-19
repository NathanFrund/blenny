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
    connectionsByUserId ifNotNil: [
        userDict := connectionsByUserId at: userId ifAbsent: [ nil ].
        userDict ifNotNil: [
            userDict removeKey: connectionId ifAbsent: [].
            userDict ifEmpty: [ connectionsByUserId removeKey: userId ] ] ].
    stream ifNotNil: [
        stream close.
        stream := nil ]
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
