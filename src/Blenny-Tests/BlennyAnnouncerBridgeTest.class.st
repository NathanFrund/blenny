Class {
	#name : 'BlennyAnnouncerBridgeTest',
	#superclass : 'TestCase',
	#instVars : [
		'bridge'
	],
	#category : 'Blenny-Tests',
	#package : 'Blenny-Tests'
}

{ #category : 'running' }
BlennyAnnouncerBridgeTest >> setUp [
    bridge := BlennyAnnouncerBridge new initializeWithEndpoint: 'html'.
]

{ #category : 'tests' }
BlennyAnnouncerBridgeTest >> testAddAndRemoveClient [
    "Skip - requires real WebSocket or proper mock"
    self skip.
]

{ #category : 'tests' }
BlennyAnnouncerBridgeTest >> testInitialization [
    self assert: bridge endpoint equals: 'html'.
    self assert: bridge isRunning equals: true.
]
