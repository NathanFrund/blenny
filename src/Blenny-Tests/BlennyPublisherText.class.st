Class {
	#name : 'BlennyPublisherText',
	#superclass : 'TestCase',
	#category : 'Blenny-Tests',
	#package : 'Blenny-Tests'
}

{ #category : 'tests' }
BlennyPublisherText >> testReset [
    "Just test that reset doesn't crash"
    BlennyPublisher reset.
    self assert: true.
]
