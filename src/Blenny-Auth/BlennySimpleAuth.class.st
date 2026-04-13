Class {
	#name : 'BlennySimpleAuth',
	#superclass : 'Object',
	#instVars : [
		'users',
		'blacklist',
		'janitorProcess'
	],
	#category : 'Blenny-Auth',
	#package : 'Blenny-Auth'
}

{ #category : 'authentication' }
BlennySimpleAuth >> authenticate: username password: password [
    | storedHash |
    storedHash := users at: username ifAbsent: [ ^ nil ].
    (self hashPassword: password) = storedHash ifTrue: [
        ^ self createJwtForUser: username ].
    ^ nil
]

{ #category : 'blacklist' }
BlennySimpleAuth >> cleanupBlacklist [
    "Remove expired entries from blacklist"
    | now |
    now := DateAndTime now.
    blacklist keys copy do: [ :jti |
        (blacklist at: jti) <= now ifTrue: [ 
            blacklist removeKey: jti ] ].
]

{ #category : 'jwt' }
BlennySimpleAuth >> createJwtForUser: aUserId [
    | jws claims jti duration |
    jti := UUID new asString.
    duration := BlennyConfig current sessionDuration.
    
    claims := JWTClaimsSet new.
    claims sub: aUserId.
    claims jti: jti.
    claims exp: (DateAndTime now + duration) asUnixTime.
    claims iat: DateAndTime now asUnixTime.
    
    jws := JsonWebSignature new
        algorithmName: 'HS256';
        payload: claims;
        symmetricKey: self jwtSecret.
    
    ^ jws compactSerialized
]

{ #category : 'user management' }
BlennySimpleAuth >> createUser: aUsername password: aPassword [
    (users includesKey: aUsername) ifTrue: [ ^ false ].
    users at: aUsername put: (self hashPassword: aPassword).
    ^ true
]

{ #category : 'user management' }
BlennySimpleAuth >> deleteUser: aUsername [
    users removeKey: aUsername ifAbsent: [].
]

{ #category : 'jwt' }
BlennySimpleAuth >> extractExpFromToken: aToken [
    | jws expValue |
    [ 
        jws := JsonWebSignature materializeCompact: aToken key: self jwtSecret.
        expValue := jws payload exp.
        ^ DateAndTime fromUnixTime: expValue
    ] on: Error do: [ :ex | ^ nil ]
]

{ #category : 'jwt' }
BlennySimpleAuth >> extractJtiFromToken: aToken [
    | jws |
    [ 
        jws := JsonWebSignature materializeCompact: aToken key: self jwtSecret.
        ^ jws payload jti
    ] on: Error do: [ :ex | ^ nil ]
]

{ #category : 'private' }
BlennySimpleAuth >> hashPassword: aPassword [
    "Simple hash for development - replace with SHA256 later"
    ^ (aPassword reversed, aPassword size asString, 'blenny-salt') hash asString
]

{ #category : 'initialization' }
BlennySimpleAuth >> initialize [
    super initialize.
    users := Dictionary new.
    blacklist := Dictionary new.
    self setupTestUsers.
    self cleanupBlacklist.  "Clean on startup"
    self startBlacklistJanitor.

	Smalltalk addToShutDownList: self.
]

{ #category : 'jwt' }
BlennySimpleAuth >> jwtSecret [
    "Get JWT secret from config"
    ^ BlennyConfig current jwtSecret
]

{ #category : 'authentication' }
BlennySimpleAuth >> logout: aToken [
    "Add token to blacklist"
    | jti exp |
    aToken ifNil: [ ^ self ].
    
    jti := self extractJtiFromToken: aToken.
    exp := self extractExpFromToken: aToken.
    
    jti ifNotNil: [ 
        blacklist at: jti put: exp.
        Transcript show: 'Token blacklisted until: ', exp asString; cr ].
]

{ #category : 'initialization' }
BlennySimpleAuth >> setupTestUsers [
    "username -> hashedPassword"
    users at: 'alice' put: (self hashPassword: 'secret').
    users at: 'bob' put: (self hashPassword: 'secret').
    users at: 'charlie' put: (self hashPassword: 'secret').
]

{ #category : 'system startup' }
BlennySimpleAuth >> shutDown [
    "Pharo system hook - called on image shutdown"
    self shutdown.
]

{ #category : 'as yet unclassified' }
BlennySimpleAuth >> shutdown [
    "Clean up background processes"
    self stopBlacklistJanitor.
]

{ #category : 'blacklist' }
BlennySimpleAuth >> startBlacklistJanitor [
    "Start background process to clean expired blacklist entries"
    janitorProcess := [
        [ true ] whileTrue: [
            (Delay forMinutes: 5) wait.
            self cleanupBlacklist.
            Transcript show: 'Blacklist cleanup complete. Size: ', blacklist size asString; cr.
        ]
    ] forkAt: Processor userBackgroundPriority named: 'BlennyAuthJanitor'.
]

{ #category : 'blacklist' }
BlennySimpleAuth >> stopBlacklistJanitor [
    janitorProcess ifNotNil: [ 
        janitorProcess terminate.
        janitorProcess := nil ].
]

{ #category : 'user management' }
BlennySimpleAuth >> userExists: aUsername [
    ^ users includesKey: aUsername

]

{ #category : 'jwt' }
BlennySimpleAuth >> validateJwt: aToken [
    | jws jti expValue |
    aToken ifNil: [ ^ nil ].
    
    [ 
        jws := JsonWebSignature materializeCompact: aToken key: self jwtSecret.
        
        expValue := jws payload exp.
        expValue <= DateAndTime now asUnixTime ifTrue: [ ^ nil ].
        
        jti := jws payload jti.
        (blacklist includesKey: jti) ifTrue: [ ^ nil ].
        
        ^ jws payload sub
    ] on: Error do: [ :ex | ^ nil ]
]

{ #category : 'authentication' }
BlennySimpleAuth >> validateToken: token [
    ^ self validateJwt: token
]
