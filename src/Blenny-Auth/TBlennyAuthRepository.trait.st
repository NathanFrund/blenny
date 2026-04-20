Trait {
	#name : 'TBlennyAuthRepository',
	#traits : 'TBlennyRepository',
	#classTraits : 'TBlennyRepository classTrait',
	#category : 'Blenny-Auth',
	#package : 'Blenny-Auth'
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
