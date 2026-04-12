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
