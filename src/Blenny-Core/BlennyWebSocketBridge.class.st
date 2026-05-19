"
I am the bridge between the Announcer pub/sub system and WebSocket clients.

I manage WebSocket connections for a single endpoint (either '/ws/html' or '/ws/data').

My responsibilities:
- Track connected clients by userId and connection ID
- Subscribe to announcement classes (HTMLBroadcast, HTMLDirect, DataBroadcast, DataDirect)
- Broadcast messages to all connected clients
- Send direct messages to specific users
- Handle WebSocket lifecycle (connect, disconnect, read loop)

I am created per endpoint by BlennyWebApp:
    htmlBridge := BlennyAnnouncerBridge new initializeWithEndpoint: 'html'.
    dataBridge := BlennyAnnouncerBridge new initializeWithEndpoint: 'data'.

Usage:
    ""Broadcast to all HTML clients""
    htmlBridge broadcastHtml: '<div>Hello</div>'.
    
    ""Direct message to specific user""
    htmlBridge directHtml: '<div>Private</div>' to: 'alice'.

I use a dictionary-based client store:
    clientsById: connection ID → client info
    clientsByUserId: user ID → collection of client info
"
Class {
	#name : 'BlennyWebSocketBridge',
	#superclass : 'BlennyTransportBridge',
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'utilities - objectiveC' }
BlennyWebSocketBridge >> sendMessage: aMessage to: aWebSocket [
    | category payload |
    category := aMessage at: #category ifAbsent: [#ui].
    payload := aMessage at: #html ifAbsent: [ aMessage at: #signals ifAbsent: [ nil ] ].
    payload ifNil: [ ^ self ].
    
    category = #ui
        ifTrue: [ aWebSocket sendMessage: payload ]   "raw HTML"
        ifFalse: [ aWebSocket sendMessage: (NeoJSONWriter toString: aMessage) ]
]

{ #category : 'accessing' }
BlennyWebSocketBridge >> stop [
    "Close all WebSocket connections to break read loops before finalization"
    connectionsByUserId do: [ :userDict |
        userDict valuesDo: [ :handle |
            handle stream ifNotNil: [ :ws |
                [ ws close ] on: Error do: [ :ex |
                    StringSignal emit: ('WS close error: {1}' format: { ex messageText }) ] ] ] ].
    super stop.   "now finalize all handles (will close streams again, but that's fine)"
]
