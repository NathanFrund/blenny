Class {
	#name : 'BlennyFileConfigProvider',
	#superclass : 'BlennyConfigProvider',
	#instVars : [
		'config'
	],
	#category : 'Blenny-Config',
	#package : 'Blenny-Config'
}

{ #category : 'accessing' }
BlennyFileConfigProvider >> at: aKey [
    ^ config at: aKey ifAbsent: [ nil ]
]

{ #category : 'testing' }
BlennyFileConfigProvider >> hasConfig [
    ^ config notNil and: [ config isEmpty not ]
]

{ #category : 'initialization' }
BlennyFileConfigProvider >> initialize [ 
	super initialize.
	self loadConfig.
]

{ #category : 'loading' }
BlennyFileConfigProvider >> loadConfig [
    | file |
    file := 'blenny.json' asFileReference.
    file exists ifFalse: [ ^ self ].
    config := STON fromString: file contents.
]
