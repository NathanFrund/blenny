"
I am the abstract base class for all configuration providers.

I define the protocol that each provider must implement.

Subclasses must implement:
    hasConfig   ""Return true if this provider can supply configuration""
    at:         ""Return value for key, or nil if not found""

Optional convenience methods (provided by default):
    stringAt:   ""Return value as string""
    integerAt:  ""Return value as integer""
    booleanAt:  ""Return value as boolean""

Built-in providers:
    BlennyEmbeddedConfigProvider  - Compiled defaults (always works)
    BlennyFileConfigProvider      - Reads blenny.json
    BlennyEnvConfigProvider       - Reads BLENNY_* environment variables
    BlennyArgConfigProvider       - Reads command line arguments

Example custom provider:
    BlennyConfigProvider subclass: #MyDatabaseConfigProvider
        hasConfig [ ^ database notNil ]
        at: aKey [ ^ database at: aKey ]
"
Class {
	#name : 'BlennyConfigProvider',
	#superclass : 'Object',
	#category : 'Blenny-Config',
	#package : 'Blenny-Config'
}

{ #category : 'accessing' }
BlennyConfigProvider >> at: aKey [
    "Return value for key, or nil if not found"
    ^ self subclassResponsibility
]

{ #category : 'accessing' }
BlennyConfigProvider >> booleanAt: aKey [
    | value |
    value := self at: aKey.
    value ifNil: [ ^ false ].
    ^ value = true or: [ value asString asLowercase = 'true' ]
]

{ #category : 'testing' }
BlennyConfigProvider >> hasConfig [
    "Return true if this provider can supply configuration"
    ^ self subclassResponsibility
]

{ #category : 'accessing' }
BlennyConfigProvider >> integerAt: aKey [
    "Return integer value for key"
    | value |
    value := self at: aKey.
    ^ value ifNotNil: [ value asInteger ]
]

{ #category : 'accessing' }
BlennyConfigProvider >> stringAt: aKey [
    "Return string value for key"
    ^ self at: aKey
]
