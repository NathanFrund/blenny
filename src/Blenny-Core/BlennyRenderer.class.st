Class {
	#name : 'BlennyRenderer',
	#superclass : 'Object',
	#traits : 'TConduitRenderer + THtmxRenderer',
	#classTraits : 'TConduitRenderer classTrait + THtmxRenderer classTrait',
	#instVars : [
		'conduit',
		'rootPath'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'accessing' }
BlennyRenderer >> conduit [
	^ conduit
]

{ #category : 'initialization' }
BlennyRenderer >> initializeWithConduit: aConduit rootPath: aPath [
    conduit := aConduit.
    rootPath := aPath.
]
