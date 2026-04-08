Class {
	#name : 'BlennyClientMessage',
	#superclass : 'Object',
	#instVars : [
		'fromUserId',
		'payload'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'initialization' }
BlennyClientMessage >> fromUserId [
	^ fromUserId 
]

{ #category : 'initialization' }
BlennyClientMessage >> fromUserId: aString payload: anObject [
	fromUserId := aString.
	payload := anObject.
]

{ #category : 'initialization' }
BlennyClientMessage >> payload [
	^ payload
]
