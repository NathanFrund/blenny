"
I am the always‑on SSE transport bridge in Blenny.

I hold a BlennySSEEncoder (injected at start‑up via configuration) and implement #sendMessage:to: by converting the message dictionary to SSE text and writing it to
the stored socket stream.

My lifecycle:

  - addSSEStream:forUser:intents:   registers a socket stream (called from the router)
  - sendMessage:to:                encodes and writes a message to that stream

The encoder class is chosen by BlennyConfig (key: 'sse.encoder').  

The default is BlennyStandardSSEEncoder; switch to DatastarSSEEncoder for Datastar-powered front-ends.
"
Class {
	#name : 'BlennySSEBridge',
	#superclass : 'BlennyTransportBridge',
	#instVars : [
		'encoder'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'adding' }
BlennySSEBridge >> addSSEStream: aStream forUser: aUserId intents: aCollection [
   self addConnection: aStream forUser: aUserId intents: aCollection
]

{ #category : 'accessing' }
BlennySSEBridge >> encoder [
	^ encoder
]

{ #category : 'initialization' }
BlennySSEBridge >> initializeWithEncoder: anSSEEncoder name: aString [
   self initializeWithName: aString.
   encoder := anSSEEncoder.
   ^ self

]

{ #category : 'utilities - objectiveC' }
BlennySSEBridge >> sendMessage: aMessage to: aConnection [
   | rawSSE |
   rawSSE := encoder encodeMessage: aMessage.
   rawSSE ifNotNil: [
      [ aConnection nextPutAll: rawSSE; flush ]
         on: Error do: [ :e |
            Transcript show: 'SSE send error: '; show: e messageText; cr ] ]

]
