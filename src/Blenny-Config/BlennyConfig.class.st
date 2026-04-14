"
I am the main configuration facade for Blenny.

I provide a unified interface to configuration values from multiple sources, with a clear precedence order:

1. Command line arguments (--key=value)
2. Environment variables (BLENNY_KEY=value)
3. Config file (blenny.json)
4. Embedded defaults (compiled into the image)

I automatically select the appropriate provider based on what's available.

Usage:
    ""Get a value""
    port := BlennyConfig current at: 'server.port'.
    
    ""Convenience methods for common keys""
    port := BlennyConfig current port.
    secret := BlennyConfig current jwtSecret.
    
    ""Reset the cache (useful after changing config file)""
    BlennyConfig reset.

Configuration keys use dot notation:
    server.port
    server.bind_address
    auth.jwt_secret
    auth.session_duration_hours
    dev_mode

I am the single source of truth for all Blenny configuration.
"
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

{ #category : 'convenience' }
BlennyConfig >> bindAddress [
    "Return bind_address string"
    ^ self at: 'server.bind_address'
]

{ #category : 'accessing' }
BlennyConfig >> booleanAt: aKey [
    | value |
    value := self at: aKey.
    ^ value = true or: [ value asString asLowercase = 'true' ]
]

{ #category : 'accessing' }
BlennyConfig >> devMode [
    ^ self booleanAt: 'dev_mode'
]

{ #category : 'initialization' }
BlennyConfig >> initialize [
    provider := self selectProvider.
    self showStartupWarning.
]

{ #category : 'convenience' }
BlennyConfig >> jwtSecret [
    ^ self at: 'auth.jwt_secret'
]

{ #category : 'convenience' }
BlennyConfig >> port [
    ^ self at: 'server.port'
]

{ #category : 'accessing' }
BlennyConfig >> provider [
    "Return the active config provider (for debugging)"
    ^ provider
]

{ #category : 'accessing' }
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

{ #category : 'convenience' }
BlennyConfig >> sessionDuration [
    | hours |
    hours := self at: 'auth.session_duration_hours'.
    ^ hours * 60 * 60
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
