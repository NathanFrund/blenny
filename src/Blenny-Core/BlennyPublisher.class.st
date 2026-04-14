"
I allow any Pharo object to publish WebSocket messages without knowing about Blenny.

Any code in your image can send real-time updates:
    BlennyPublisher broadcastHtml: '<div>Hello</div>'
    BlennyPublisher broadcastData: '{""type"": ""update""}'
    BlennyPublisher directHtml: 'Private message' toUser: 'alice'

I automatically find the running BlennyWebApp instance and delegate to it.

My methods are all class-side, so you never need to create an instance:
    BlennyPublisher broadcastHtml: '...'

For testing, you can reset the cached web app reference:
    BlennyPublisher reset.

I am the simplest way to push real-time updates from any part of your Pharo image.
"
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

{ #category : 'public' }
BlennyPublisher class >> reset [
    "Reset cached web app (useful for testing)"
    CurrentWebApp := nil
]
