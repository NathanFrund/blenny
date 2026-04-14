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
BlennySimpleAuthTest >> testBlacklistCleanup [
    "Test that expired blacklist entries are removed"
    | auth |
    auth := BlennySimpleAuth new.
    auth blacklist at: 'test-jti' put: DateAndTime now - 1 hour.
    auth cleanupBlacklist.
    self assert: (auth blacklist includesKey: 'test-jti') equals: false.
]

{ #category : 'tests' }
BlennySimpleAuthTest >> testCreateUser [
    self assert: (auth createUser: 'newuser' password: 'pass').
    self assert: (auth userExists: 'newuser').
    self assert: (auth createUser: 'newuser' password: 'pass') equals: false.

]

{ #category : 'tests' }
BlennySimpleAuthTest >> testInvalidTokenFormat [
    | userId |
    userId := auth validateToken: 'not.a.valid.jwt'.
    self assert: userId equals: nil.
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
BlennySimpleAuthTest >> testTamperedToken [
    "Test that a tampered token is rejected"
    | token userId parts tampered |
    token := auth authenticate: 'alice' password: 'secret'.
    
    "Split into header, payload, signature"
    parts := token splitOn: '.'.
    
    "Modify the payload (second part) by changing a character"
    "This corrupts the base64 encoding"
    tampered := parts first, '.', (parts second copyReplaceAll: 'i' with: 'x'), '.', parts third.
    
    userId := auth validateToken: tampered.
    self assert: userId equals: nil.

]

{ #category : 'tests' }
BlennySimpleAuthTest >> testTokenExpiration [
    "Test that expired tokens are rejected"
    | token userId |
    "Create a token that expires in 1 second"
    "This requires modifying createJwtForUser to accept duration"
    "Or test with a token that's already expired"
    self skip.
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
