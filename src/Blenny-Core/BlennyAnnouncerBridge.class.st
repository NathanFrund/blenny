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

{ #category : 'client management' }
BlennyAnnouncerBridge >> addClient: aWebSocket forUser: aUserId [
    | userClients clientInfo |
    
    userClients := clientsByUserId at: aUserId ifAbsentPut: [ OrderedCollection new ].
    clientInfo := { 'socket' -> aWebSocket. 'endpoint' -> endpoint } asDictionary.
    userClients add: clientInfo.
    clientsById at: aWebSocket hash put: clientInfo.
    
    Transcript show: 'Bridge CONNECTED: ', aUserId, ' [', endpoint, '] (Total users: ', clientsByUserId size asString, ')'; cr.
    
    "Send welcome message"
    aWebSocket sendMessage: 'Welcome ', aUserId, ' (', endpoint, ' endpoint)'.
    
    ^ clientInfo
]

{ #category : 'client management' }
BlennyAnnouncerBridge >> allClients [
    ^ clientsById values
]

{ #category : 'handlers' }
BlennyAnnouncerBridge >> broadcastData: aPayload [
    "Broadcast JSON to all data clients connected to this bridge"
    self allClients do: [ :clientInfo |
        [ (clientInfo at: 'socket') sendMessage: aPayload ]
            on: Error
            do: [ :ex | 
                Transcript show: 'Data broadcast failed: ', ex description; cr ] ]
]

{ #category : 'handlers' }
BlennyAnnouncerBridge >> broadcastHtml: aPayload [
    "Broadcast HTML to all HTML clients connected to this bridge"
    self allClients do: [ :clientInfo |
        [ (clientInfo at: 'socket') sendMessage: aPayload ]
            on: Error
            do: [ :ex | 
                Transcript show: 'HTML broadcast failed: ', ex description; cr ] ]
]

{ #category : 'client management' }
BlennyAnnouncerBridge >> clientConnectionsForUser: aUserId [
    ^ clientsByUserId at: aUserId ifAbsent: [ #() ]
]

{ #category : 'as yet unclassified' }
BlennyAnnouncerBridge >> connectedCount [
    ^ clientsById size
]

{ #category : 'handlers' }
BlennyAnnouncerBridge >> directData: aPayload to: aUserId [
    "Send JSON directly to a specific user"
    | clients |
    clients := self clientConnectionsForUser: aUserId.
    clients do: [ :clientInfo |
        [ (clientInfo at: 'socket') sendMessage: aPayload ]
            on: Error
            do: [ :ex | 
                Transcript show: 'Data direct failed: ', ex description; cr ] ]
]

{ #category : 'handlers' }
BlennyAnnouncerBridge >> directHtml: aPayload to: aUserId [
    "Send HTML directly to a specific user"
    | clients |
    clients := self clientConnectionsForUser: aUserId.
    clients do: [ :clientInfo |
        [ (clientInfo at: 'socket') sendMessage: aPayload ]
            on: Error
            do: [ :ex | 
                Transcript show: 'HTML direct failed: ', ex description; cr ] ]
]

{ #category : 'handlers' }
BlennyAnnouncerBridge >> handleWebSocket: aWebSocket forUser: aUserId [
    | clientInfo |
    
    "Add client to this bridge"
    clientInfo := self addClient: aWebSocket forUser: aUserId.
    
    "Start the read loop"
    [ aWebSocket runWith: [ :message |
        message ifNotNil: [
            Transcript show: aUserId, ' [', endpoint, ']: ', message asString; cr.
            aWebSocket sendMessage: 'Echo: ', message asString ] ] ]
    ensure: [
        "Cleanup on disconnect"
        self removeClient: aWebSocket forUser: aUserId ]
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

{ #category : 'client management' }
BlennyAnnouncerBridge >> removeClient: aWebSocket forUser: aUserId [
    | clientInfo userClients |
    
    clientInfo := clientsById at: aWebSocket hash ifAbsent: [ ^ self ].
    userClients := clientsByUserId at: aUserId ifAbsent: [ ^ self ].
    
    userClients remove: clientInfo ifAbsent: [].
    clientsById removeKey: aWebSocket hash ifAbsent: [].
    
    userClients ifEmpty: [ clientsByUserId removeKey: aUserId ifAbsent: [] ].
    
    Transcript show: 'Bridge DISCONNECTED: ', aUserId, ' [', endpoint, '] (Remaining: ', clientsByUserId size asString, ')'; cr.
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
