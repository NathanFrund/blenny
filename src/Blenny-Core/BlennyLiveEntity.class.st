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
