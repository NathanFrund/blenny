Class {
	#name : 'BlennySimpleAuth',
	#superclass : 'Object',
	#instVars : [
		'users',
		'sessions'
	],
	#category : 'Blenny-Auth',
	#package : 'Blenny-Auth'
}

{ #category : 'as yet unclassified' }
BlennySimpleAuth >> authenticate: username password: password [
    | storedHash sessionDict |
    storedHash := users at: username ifAbsent: [ ^ nil ].
    (self hashPassword: password) = storedHash ifTrue: [
        | sessionId |
        sessionId := UUID new asString.
        sessionDict := Dictionary new.
        sessionDict at: 'userId' put: username.
        sessionDict at: 'expiresAt' put: DateAndTime now + (24 * 60 * 60).
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

{ #category : 'authentication' }
BlennySimpleAuth >> validateToken: token [

	| session |
	token ifNil: [ ^ nil ].
	session := sessions at: token ifAbsent: [ ^ nil ].
	(session at: 'expiresAt') <= DateAndTime now ifTrue: [
			sessions removeKey: token ifAbsent: [ ].
			^ nil ].

	^ session at: 'userId'
]
