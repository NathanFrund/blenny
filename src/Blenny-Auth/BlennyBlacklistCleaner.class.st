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
	 isRunning        <Boolean>               flag to signal graceful exit
"
Class {
	#name : 'BlennyBlacklistCleaner',
	#superclass : 'Object',
	#instVars : [
		'repository',
		'process',
		'intervalSeconds',
		'isRunning'
	],
	#category : 'Blenny-Auth',
	#package : 'Blenny-Auth'
}

{ #category : 'instance creation' }
BlennyBlacklistCleaner class >> forRepository: aRepository [

	^ self new
		  repository: aRepository;
		  yourself
]

{ #category : 'accessing' }
BlennyBlacklistCleaner >> intervalSeconds: anInteger [

	(anInteger isInteger and: [ anInteger > 0 ])
		ifTrue: [ intervalSeconds := anInteger ]
		ifFalse: [ self error: 'intervalSeconds must be a positive integer' ]
]

{ #category : 'testing' }
BlennyBlacklistCleaner >> isStarted [
    ^ process notNil and: [ process isTerminated not ]

]

{ #category : 'cleanup' }
BlennyBlacklistCleaner >> performCleanup [

	[ repository ifNotNil: [ repository cleanupExpiredBlacklist ] ]
		on: Error
		do: [ :ex |
				StringSignal emit:
					('BlennyBlacklistCleaner error: {1}' format: { ex messageText }) ]
]

{ #category : 'cleanup' }
BlennyBlacklistCleaner >> performCleanupWithErrorHandling [
	"Run one cleanup immediately, then loop at interval while isRunning."

	self performCleanup.
	[ isRunning ] whileTrue: [
			(Delay forSeconds: intervalSeconds) wait.
			isRunning ifTrue: [ self performCleanup ] ]
]

{ #category : 'accessing' }
BlennyBlacklistCleaner >> repository: aRepository [

	repository := aRepository
]

{ #category : 'accessing' }
BlennyBlacklistCleaner >> start [

	intervalSeconds ifNil: [ intervalSeconds := 300 ].
	isRunning := true.
	process := [ self performCleanupWithErrorHandling ]
		           forkAt: Processor userBackgroundPriority
		           named: 'BlennyBlacklistCleaner'.
	StringSignal emit: 'BlennyBlacklistCleaner started (interval: '
		, intervalSeconds asString , 's)'
]

{ #category : 'accessing' }
BlennyBlacklistCleaner >> stop [
    isRunning ifFalse: [ ^ self ].
    isRunning := false.
    "Give the process time to finish the current cleanup"
    process ifNotNil: [
        (Delay forMilliseconds: 2000) wait.
        process ifNotNil: [
            process terminate.
            process := nil ] ].
    StringSignal emit: 'BlennyBlacklistCleaner stopped'.
]
