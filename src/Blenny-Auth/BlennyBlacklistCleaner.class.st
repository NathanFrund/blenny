"
I manage periodic cleanup of expired token blacklist entries for the authentication system.

I run in a background process and call `repository cleanupExpiredBlacklist` at regular intervals (default 5 minutes). I am created and started by `BlennyWebApp` when the auth service is initialized, and stopped when the server stops.

Usage:
    cleaner := BlennyBlacklistCleaner forRepository: authService repository.
    cleaner intervalSeconds: 300.   ""optional""
    cleaner start.
    ...
    cleaner stop.

Testing:
    I provide #performCleanup to run a single cleanup cycle synchronously (used in unit tests).

Instance Variables:
    repository       <BlennyAuthRepository>  the repository containing the blacklist
    process          <Process>               the background process (nil when stopped)
    intervalSeconds  <Integer>               delay between cleanups (default 300)

"
Class {
	#name : 'BlennyBlacklistCleaner',
	#superclass : 'Object',
	#instVars : [
		'repository',
		'process',
		'intervalSeconds'
	],
	#category : 'Blenny-Auth',
	#package : 'Blenny-Auth'
}

{ #category : 'instance creation' }
BlennyBlacklistCleaner class >> forRepository: aRepository [
    ^ self new repository: aRepository; yourself
]

{ #category : 'accessing' }
BlennyBlacklistCleaner >> intervalSeconds: anInteger [
    intervalSeconds := anInteger
]

{ #category : 'cleanup' }
BlennyBlacklistCleaner >> performCleanup [
    "Run one cleanup cycle immediately (for testing and manual invocation)."
    repository ifNotNil: [ repository cleanupExpiredBlacklist ]

]

{ #category : 'accessing' }
BlennyBlacklistCleaner >> repository: aRepository [
    repository := aRepository
]

{ #category : 'accessing' }
BlennyBlacklistCleaner >> start [
    intervalSeconds ifNil: [ intervalSeconds := 300 ].
    process := [ 
        [ true ] whileTrue: [ 
            (Delay forSeconds: intervalSeconds) wait.
            self performCleanup ]
    ] forkAt: Processor userBackgroundPriority named: 'BlennyBlacklistCleaner'.

]

{ #category : 'accessing' }
BlennyBlacklistCleaner >> stop [
    process ifNotNil: [ 
        process terminate.
        process := nil ]
]
