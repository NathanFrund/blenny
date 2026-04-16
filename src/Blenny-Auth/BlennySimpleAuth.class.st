"
I provide JWT-based authentication for Blenny.

Features:
- JWT creation and validation (HS256)
- Configurable session duration
- Token blacklist with automatic cleanup
- User management (create, delete, exists)
- Password hashing (simple hash for development)

This is a reference implementation. For production, replace with your own auth provider.
"
Class {
	#name : 'BlennySimpleAuth',
	#superclass : 'Object',
	#instVars : [
		'repository',
		'janitorProcess'
	],
	#category : 'Blenny-Auth',
	#package : 'Blenny-Auth'
}

{ #category : 'authentication' }
BlennySimpleAuth >> authenticate: username password: password [
    | user storedHash |
    user := repository findUserByUsername: username.
    user ifNil: [ ^ nil ].
    storedHash := user at: 'passwordHash'.
    (self hashPassword: password) = storedHash ifTrue: [
        ^ self createJwtForUser: username ].
    ^ nil
]

{ #category : 'blacklist' }
BlennySimpleAuth >> cleanupBlacklist [
    repository cleanupExpiredBlacklist.
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

{ #category : 'password-reset' }
BlennySimpleAuth >> createPasswordResetTokenFor: email [
    | token expiration |
    token := UUID new asString.
    expiration := DateAndTime now + (1 * 60 * 60).
    repository saveResetToken: token forEmail: email expiration: expiration.
    ^ token
]

{ #category : 'user management' }
BlennySimpleAuth >> createUser: aUsername password: aPassword [
    (self userExists: aUsername) ifTrue: [ ^ false ].
    repository saveUser: {
        'id' -> UUID new asString.
        'username' -> aUsername.
        'passwordHash' -> (self hashPassword: aPassword).
        'createdAt' -> DateAndTime now.
    } asDictionary.
    ^ true
]

{ #category : 'user management' }
BlennySimpleAuth >> deleteUser: aUsername [
    repository deleteUser: aUsername.
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


]

{ #category : 'jwt' }
BlennySimpleAuth >> jwtSecret [
    "Get JWT secret from config"
    ^ BlennyConfig current jwtSecret
]

{ #category : 'authentication' }
BlennySimpleAuth >> logout: aToken [
    | jti exp |
    aToken ifNil: [ ^ self ].
    
    jti := self extractJtiFromToken: aToken.
    exp := self extractExpFromToken: aToken.
    
    jti ifNotNil: [ 
        repository saveBlacklistEntry: jti expiration: exp.
        Transcript show: 'Token blacklisted until: ', exp asString; cr ].
]

{ #category : 'accessing' }
BlennySimpleAuth >> repository [
	^ repository 
]

{ #category : 'accessing' }
BlennySimpleAuth >> repository: aRepository [

	repository := aRepository.
	"Now that repository is set, start the janitor"
	self cleanupBlacklist.
	self startBlacklistJanitor
]

{ #category : 'password-reset' }
BlennySimpleAuth >> resetPassword: token newPassword: aPassword [
    | email |
    email := self validatePasswordResetToken: token.
    email ifNil: [ ^ false ].
    self createUser: email password: aPassword.
    repository deleteResetToken: token.
    ^ true
]

{ #category : 'system' }
BlennySimpleAuth >> shutDown [
    "Pharo system hook - called on image shutdown"
    self shutdown.
]

{ #category : 'shutdown' }
BlennySimpleAuth >> shutdown [
    "Clean up background processes"
    self stopBlacklistJanitor.
]

{ #category : 'blacklist' }
BlennySimpleAuth >> startBlacklistJanitor [
    janitorProcess := [
        [ true ] whileTrue: [
            (Delay forMinutes: 5) wait.
            self cleanupBlacklist.  "← This is correct"
            Transcript show: 'Blacklist cleanup complete.'; cr.
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
    ^ (repository findUserByUsername: aUsername) notNil
]

{ #category : 'jwt' }
BlennySimpleAuth >> validateJwt: aToken [
    | jws jti expValue result |
    aToken ifNil: [ ^ nil ].
    
    "Guard against nil repository"
    repository ifNil: [ 
        ^ nil ].
    
    [ 
        jws := JsonWebSignature materializeCompact: aToken key: self jwtSecret.
        
        expValue := jws payload exp.
        expValue <= DateAndTime now asUnixTime ifTrue: [ 
            ^ nil ].
        
        jti := jws payload jti.
        (repository isBlacklisted: jti) ifTrue: [ 
            ^ nil ].
        
        result := jws payload sub.
        ^ result
    ] on: Error do: [ :ex | 
        Transcript show: 'JWT Error: ', ex description; cr.
        ^ nil ]
]

{ #category : 'password-reset' }
BlennySimpleAuth >> validatePasswordResetToken: token [
    ^ repository findEmailByResetToken: token
]

{ #category : 'authentication' }
BlennySimpleAuth >> validateToken: token [
    | result |
    result := self validateJwt: token.
    ^ result
]
