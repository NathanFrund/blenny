"
I am an in-memory implementation of TBlennyAuthRepository.

I store all data in a Dictionary. This is useful for:
- Development and testing
- Applications that don't need persistence
- As a reference implementation for other backends

Data does NOT survive image restart.
"
Class {
	#name : 'BlennyMemoryRepository',
	#superclass : 'Object',
	#traits : 'TBlennyAuthRepository',
	#classTraits : 'TBlennyAuthRepository classTrait',
	#instVars : [
		'storage'
	],
	#category : 'Blenny-Persistence',
	#package : 'Blenny-Persistence'
}

{ #category : 'core' }
BlennyMemoryRepository >> allKeys [
    ^ storage keys
]

{ #category : 'core' }
BlennyMemoryRepository >> at: aKey ifAbsent: aBlock [
    ^ storage at: aKey ifAbsent: aBlock
]

{ #category : 'core' }
BlennyMemoryRepository >> at: aKey put: aValue [
    storage at: aKey put: aValue.
]

{ #category : 'blacklist' }
BlennyMemoryRepository >> cleanupExpiredBlacklist [
    | now |
    now := DateAndTime now.
    storage keys copy do: [ :key |
        (key beginsWith: 'blacklist_') ifTrue: [
            (storage at: key) <= now ifTrue: [
                storage removeKey: key ] ] ]

]

{ #category : 'initialization' }
BlennyMemoryRepository >> initialize [
    super initialize.
    storage := Dictionary new.
	Transcript show: 'BlennyMemoryRepository initialized with storage'; cr.
]

{ #category : 'core' }
BlennyMemoryRepository >> removeKey: aKey [
    storage removeKey: aKey ifAbsent: [].
]
