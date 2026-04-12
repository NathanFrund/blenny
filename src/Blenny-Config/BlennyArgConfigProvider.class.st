Class {
	#name : 'BlennyArgConfigProvider',
	#superclass : 'BlennyConfigProvider',
	#instVars : [
		'args'
	],
	#category : 'Blenny-Config',
	#package : 'Blenny-Config'
}

{ #category : 'accessing' }
BlennyArgConfigProvider >> at: aKey [
    ^ args at: aKey ifAbsent: [ nil ]
]

{ #category : 'testing' }
BlennyArgConfigProvider >> hasConfig [
    ^ args notEmpty
]

{ #category : 'initialization' }
BlennyArgConfigProvider >> initialize [ 
	super initialize.
	self parseArgs.
]

{ #category : 'parsing' }
BlennyArgConfigProvider >> parseArgs [
    args := Dictionary new.
    (Smalltalk commandLine arguments) do: [ :arg |
        (arg beginsWith: '--') ifTrue: [
            | key value |
            key := (arg copyFrom: 3 to: (arg indexOf: $=) - 1).
            value := (arg copyAfter: $=).
            args at: key put: value ] ]

]
