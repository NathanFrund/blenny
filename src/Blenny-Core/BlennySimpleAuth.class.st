Class {
	#name : 'BlennySimpleAuth',
	#superclass : 'Object',
	#instVars : [
		'users',
		'sessions'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'as yet unclassified' }
BlennySimpleAuth >> authenticate: aUsername password: aPassword [
    | storedHash sessionId sessionDict |
    storedHash := users at: aUsername ifAbsent: [ ^ nil ].
    (self hashPassword: aPassword) = storedHash ifTrue: [
        sessionId := UUID new asString.
        
        "Create dictionary explicitly - use DateAndTime"
        sessionDict := Dictionary new.
        sessionDict at: 'userId' put: aUsername.
        sessionDict at: 'createdAt' put: DateAndTime now.
        sessionDict at: 'expiresAt' put: DateAndTime now + (24 * 60 * 60). "24 hours in seconds"
        
        sessions at: sessionId put: sessionDict.
        ^ sessionId ].
    ^ nil
]

{ #category : 'as yet unclassified' }
BlennySimpleAuth >> createUser: aUsername password: aPassword [
    (users includesKey: aUsername) ifTrue: [ ^ false ].
    users at: aUsername put: (self hashPassword: aPassword).
    ^ true
]

{ #category : 'as yet unclassified' }
BlennySimpleAuth >> deleteUser: aUsername [
    users removeKey: aUsername ifAbsent: [].
]

{ #category : 'as yet unclassified' }
BlennySimpleAuth >> hashPassword: aPassword [
    "Simple hash for development - replace with SHA256 later"
    ^ (aPassword reversed, aPassword size asString, 'blenny-salt') hash asString
]

{ #category : 'initialization' }
BlennySimpleAuth >> initialize [
    super initialize.
    users := Dictionary new.
    sessions := Dictionary new.
    self setupTestUsers.
]

{ #category : 'as yet unclassified' }
BlennySimpleAuth >> logout: aSessionId [
    sessions removeKey: aSessionId ifAbsent: [].
]

{ #category : 'as yet unclassified' }
BlennySimpleAuth >> setupTestUsers [
    "username -> hashedPassword"
    users at: 'alice' put: (self hashPassword: 'secret').
    users at: 'bob' put: (self hashPassword: 'secret').
    users at: 'charlie' put: (self hashPassword: 'secret').
]

{ #category : 'as yet unclassified' }
BlennySimpleAuth >> userExists: aUsername [
    ^ users includesKey: aUsername

]

{ #category : 'as yet unclassified' }
BlennySimpleAuth >> validateSession: aSessionId [
    | session |
    session := sessions at: aSessionId ifAbsent: [ ^ nil ].
    (session at: 'expiresAt') <= DateAndTime now ifTrue: [
        sessions removeKey: aSessionId ifAbsent: [].
        ^ nil ].
    ^ session at: 'userId'
]
