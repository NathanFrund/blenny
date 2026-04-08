Class {
	#name : 'BlennyAnnouncerBridge',
	#superclass : 'Object',
	#instVars : [
		'announcer',
		'endpoint',
		'clientsByUserId',
		'clientsById',
		'isRunning'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'handlers' }
BlennyAnnouncerBridge >> broadcastData: aPayload [
	"Broadcast JSON to all data clients"

	clientsById values asArray do: [ :client |
			(client endpoint = 'data' and: [ client isClosed not ]) ifTrue: [
					[ client sendMessage: aPayload ]
						on: Error
						do: [ :ex |
								Transcript
									show: 'Data broadcast failed: ' , ex description;
									cr ] ] ]
]

{ #category : 'handlers' }
BlennyAnnouncerBridge >> broadcastHtml: aPayload [
    "Broadcast HTML to all HTML clients"
    clientsById values asArray do: [ :client |
        (client endpoint = 'html' and: [ client isClosed not ]) ifTrue: [
            [ client sendMessage: aPayload ]  "Use client's sendMessage, not socket directly"
                on: Error
                do: [ :ex |
                    Transcript
                        show: 'HTML broadcast failed: ' , ex description;
                        cr ] ] ]
]

{ #category : 'as yet unclassified' }
BlennyAnnouncerBridge >> connectedCount [
    ^ clientsById size
]

{ #category : 'handlers' }
BlennyAnnouncerBridge >> directData: aPayload to: aUserId [
	"Send JSON directly to a specific user"

	(clientsByUserId at: aUserId ifAbsent: [ #(  ) ]) asArray do: [
			:client |
			(client endpoint = 'data' and: [ client isClosed not ]) ifTrue: [
					[ client sendMessage: aPayload ]
						on: Error
						do: [ :ex |
								Transcript
									show: 'Data direct failed: ' , ex description;
									cr ] ] ]
]

{ #category : 'handlers' }
BlennyAnnouncerBridge >> directHtml: aPayload to: aUserId [
	"Send HTML directly to a specific user"

	(clientsByUserId at: aUserId ifAbsent: [ #(  ) ]) asArray do: [
			:client |
			(client endpoint = 'html' and: [ client isClosed not ]) ifTrue: [
					[ client sendMessage: aPayload ]
						on: Error
						do: [ :ex |
								Transcript
									show: 'HTML direct failed: ' , ex description;
									cr ] ] ]
]

{ #category : 'as yet unclassified' }
BlennyAnnouncerBridge >> fanOut: aMessage to: aTopic [
    "Broadcast to all connected clients - copy collection to avoid modification during iteration"
    clientsById copy valuesDo: [ :client |
        client isClosed ifFalse: [
            [ client sendMessage: aMessage payload ]
                on: Error
                do: [ :ex | Transcript show: 'Broadcast failed: ', ex description; cr ] ] ]
]

{ #category : 'as yet unclassified' }
BlennyAnnouncerBridge >> fanOutDirect: aMessage to: aTopic [
    "Extract user ID from topic and send only to that user"
    | userId prefix recipients |
    prefix := 'ws.', endpoint, '.direct.'.
    userId := aTopic copyFrom: prefix size + 1.
    recipients := clientsByUserId at: userId ifAbsent: [ #() ].
    
    "Copy to avoid modification during iteration"
    recipients copy do: [ :client |
        client isClosed ifFalse: [
            [ client sendMessage: aMessage payload ]
                on: Error
                do: [ :ex | Transcript show: 'Direct send failed: ', ex description; cr ] ] ]
]

{ #category : 'as yet unclassified' }
BlennyAnnouncerBridge >> handleWebSocket: aWebSocket forUser: aUserId [
    | client |

	Transcript show: '=== HANDLE WEBSOCKET START ==='; cr.
    Transcript show: 'User: ', aUserId, ' Endpoint: ', endpoint; cr.

    client := BlennyWebSocketClient new
    userId: aUserId 
    endpoint: endpoint 
    socket: aWebSocket 
    bridge: self.

Transcript show: 'Client created. ID: ', client id; cr.
    Transcript show: 'Client userId: ', client userId; cr.
    Transcript show: 'Client endpoint: ', client endpoint; cr.
    
    "Store the client"
    clientsById at: client id put: client.
    (clientsByUserId at: aUserId ifAbsentPut: [ OrderedCollection new ]) add: client.

 Transcript show: 'ClientsById size: ', clientsById size asString; cr.
    Transcript show: 'ClientsByUserId size: ', clientsByUserId size; cr.
    Transcript show: '=== HANDLE WEBSOCKET END ==='; cr.

Transcript show: 'Connection established, keeping open...'; cr.
^ self.
    
"    ""Start the read loop with defensive error handling""
    [ 
    [ 
        aWebSocket runWith: [ :message |
            ""Optional: handle incoming messages from client""
            message ifNotNil: [
                Transcript show: 'Message from ', aUserId, ': ', message; cr.
                ""Uncomment when BlennyClientMessage is created""
                ""announcer announce: (BlennyClientMessage new
                    fromUserId: aUserId;
                    payload: message;
                    yourself)"" ]
        ]
    ] on: Error do: [ :ex |
        Transcript show: 'Bridge read error for ', aUserId, ': ', ex description; cr. ]
] ensure: [
    self unregisterClient: client.
    Transcript show: 'Client disconnected: ', aUserId; cr.
]"
]

{ #category : 'initialization' }
BlennyAnnouncerBridge >> initialize [ 
	super initialize.
	clientsByUserId  := Dictionary new.
	clientsById := Dictionary new.
]

{ #category : 'initialization' }
BlennyAnnouncerBridge >> initializeWithEndpoint: aString [
    endpoint := aString.
    announcer := Announcer new.
    clientsByUserId := Dictionary new.
    clientsById := Dictionary new.
    isRunning := true.

    "Subscribe to each announcement class"
    announcer
        weak
        when: BlennyHTMLBroadcast
        do: [ :ann | self broadcastHtml: ann payload ]
        for: self.

    announcer
        weak
        when: BlennyHTMLDirect
        do: [ :ann | self directHtml: ann payload to: ann recipientUserId ]
        for: self.

    announcer
        weak
        when: BlennyDataBroadcast
        do: [ :ann | self broadcastData: ann payload ]
        for: self.

    announcer
        weak
        when: BlennyDataDirect
        do: [ :ann | self directData: ann payload to: ann recipientUserId ]
        for: self.

    ^ self

]

{ #category : 'publishing' }
BlennyAnnouncerBridge >> publish: anAnnouncement [
    isRunning ifFalse: [ ^ self ].
    announcer announce: anAnnouncement
]

{ #category : 'accessing' }
BlennyAnnouncerBridge >> stop [
    isRunning := false.
    
    "Unsubscribe from all announcements"
    announcer unsubscribe: self.
    
    "Close all client connections"
    clientsById copy valuesDo: [ :client |
        [ client close ] on: Error do: [ :ex | ] ].
    
    "Clear collections"
    clientsById removeAll.
    clientsByUserId removeAll.
    
    Transcript show: 'Bridge stopped for endpoint: ', endpoint; cr.
]

{ #category : 'subscription' }
BlennyAnnouncerBridge >> subscribeTo: aTopic [
    "Single subscriber per topic - this is the bridge"
    announcer when: aTopic do: [ :message |
        isRunning ifTrue: [ self fanOut: message to: aTopic ] ]

]

{ #category : 'as yet unclassified' }
BlennyAnnouncerBridge >> subscribeToPattern: aPattern [
    "Handle direct messages like ws.html.direct.user123"
    announcer when: aPattern do: [ :message |
        isRunning ifTrue: [
            | topic |
            topic := message topic.
            (topic beginsWith: ('ws.', endpoint, '.direct.')) ifTrue: [
                self fanOutDirect: message to: topic ] ] ]
]

{ #category : 'as yet unclassified' }
BlennyAnnouncerBridge >> unregisterClient: aClient [
    aClient isClosed ifTrue: [ ^ self ].
    aClient close.
    
    clientsById removeKey: aClient id ifAbsent: [].
    (clientsByUserId at: aClient userId ifAbsent: [ ^ self ]) 
        remove: aClient 
        ifAbsent: [].
        
    "Clean up empty user entries"
    (clientsByUserId at: aClient userId ifAbsent: [ #() ]) ifEmpty: [
        clientsByUserId removeKey: aClient userId ifAbsent: [] ].
]
