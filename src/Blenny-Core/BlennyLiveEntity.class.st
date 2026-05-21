"
I am a streaming ZnEntity for Server‑Sent Events (SSE) that writes live data to the socket.

Unlike static entities, I do not have a fixed content length. When Zinc calls #writeOn:,
I execute the stored updateBlock, passing it the raw socket stream. This allows the
application to write SSE messages (or keep‑alive comments) directly to the connection
over time, without buffering the entire response.

I am created by BlennyRouter when handling an SSE request:

    entity := BlennyLiveEntity updateBlock: [ :stream |
        stream nextPutAll: 'data: hello'; flush.
        [ true ] whileTrue: [ ... ] ].

My only responsibility is to bridge the ZnServer socket stream to the application's
streaming logic. I do not interpret or format messages – that is the job of the encoder.
"
Class {
	#name : 'BlennyLiveEntity',
	#superclass : 'Object',
	#instVars : [
		'updateBlock'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'accessing' }
BlennyLiveEntity class >> updateBlock: aBlock [
    ^ self new updateBlock: aBlock
]

{ #category : 'accessing' }
BlennyLiveEntity >> contentLength [
    ^ nil  "Important: infinite stream"
]

{ #category : 'accessing' }
BlennyLiveEntity >> contentType [
    "Return the base MIME type object"
    ^ ZnMimeType fromString: 'text/event-stream'
]

{ #category : 'accessing' }
BlennyLiveEntity >> updateBlock: aBlock [
    updateBlock := aBlock
]

{ #category : 'writing' }
BlennyLiveEntity >> writeOn: aStream [
    "Zinc calls this with the socket stream"
    updateBlock value: aStream
]
