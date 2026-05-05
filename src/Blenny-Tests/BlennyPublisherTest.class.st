Class {
	#name : 'BlennyPublisherTest',
	#superclass : 'TestCase',
	#category : 'Blenny-Tests',
	#package : 'Blenny-Tests'
}

{ #category : 'tests' }
BlennyPublisherTest >> testNoRunningApp [
   "Ensure no running app is present, then verify that currentWebApp raises an error"
   BlennyWebApp allInstances do: [ :app | app stop ].
   BlennyPublisher reset.
   self should: [ BlennyPublisher currentWebApp ] raise: Error.

]

{ #category : 'tests' }
BlennyPublisherTest >> testReset [
    BlennyPublisher reset.
    self assert: true.  "Just ensure no error"
]
