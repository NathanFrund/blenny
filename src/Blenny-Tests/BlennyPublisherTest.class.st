Class {
	#name : 'BlennyPublisherTest',
	#superclass : 'TestCase',
	#category : 'Blenny-Tests',
	#package : 'Blenny-Tests'
}

{ #category : 'tests' }
BlennyPublisherTest >> testNoRunningApp [
    "Reset the cached app"
    BlennyPublisher reset.
    "Without running app, currentWebApp should error"
    self should: [ BlennyPublisher currentWebApp ] raise: Error.

]

{ #category : 'tests' }
BlennyPublisherTest >> testReset [
    BlennyPublisher reset.
    self assert: true.  "Just ensure no error"
]
