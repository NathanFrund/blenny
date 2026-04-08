Class {
	#name : 'BlennyMessage',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'payload'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'accessing' }
BlennyMessage >> payload [
	^ payload 
]

{ #category : 'accessing' }
BlennyMessage >> topic [
	^ topic 
]

{ #category : 'initialization' }
BlennyMessage >> topic: aString payload: anObject [
	topic := aString.
	payload := anObject.
]
