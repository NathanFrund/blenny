Class {
	#name : 'BlennySimpleAuthTest',
	#superclass : 'TestCase',
	#instVars : [
		'auth'
	],
	#category : 'Blenny-Tests',
	#package : 'Blenny-Tests'
}

{ #category : 'running' }
BlennySimpleAuthTest >> setUp [
    auth := BlennySimpleAuth new.
]

{ #category : 'tests' }
BlennySimpleAuthTest >> testAuthenticateInvalidUser [
    | token |
    token := auth authenticate: 'alice' password: 'wrong'.
    self assert: token equals: nil.
]

{ #category : 'tests' }
BlennySimpleAuthTest >> testAuthenticateValidUser [
    | token |
    token := auth authenticate: 'alice' password: 'secret'.
    self assert: token notNil.
    self assert: (token beginsWith: 'eyJ').
]

{ #category : 'tests' }
BlennySimpleAuthTest >> testCreateUser [
    self assert: (auth createUser: 'newuser' password: 'pass').
    self assert: (auth userExists: 'newuser').
    self assert: (auth createUser: 'newuser' password: 'pass') equals: false.

]

{ #category : 'tests' }
BlennySimpleAuthTest >> testLogout [
    | token userId |
    token := auth authenticate: 'alice' password: 'secret'.
    auth logout: token.
    userId := auth validateToken: token.
    self assert: userId equals: nil.
]

{ #category : 'tests' }
BlennySimpleAuthTest >> testUserExists [
    self assert: (auth userExists: 'alice') equals: true.
    self assert: (auth userExists: 'nonexistent') equals: false.
]

{ #category : 'tests' }
BlennySimpleAuthTest >> testValidateInvalidToken [
    | userId |
    userId := auth validateToken: 'invalid.token.here'.
    self assert: userId equals: nil.
]

{ #category : 'tests' }
BlennySimpleAuthTest >> testValidateValidToken [
    | token userId |
    token := auth authenticate: 'alice' password: 'secret'.
    userId := auth validateToken: token.
    self assert: userId equals: 'alice'.
]
