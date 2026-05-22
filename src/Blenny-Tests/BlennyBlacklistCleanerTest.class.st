Class {
	#name : 'BlennyBlacklistCleanerTest',
	#superclass : 'TestCase',
	#category : 'Blenny-Tests',
	#package : 'Blenny-Tests'
}

{ #category : 'tests' }
BlennyBlacklistCleanerTest >> testPerformCleanupRemovesExpiredEntries [
    | repository cleaner expiredJti validJti expirationDate validExpiration |
    repository := BlennyMemoryRepository new.
    cleaner := BlennyBlacklistCleaner forRepository: repository.
    
    "Add an expired entry (1 hour ago)"
    expiredJti := 'expired-jti'.
    expirationDate := DateAndTime now - (1 * 60 * 60).
    repository saveBlacklistEntry: expiredJti expiration: expirationDate.
    
    "Add a valid entry (1 hour from now)"
    validJti := 'valid-jti'.
    validExpiration := DateAndTime now + (1 * 60 * 60).
    repository saveBlacklistEntry: validJti expiration: validExpiration.
    
    "Perform cleanup" 
    cleaner performCleanup.
    
    "Expired entry should be gone; valid entry remains"
    self assert: (repository isBlacklisted: expiredJti) equals: false.
    self assert: (repository isBlacklisted: validJti) equals: true.
]

{ #category : 'tests' }
BlennyBlacklistCleanerTest >> testPerformCleanupWithEmptyRepository [
    | repository cleaner |
    repository := BlennyMemoryRepository new.
    cleaner := BlennyBlacklistCleaner forRepository: repository.
    
    "Should not raise any error"
    cleaner performCleanup.
    
    self assert: true. "If we reach here, test passes"
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
    
    self assert: (repository isBlacklisted: jti) equals: true.
]
