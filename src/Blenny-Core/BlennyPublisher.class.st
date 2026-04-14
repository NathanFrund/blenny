Class {
	#name : 'BlennyPublisher',
	#superclass : 'Object',
	#classInstVars : [
		'CurrentWebApp'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'publishing' }
BlennyPublisher class >> broadcastData: aString [
    ^ self currentWebApp broadcastData: aString
]

{ #category : 'publishing' }
BlennyPublisher class >> broadcastHtml: aString [
    ^ self currentWebApp broadcastHtml: aString
]

{ #category : 'private' }
BlennyPublisher class >> currentWebApp [
    "Find the running BlennyWebApp instance"
    CurrentWebApp ifNil: [
        CurrentWebApp := BlennyWebApp allInstances 
            detect: [ :each | each server notNil ]
            ifNone: [ self error: 'No running BlennyWebApp found' ] ].
    ^ CurrentWebApp
]

{ #category : 'publishing' }
BlennyPublisher class >> directData: aString toUser: aUserId [
    ^ self currentWebApp directData: aString toUser: aUserId

]

{ #category : 'publishing' }
BlennyPublisher class >> directHtml: aString toUser: aUserId [
    ^ self currentWebApp directHtml: aString toUser: aUserId
]

{ #category : 'publishing' }
BlennyPublisher class >> reset [
    "Reset cached web app (useful for testing)"
    CurrentWebApp := nil
]
