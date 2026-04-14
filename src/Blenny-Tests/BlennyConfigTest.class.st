Class {
	#name : 'BlennyConfigTest',
	#superclass : 'TestCase',
	#category : 'Blenny-Tests',
	#package : 'Blenny-Tests'
}

{ #category : 'tests' }
BlennyConfigTest >> testConvenienceMethods [
    | config |
    config := BlennyConfig new.
    self assert: config port equals: 8081.
    self assert: config bindAddress equals: '0.0.0.0'.
    self assert: config jwtSecret equals: 'CHANGE-ME-EMBEDDED-DEFAULT'.
    self assert: config devMode equals: true.
]

{ #category : 'accessing' }
BlennyConfigTest >> testDefaultValues [
    "Test that embedded defaults work"
    | config |
    config := BlennyConfig new.
    self assert: (config at: 'server.port') equals: 8081.
    self assert: (config at: 'server.bind_address') equals: '0.0.0.0'.
    self assert: (config at: 'auth.jwt_secret') equals: 'CHANGE-ME-EMBEDDED-DEFAULT'.
    self assert: (config at: 'auth.session_duration_hours') equals: 720.
    self assert: (config at: 'dev_mode') equals: true.
]

{ #category : 'tests' }
BlennyConfigTest >> testSessionDuration [
    | config |
    config := BlennyConfig new.
    self assert: config sessionDuration equals: 720 * 60 * 60.

]
