"
I am the abstract hub for all real‑time transports in Blenny (SSE, WebSocket, …).

I manage:
  - connection tracking (by user id and connection id)
  - announcement subscription (HTMLBroadcast, HTMLDirect, DataBroadcast, DataDirect)
  - intent‑based filtering (only connections whose intent set matches the message's #category receive it)

My concrete subclasses only need to implement #sendMessage:to: – the actual wire‑level
write for one connection.  Blenny ships with BlennySSEBridge and BlennyWebSocketBridge.

The internal message dictionary is transport‑agnostic and carries the keys #html, #signals, #script, and #category.
"
Class {
	#name : 'BlennyTransportBridge',
	#superclass : 'Object',
	#instVars : [
		'announcer',
		'connectionsByUserId',
		'isRunning',
		'transportName'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'publishing' }
BlennyTransportBridge >> broadcastData: aPayload [
   self broadcastMessage: (Dictionary with: #signals -> aPayload with: #category -> #data)
]

{ #category : 'publishing' }
BlennyTransportBridge >> broadcastHtml: aPayload [
   self broadcastMessage: (Dictionary with: #html -> aPayload with: #category -> #ui)
]

{ #category : 'publishing' }
BlennyTransportBridge >> broadcastMessage: aMessage [
    connectionsByUserId keysAndValuesDo: [ :userId :userDict |
        userDict values do: [ :handle |
            self sendMessageIfIntentsPermit: aMessage to: handle ] ]
]

{ #category : 'accessing' }
BlennyTransportBridge >> connectionsForUserId: aUserId [
    | userDict |
    userDict := connectionsByUserId at: aUserId ifAbsent: [ ^ #() ].
    ^ userDict values
]

{ #category : 'publishing' }
BlennyTransportBridge >> directData: aPayload to: aUserId [
   self directMessage: (Dictionary with: #signals -> aPayload with: #category -> #ui) to: aUserId

]

{ #category : 'publishing' }
BlennyTransportBridge >> directHtml: aPayload to: aUserId [
   self directMessage: (Dictionary with: #html -> aPayload with: #category -> #ui) to: aUserId
]

{ #category : 'publishing' }
BlennyTransportBridge >> directMessage: aMessage to: aUserId [
    (self connectionsForUserId: aUserId) do: [ :handle |
        self sendMessageIfIntentsPermit: aMessage to: handle ]
]

{ #category : 'testing' }
BlennyTransportBridge >> hasConnectionForUser: aUserId [
    ^ (connectionsByUserId at: aUserId ifAbsent: [ #() ]) notEmpty
]

{ #category : 'initialization' }
BlennyTransportBridge >> initialize [
   super initialize.
   connectionsByUserId := Dictionary new.
   isRunning := false.
   transportName := 'transport'
]

{ #category : 'initialization' }
BlennyTransportBridge >> initializeWithName: aString [
   transportName := aString.
   announcer := Announcer new.
   connectionsByUserId := Dictionary new.
   isRunning := true.

   "Subscribe to all existing announcement types"
   announcer
      weak
      when: BlennyHTMLBroadcast
      do: [ :ann | self broadcastHtml: ann payload ]
      for: self.

   announcer
      weak
      when: BlennyHTMLDirect
      do: [ :ann | self directHtml: ann payload to: ann recipientUserId ]
      for: self.

   announcer
      weak
      when: BlennyDataBroadcast
      do: [ :ann | self broadcastData: ann payload ]
      for: self.

   announcer
      weak
      when: BlennyDataDirect
      do: [ :ann | self directData: ann payload to: ann recipientUserId ]
      for: self.

   ^ self
]

{ #category : 'accessing' }
BlennyTransportBridge >> isRunning [
   ^ isRunning
]

{ #category : 'publishing' }
BlennyTransportBridge >> publish: anAnnouncement [
   isRunning ifFalse: [ ^ self ].
   announcer announce: anAnnouncement
]

{ #category : 'as yet unclassified' }
BlennyTransportBridge >> registerUser: aUserId stream: aStream intents: aCollection [
    | handle userDict |
    handle := BlennyConnectionHandle new.
StringSignal emit: ('Registered connection for user {1}, total dict size: {2}' 
    format: { aUserId. connectionsByUserId size }).
    handle
        userId: aUserId;
        connectionId: UUID new asString;
        stream: aStream;
        intents: aCollection asSet;
        connectionsByUserId: connectionsByUserId.
    userDict := connectionsByUserId at: aUserId ifAbsentPut: [ Dictionary new ].
    userDict at: handle connectionId put: handle.
    StringSignal emit: ('{1} CONNECTED ({2}): {3}' format: {
        transportName.
        (aCollection asArray join: ',').
        aUserId }).
    ^ handle
]

{ #category : 'utilities - objectiveC' }
BlennyTransportBridge >> sendMessage: aMessage to: aConnection [
   self subclassResponsibility
]

{ #category : 'publishing' }
BlennyTransportBridge >> sendMessageIfIntentsPermit: aMessage to: aHandle [
    | intents msgCategory |
    intents := aHandle intents.
    intents ifNil: [ ^ self ].
    (intents includes: #all) ifTrue: [ ^ self sendMessage: aMessage to: aHandle stream ].
    msgCategory := aMessage at: #category ifAbsent: [ #ui ].
    (intents includes: msgCategory) ifTrue: [ self sendMessage: aMessage to: aHandle stream ]
]

{ #category : 'accessing' }
BlennyTransportBridge >> start [
   isRunning := true.
]

{ #category : 'accessing' }
BlennyTransportBridge >> stop [
    isRunning := false.
    announcer unsubscribe: self.
    "Finalize all handles; they remove themselves from connectionsByUserId"
    connectionsByUserId copy do: [ :userDict |
        userDict copy do: [ :handle |
            [ handle finalize ] on: Error do: [ :ex |
                StringSignal emit: ('{1} failed to close: {2}' format: {
                    transportName. ex messageText }) ] ] ].
    connectionsByUserId removeAll.
    StringSignal emit: ('{1} bridge stopped' format: { transportName }).
    ^ self
]

{ #category : 'accessing' }
BlennyTransportBridge >> transportName [
    ^ transportName
]
