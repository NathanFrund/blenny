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
		'connectionsById',
		'isRunning',
		'transportName'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'adding' }
BlennyTransportBridge >> addConnection: aConnection forUser: aUserId intents: aCollection [

	| connId userConns info |
	connId := aConnection hash.
	info := Dictionary new
		        at: #connection put: aConnection;
		        at: #intents put: aCollection asSet;
		        yourself.
	connectionsById at: connId put: info.
	userConns := connectionsByUserId
		             at: aUserId
		             ifAbsentPut: [ OrderedCollection new ].
	userConns add: aConnection.
	StringSignal emit: ('{1} CONNECTED ({2}): {3}' format: {
				 transportName.
				 (aCollection asArray join: ',').
				 aUserId }).
	^ aConnection
]

{ #category : 'adding' }
BlennyTransportBridge >> addSSEStream: aStream forUser: aUserId intents: aCollection [
   "Temporary; will be overridden in BlennySSEBridge"
   self addConnection: aStream forUser: aUserId intents: aCollection
]

{ #category : 'publishing' }
BlennyTransportBridge >> broadcastData: aPayload [
   self broadcastMessage: (Dictionary with: #signals -> aPayload with: #category -> #ui)
]

{ #category : 'publishing' }
BlennyTransportBridge >> broadcastHtml: aPayload [
   self broadcastMessage: (Dictionary with: #html -> aPayload with: #category -> #ui)
]

{ #category : 'publishing' }
BlennyTransportBridge >> broadcastMessage: aMessage [
   connectionsByUserId keysAndValuesDo: [ :userId :conns |
      conns do: [ :conn | self sendMessageIfIntentsPermit: aMessage to: conn ] ]
]

{ #category : 'accessing' }
BlennyTransportBridge >> connectionsForUserId: aUserId [
   ^ connectionsByUserId at: aUserId ifAbsent: [ #() ]
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
   (self connectionsForUserId: aUserId) do: [ :conn |
      self sendMessageIfIntentsPermit: aMessage to: conn ]
]

{ #category : 'testing' }
BlennyTransportBridge >> hasConnectionForUser: aUserId [
   ^ connectionsByUserId includesKey: aUserId
]

{ #category : 'initialization' }
BlennyTransportBridge >> initialize [
   super initialize.
   connectionsByUserId := Dictionary new.
   connectionsById := Dictionary new.
   isRunning := false.
   transportName := 'transport'
]

{ #category : 'initialization' }
BlennyTransportBridge >> initializeWithName: aString [
   transportName := aString.
   announcer := Announcer new.
   connectionsByUserId := Dictionary new.
   connectionsById := Dictionary new.
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
BlennyTransportBridge >> intentsForConnection: aConnection [
   | info |
   info := connectionsById at: aConnection hash ifAbsent: [ ^ nil ].
   ^ info at: #intents
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

{ #category : 'removing' }
BlennyTransportBridge >> removeConnection: aConnection forUser: aUserId [
   | connId userConns |
   connId := aConnection hash.
   connectionsById removeKey: connId ifAbsent: [ ^ self ].
   userConns := connectionsByUserId at: aUserId ifAbsent: [ ^ self ].
   userConns remove: aConnection ifAbsent: [].
   userConns ifEmpty: [ connectionsByUserId removeKey: aUserId ].
   StringSignal emit: ('{1} DISCONNECTED: {2}' format: { transportName. aUserId }).

]

{ #category : 'utilities - objectiveC' }
BlennyTransportBridge >> sendMessage: aMessage to: aConnection [
   self subclassResponsibility
]

{ #category : 'publishing' }
BlennyTransportBridge >> sendMessageIfIntentsPermit: aMessage to: aConnection [
   | intents msgCategory |
   intents := self intentsForConnection: aConnection.
   intents ifNil: [ ^ self ].
   (intents includes: #all) ifTrue: [ ^ self sendMessage: aMessage to: aConnection ].
   msgCategory := aMessage at: #category ifAbsent: [ #ui ].
   (intents includes: msgCategory) ifTrue: [ self sendMessage: aMessage to: aConnection ]
]

{ #category : 'accessing' }
BlennyTransportBridge >> start [
   isRunning := true.
]

{ #category : 'accessing' }
BlennyTransportBridge >> stop [

	isRunning := false.
	announcer unsubscribe: self.
	connectionsById copy valuesDo: [ :info |
			[ (info at: #connection) close ]
				on: Error
				do: [ :ex |
						StringSignal emit: ('{1} failed to close: {2}' format: {
									 transportName.
									 ex messageText }) ] ].
	connectionsById removeAll.
	connectionsByUserId removeAll.
	StringSignal emit: ('{1} bridge stopped' format: { transportName }).
	^ self
]

{ #category : 'accessing' }
BlennyTransportBridge >> transportName [
    ^ transportName
]
