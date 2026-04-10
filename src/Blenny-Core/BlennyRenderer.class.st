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

{ #category : 'template-resolution' }
BlennyRenderer >> resolvePartials [
	| dict prefix |
	"If Disk is active, use its registry" 
	(self conduit notNil and: [ self conduit registry notEmpty ]) 
		ifTrue: [ ^ self conduit registry ]. 

	"Otherwise, rebuild from Frozen methods" 
	prefix := 'frozenTemplate'.
	dict := Dictionary new. 
	(self class selectors select: [ :s | s beginsWith: prefix ]) do: [ :sel | 
		| key |
		key := (sel copyFrom: prefix size + 1 to: sel size) asLowercase.
		dict at: key put: (MustacheTemplate on: (self perform: sel)) ]. 
	^ dict
]

{ #category : 'accessing' }
BlennyRenderer >> templateNamed: aName [
    | methodName |
    methodName := ('frozenTemplate' , aName capitalized) asSymbol.

    "1. Check Disk (Via the conduit method, not a variable)"
    (self conduit notNil and: [ self conduit registry includesKey: aName ])
        ifTrue: [ ^ self conduit registry at: aName ].

    "2. Check Image (Frozen Methods)"
    (self respondsTo: methodName)
        ifTrue: [ ^ MustacheTemplate on: (self perform: methodName) ].

    ^ nil
]
