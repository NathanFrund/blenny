Class {
	#name : 'BlennyPubSub',
	#superclass : 'Object',
	#instVars : [
		'subscriptions'
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

{ #category : 'subscribing' }
BlennyPubSub >> subscribe: aWebSocket to: aTopic [
    (subscriptions at: aTopic ifAbsentPut: [ OrderedCollection new]) add: aWebSocket.
]

{ #category : 'unsubscribing' }
BlennyPubSub >> unsubscribe: aWebSocket from: aTopic [
    (subscriptions at: aTopic ifAbsent: [ ^ self ]) remove: aWebSocket ifAbsent: [].
]
