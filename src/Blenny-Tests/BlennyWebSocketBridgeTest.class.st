Class {
	#name : 'BlennyWebSocketBridgeTest',
	#superclass : 'TestCase',
	#instVars : [
		'bridge'
	],
	#category : 'Blenny-Tests',
	#package : 'Blenny-Tests'
}

{ #category : 'running' }
BlennyWebSocketBridgeTest >> setUp [
   bridge := BlennyWebSocketBridge new initializeWithName: 'test-ws'.
]

{ #category : 'tests' }
BlennyWebSocketBridgeTest >> testAddAndRemoveClient [
   "Requires a real ZnWebSocket or a proper mock. Will be revisited when WebSocket sidecar is re-enabled."
   self skip.
]

{ #category : 'tests' }
BlennyWebSocketBridgeTest >> testInitialization [
   self assert: bridge transportName equals: 'test-ws'.
   self assert: bridge isRunning.
]
