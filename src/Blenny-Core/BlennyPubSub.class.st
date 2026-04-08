Class {
	#name : 'BlennyPubSub',
	#superclass : 'Object',
	#instVars : [
		'subscriptions',
		'announcer'
	],
	#classInstVars : [
		'Current'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'accessing' }
BlennyPubSub class >> current [
    ^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
BlennyPubSub >> announcer [
    ^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'initialization' }
BlennyPubSub >> initialize [
    super initialize.
    subscriptions := Dictionary new.
]

{ #category : 'publishing' }
BlennyPubSub >> publish: aTopic with: aString [
    (subscriptions at: aTopic ifAbsent: [ ^ self ]) do: [ :socket |
        [ socket send: aString ] on: Error do: [ :ex |
            self unsubscribe: socket from: aTopic ] ].
]

{ #category : 'as yet unclassified' }
BlennyPubSub >> publishDataBroadcast: aString [
    "Publish JSON to all data clients"
    self announcer announce: (BlennyDataBroadcast payload: aString)
]

{ #category : 'as yet unclassified' }
BlennyPubSub >> publishDataDirect: aString toUser: aUserId [
    "Publish JSON directly to a specific user"
    self announcer announce: (BlennyDataDirect payload: aString toUser: aUserId)
]

{ #category : 'as yet unclassified' }
BlennyPubSub >> publishHtmlBroadcast: aString [
    "Publish HTML to all HTML clients"
    self announcer announce: (BlennyHTMLBroadcast payload: aString)
]

{ #category : 'as yet unclassified' }
BlennyPubSub >> publishHtmlDirect: aString toUser: aUserId [
    "Publish HTML directly to a specific user"
    self announcer announce: (BlennyHTMLDirect payload: aString toUser: aUserId)
]

{ #category : 'subscribing' }
BlennyPubSub >> subscribe: aWebSocket to: aTopic [
    (subscriptions at: aTopic ifAbsentPut: [ OrderedCollection new]) add: aWebSocket.
]

{ #category : 'unsubscribing' }
BlennyPubSub >> unsubscribe: aWebSocket from: aTopic [
    (subscriptions at: aTopic ifAbsent: [ ^ self ]) remove: aWebSocket ifAbsent: [].
]
