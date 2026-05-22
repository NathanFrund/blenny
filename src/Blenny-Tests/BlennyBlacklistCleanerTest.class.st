Class {
	#name : 'BlennyBlacklistCleanerTest',
	#superclass : 'TestCase',
	#category : 'Blenny-Tests',
	#package : 'Blenny-Tests'
}

{ #category : 'tests' }
BlennyBlacklistCleanerTest >> testIntervalValidation [

	| repository cleaner |
	repository := BlennyMemoryRepository new.
	cleaner := BlennyBlacklistCleaner forRepository: repository.

	self should: [ cleaner intervalSeconds: 0 ] raise: Error.
	self should: [ cleaner intervalSeconds: -5 ] raise: Error
]

{ #category : 'tests' }
BlennyBlacklistCleanerTest >> testPerformCleanupRemovesExpiredEntries [

	| repository cleaner expiredJti validJti expirationDate validExpiration |
	repository := BlennyMemoryRepository new.
	cleaner := BlennyBlacklistCleaner forRepository: repository.

	expiredJti := 'expired-jti'.
	expirationDate := DateAndTime now - (1 * 60 * 60).
	repository saveBlacklistEntry: expiredJti expiration: expirationDate.

	validJti := 'valid-jti'.
	validExpiration := DateAndTime now + (1 * 60 * 60).
	repository saveBlacklistEntry: validJti expiration: validExpiration.

	cleaner performCleanup.

	self deny: (repository isBlacklisted: expiredJti).
	self assert: (repository isBlacklisted: validJti)
]

{ #category : 'tests' }
BlennyBlacklistCleanerTest >> testPerformCleanupWithEmptyRepository [

	| repository cleaner |
	repository := BlennyMemoryRepository new.
	cleaner := BlennyBlacklistCleaner forRepository: repository.

	"Should not raise any error"
	cleaner performCleanup.

	self assert: true
]

{ #category : 'tests' }
BlennyBlacklistCleanerTest >> testPerformCleanupWithNoExpiredEntries [

	| repository cleaner jti expiration |
	repository := BlennyMemoryRepository new.
	cleaner := BlennyBlacklistCleaner forRepository: repository.

	jti := 'valid-jti'.
	expiration := DateAndTime now + (1 * 60 * 60).
	repository saveBlacklistEntry: jti expiration: expiration.

	cleaner performCleanup.

	self assert: (repository isBlacklisted: jti)
]

{ #category : 'tests' }
BlennyBlacklistCleanerTest >> testStartAndStop [

	| repository cleaner |
	repository := BlennyMemoryRepository new.
	cleaner := BlennyBlacklistCleaner forRepository: repository.
	cleaner intervalSeconds: 1. "Short interval for quick test"

	self deny: cleaner isStarted.
	cleaner start.
	self assert: cleaner isStarted.

	"Wait a bit to allow a cleanup cycle (optional, just to be safe)"
	(Delay forMilliseconds: 500) wait.

	cleaner stop.
	self deny: cleaner isStarted
]
