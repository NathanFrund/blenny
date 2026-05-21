"
I am the repository trait for authentication storage in Blenny.

My responsibility is to define the contract for storing and retrieving
user accounts, password reset tokens, and token blacklist entries.

Implementors must provide:
- #at:ifAbsent:      → retrieve a value by key
- #at:put:           → store a value by key
- #removeKey:        → delete a key
- #allKeys           → answer all keys in the repository

The key naming convention used by BlennySimpleAuth:
- 'user_<username>'       → user dictionary
- 'blacklist_<jti>'       → expiration timestamp
- 'reset_<token>'         → reset token data

Concrete backends (memory, file, SQLite, Redis) should use this trait
to ensure a consistent API for the authentication system.

Example usage (inside a concrete class):

    MyRepository >> at: aKey ifAbsent: aBlock
        ^ myDictionary at: aKey ifAbsent: aBlock

    MyRepository >> allKeys
        ^ myDictionary keys

Note: This trait does not provide default implementations; it only
declares the required methods. Subclasses must implement them.
"
Trait {
	#name : 'TBlennyAuthRepository',
	#traits : 'TBlennyRepository',
	#classTraits : 'TBlennyRepository classTrait',
	#category : 'Blenny-Traits',
	#package : 'Blenny-Traits'
}

{ #category : 'blacklist' }
TBlennyAuthRepository >> cleanupExpiredBlacklist [
    | now |
    now := DateAndTime now.
    self allKeys do: [ :key |
        (key beginsWith: 'blacklist_') ifTrue: [
            (self at: key ifAbsent: [ nil ]) <= now ifTrue: [
                self removeKey: key ] ] ]
]

{ #category : 'blacklist' }
TBlennyAuthRepository >> deleteResetToken: token [
    self removeKey: ('reset_', token)
]

{ #category : 'users' }
TBlennyAuthRepository >> deleteUser: aUsername [
    self removeKey: ('user_', aUsername)
]

{ #category : 'blacklist' }
TBlennyAuthRepository >> findEmailByResetToken: token [
    | data |
    data := self at: ('reset_', token) ifAbsent: [ ^ nil ].
    (data at: 'expiresAt') <= DateAndTime now ifTrue: [
        self removeKey: ('reset_', token).
        ^ nil ].
    ^ data at: 'email'
]

{ #category : 'users' }
TBlennyAuthRepository >> findUserById: aUserId [
    "Linear scan - override in Soil for performance"
    ^ self allKeys
        detect: [ :key | (key beginsWith: 'user_') and: [ 
            ((self at: key ifAbsent: [ nil ]) at: 'id') = aUserId ] ]
        ifNone: [ nil ]
]

{ #category : 'users' }
TBlennyAuthRepository >> findUserByUsername: aUsername [
    ^ self at: ('user_', aUsername) ifAbsent: [ nil ]
]

{ #category : 'blacklist' }
TBlennyAuthRepository >> isBlacklisted: jti [
    | expiration |
    expiration := self at: ('blacklist_', jti) ifAbsent: [ ^ false ].
    ^ expiration > DateAndTime now
]

{ #category : 'blacklist' }
TBlennyAuthRepository >> saveBlacklistEntry: jti expiration: expiration [
    self at: ('blacklist_', jti) put: expiration
]

{ #category : 'blacklist' }
TBlennyAuthRepository >> saveResetToken: token forEmail: email expiration: expiration [
    self at: ('reset_', token) put: { 'email' -> email. 'expiresAt' -> expiration } asDictionary
]

{ #category : 'users' }
TBlennyAuthRepository >> saveUser: aUser [
    self at: ('user_', (aUser at: 'username')) put: aUser
]
