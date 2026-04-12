Class {
	#name : 'BlennyConfig',
	#superclass : 'Object',
	#instVars : [
		'provider'
	],
	#classInstVars : [
		'Current'
	],
	#category : 'Blenny-Config',
	#package : 'Blenny-Config'
}

{ #category : 'accessing' }
BlennyConfig class >> current [
    ^ Current ifNil: [ Current := self new ]
]

{ #category : 'initialization' }
BlennyConfig class >> reset [
	"Clear the cached current instance"
	Current := nil
]

{ #category : 'accessing' }
BlennyConfig >> at: aKey [
    ^ provider at: aKey
]

{ #category : 'accessing' }
BlennyConfig >> at: aKey ifAbsent: aBlock [
    | value |
    value := self at: aKey.
    ^ value ifNil: aBlock
]

{ #category : 'as yet unclassified' }
BlennyConfig >> bindAddress [
    "Return bind_address string"
    ^ self at: 'bind_address' ifAbsent: [ '0.0.0.0' ]
]

{ #category : 'accessing' }
BlennyConfig >> devMode [
    ^ provider booleanAt: 'dev_mode'
]

{ #category : 'accessing' }
BlennyConfig >> host [
    ^ provider stringAt: 'host'
]

{ #category : 'initialization' }
BlennyConfig >> initialize [
    provider := self selectProvider.
    self showStartupWarning.
]

{ #category : 'accessing' }
BlennyConfig >> jwtSecret [
    ^ provider stringAt: 'jwt_secret'
]

{ #category : 'accessing' }
BlennyConfig >> port [
    ^ provider integerAt: 'port'
]

{ #category : 'accessing' }
BlennyConfig >> provider [
    "Return the active config provider (for debugging)"
    ^ provider
]

{ #category : 'as yet unclassified' }
BlennyConfig >> providerClass [
    "Return the class name of the active provider"
    ^ provider class name
]

{ #category : 'initialization' }
BlennyConfig >> resetProvider [
    "Force provider selection on next access"
    provider := nil
]

{ #category : 'initialization' }
BlennyConfig >> selectProvider [
    "Try providers in order of precedence"
    (BlennyArgConfigProvider new hasConfig) ifTrue: [ ^ BlennyArgConfigProvider new ].
    (BlennyEnvConfigProvider new hasConfig) ifTrue: [ ^ BlennyEnvConfigProvider new ].
    (BlennyFileConfigProvider new hasConfig) ifTrue: [ ^ BlennyFileConfigProvider new ].
    ^ BlennyEmbeddedConfigProvider new.
]

{ #category : 'initialization' }
BlennyConfig >> showStartupWarning [
    (provider isKindOf: BlennyEmbeddedConfigProvider) ifTrue: [
        Transcript show: '========================================'; cr.
        Transcript show: 'WARNING: Using embedded default configuration!'; cr.
        Transcript show: 'Create blenny.json for production use.'; cr.
        Transcript show: '========================================'; cr.
        (Delay forSeconds: 2) wait ]
]
