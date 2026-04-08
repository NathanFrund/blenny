Class {
	#name : 'BlennyWebApp',
	#superclass : 'Object',
	#traits : 'TConduitRenderer + THtmxRenderer',
	#classTraits : 'TConduitRenderer classTrait + THtmxRenderer classTrait',
	#instVars : [
		'conduit',
		'rootPath',
		'server',
		'port',
		'connectedClients',
		'htmlBridge',
		'dataBridge'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'announcements' }
BlennyWebApp >> announceStarted [
    | mode |
    mode := rootPath ifNil: [ 'frozen' ] ifNotNil: [ 'disk' ].
    Transcript 
        nextPutAll: 'Blenny server started on port ';
        nextPutAll: port asString;
        nextPutAll: ' (', mode, ' mode)';
        cr.
]

{ #category : 'as yet unclassified' }
BlennyWebApp >> broadcast: aMessage [
    "Send to all clients regardless of endpoint"
    | count |
    count := 0.
    connectedClients valuesDo: [ :clients |
        clients do: [ :clientInfo |
            [ (clientInfo at: 'socket') sendMessage: aMessage ]
                on: Error
                do: [ :ex | Transcript show: 'Broadcast failed: ', ex description; cr ].
            count := count + 1 ] ].
    Transcript show: 'Broadcast to ', count asString, ' clients: ', aMessage; cr.
]

{ #category : 'as yet unclassified' }
BlennyWebApp >> broadcast: aMessage toEndpoint: aString [
    "Send to all clients connected to a specific endpoint"
    | count |
    count := 0.
    connectedClients valuesDo: [ :clients |
        clients do: [ :clientInfo |
            (clientInfo at: 'endpoint') = aString ifTrue: [
                [ (clientInfo at: 'socket') sendMessage: aMessage ]
                    on: Error
                    do: [ :ex | Transcript show: 'Broadcast failed: ', ex description; cr ].
                count := count + 1 ] ] ].
    Transcript show: 'Broadcast to ', count asString, ' [', aString, '] clients: ', aMessage; cr.
]

{ #category : 'publishing' }
BlennyWebApp >> broadcastData: aString [
    self broadcast: aString toEndpoint: 'data'
]

{ #category : 'publishing' }
BlennyWebApp >> broadcastHtml: aString [
    self htmlBridge publish: (BlennyHTMLBroadcast payload: aString)
]

{ #category : 'accessing' }
BlennyWebApp >> conduit [
	^ conduit
]

{ #category : 'accessing' }
BlennyWebApp >> conduit: aConduit [
conduit := aConduit 
]

{ #category : 'accessing' }
BlennyWebApp >> dataBridge [
	^ dataBridge
]

{ #category : 'accessing' }
BlennyWebApp >> dataBridge: aBridge [
	dataBridge := aBridge 
]

{ #category : 'as yet unclassified' }
BlennyWebApp >> direct: aMessage toUser: aUserId [
    "Send a message to a specific user"
    | clients count |
    clients := connectedClients at: aUserId ifAbsent: [ 
        Transcript show: 'Direct message failed - user not connected: ', aUserId; cr.
        ^ self ].
    
    count := 0.
    clients do: [ :socket |
        [ socket sendMessage: aMessage ]
            on: Error
            do: [ :ex | 
                Transcript show: 'Direct message failed for ', aUserId, ': ', ex description; cr ].
        count := count + 1 ].
    
    Transcript show: 'Direct message to ', aUserId, ' (', count asString, ' connections): ', aMessage; cr.
]

{ #category : 'as yet unclassified' }
BlennyWebApp >> direct: aMessage toUser: aUserId endpoint: aString [
    "Send to specific user on specific endpoint"
    | clients count |
    clients := connectedClients at: aUserId ifAbsent: [ 
        Transcript show: 'Direct failed - user not connected: ', aUserId; cr.
        ^ self ].
    
    count := 0.
    clients do: [ :clientInfo |
        (clientInfo at: 'endpoint') = aString ifTrue: [
            [ (clientInfo at: 'socket') sendMessage: aMessage ]
                on: Error
                do: [ :ex | 
                    Transcript show: 'Direct failed for ', aUserId, ': ', ex description; cr ].
            count := count + 1 ] ].
    
    Transcript show: 'Direct to ', aUserId, ' [', aString, '] (', count asString, ' conns): ', aMessage; cr.
]

{ #category : 'publishing' }
BlennyWebApp >> directData: aString toUser: aUserId [
    self direct: aString toUser: aUserId endpoint: 'data'
]

{ #category : 'publishing' }
BlennyWebApp >> directHtml: aString toUser: aUserId [
    self htmlBridge publish: (BlennyHTMLDirect payload: aString toUser: aUserId)
]

{ #category : 'as yet unclassified' }
BlennyWebApp >> extractEndpointFromPath: aPath [
    aPath = '/ws/html' ifTrue: [ ^ 'html' ].
    aPath = '/ws/data' ifTrue: [ ^ 'data' ].
    ^ nil
]

{ #category : 'as yet unclassified' }
BlennyWebApp >> handleWebSocket: aWebSocket forUser: aUserId [
    aUserId ifNil: [ 
        aWebSocket sendMessage: 'Error: Missing userId parameter'; close.
        ^ self ].
    
    "Store client"
    (connectedClients at: aUserId ifAbsentPut: [ OrderedCollection new ]) add: aWebSocket.
    
    Transcript show: 'Client CONNECTED: ', aUserId, ' (Total users: ', connectedClients size asString, ')'; cr.
    
    "ADD THIS LINE - Send welcome message"
    aWebSocket sendMessage: 'Welcome to Blenny!! User: ', aUserId.
    
    "Optional: Also send 'Connected as:' if you want both"
    "aWebSocket sendMessage: 'Connected as: ', aUserId."
    
    [ aWebSocket runWith: [ :message |
        Transcript show: aUserId, ': ', message asString; cr.
        aWebSocket sendMessage: 'Echo: ', message asString ] ]
    ensure: [
        (connectedClients at: aUserId ifAbsent: [ ^ self ]) remove: aWebSocket ifAbsent: [].
        (connectedClients at: aUserId ifAbsent: [ #() ]) ifEmpty: [ 
            connectedClients removeKey: aUserId ].
        Transcript show: 'Client DISCONNECTED: ', aUserId, ' (Remaining users: ', connectedClients size asString, ')'; cr. ]
]

{ #category : 'as yet unclassified' }
BlennyWebApp >> handleWebSocket: aWebSocket forUser: aUserId endpoint: aString [
    | userClients clientInfo |
    
    aUserId ifNil: [ 
        aWebSocket sendMessage: 'Error: Missing userId parameter'; close.
        ^ self ].
    
    "Store client with endpoint info"
    userClients := connectedClients at: aUserId ifAbsentPut: [ OrderedCollection new ].
    clientInfo := { 'socket' -> aWebSocket. 'endpoint' -> aString } asDictionary.
    userClients add: clientInfo.
    
    Transcript show: 'CONNECTED: ', aUserId, ' [', aString, '] (Total users: ', connectedClients size asString, ')'; cr.
    
    aWebSocket sendMessage: 'Welcome ', aUserId, ' (', aString, ' endpoint)'.
    
    [ aWebSocket runWith: [ :message |
        Transcript show: aUserId, ' [', aString, ']: ', message asString; cr.
        aWebSocket sendMessage: 'Echo: ', message asString ] ]
    ensure: [
        userClients remove: clientInfo ifAbsent: [].
        userClients ifEmpty: [ connectedClients removeKey: aUserId ifAbsent: [] ].
        Transcript show: 'DISCONNECTED: ', aUserId, ' [', aString, '] (Remaining: ', connectedClients size asString, ')'; cr. ]

]

{ #category : 'accessing' }
BlennyWebApp >> htmlBridge [
	^ htmlBridge 
]

{ #category : 'accessing' }
BlennyWebApp >> htmlBridge: aBridge [
	htmlBridge := aBridge 
]

{ #category : 'initialization' }
BlennyWebApp >> initialize [
    super initialize.
    port := 8081.
    connectedClients := Dictionary new.
]

{ #category : 'module-loading' }
BlennyWebApp >> loadModulesInto: aDispatcher [
    "Discover and load all modules"
    (Smalltalk allClasses select: [ :cls |
        cls includesBehavior: TBlennyModule ]) do: [ :moduleClass |
            moduleClass registerRoutesOn: aDispatcher ].
]

{ #category : 'accessing' }
BlennyWebApp >> pubSub [
	^ BlennyPubSub current
]

{ #category : 'actions' }
BlennyWebApp >> serveFrozenAsset: aPathString [
    | fileRef methodName content |
    fileRef := aPathString asFileReference.
    methodName := ('frozenAsset', fileRef base capitalized, fileRef extension capitalized) asSymbol.
    
    content := nil.
    (self respondsTo: methodName) ifTrue: [ 
        content := self perform: methodName ].
    
    content ifNotNil: [
        ^ ZnResponse ok: (ZnEntity 
            with: content 
            type: (ZnMimeType 
                forFilenameExtension: fileRef extension 
                ifAbsent: [ ZnMimeType applicationOctetStream ])) ].
    
    ^ ZnResponse notFound: aPathString
]

{ #category : 'private' }
BlennyWebApp >> setModeFromPath: aPath [
    aPath ifNil: [ 
        rootPath := nil.
        conduit := nil.
        ^ self ].
    rootPath := aPath asFileReference.
    self setupDiskWatcher.
]

{ #category : 'private' }
BlennyWebApp >> setupDiskWatcher [
    | templatesPath |
    templatesPath := rootPath / 'templates'.
    templatesPath exists ifFalse: [ ^ self ].
    conduit := Conduit pointingAt: templatesPath pathString.
    conduit start.
]

{ #category : 'public' }
BlennyWebApp >> startOn: aPath [
    self startOn: aPath port: port.
]

{ #category : 'public' }
BlennyWebApp >> startOn: aPath port: aPortNumber [
    self stop.
    port := aPortNumber.
    rootPath := aPath ifNotNil: [ aPath asFileReference ].
    
    rootPath ifNotNil: [ self setupDiskWatcher ].
    self startServer.
    self announceStarted.
]

{ #category : 'as yet unclassified' }
BlennyWebApp >> startServer [
    | delegate |
    ZnServer allInstancesDo: [ :s | s port = port ifTrue: [ s stop ] ].

"Create bridges"
    htmlBridge := BlennyAnnouncerBridge new initializeWithEndpoint: 'html'.
    dataBridge := BlennyAnnouncerBridge new initializeWithEndpoint: 'data'.
    
    delegate := BlennyRouter new
        rootPath: rootPath;
			htmlBridge: htmlBridge;
			dataBridge: dataBridge ;
        webApp: self.
    
    server := (ZnServer on: port)
        delegate: delegate;
        start.

"Store bridges for later use"
    self htmlBridge: htmlBridge.
    self dataBridge: dataBridge.
    
    Transcript show: '========================================'; cr.
    Transcript show: 'Blenny server started on port ', port asString; cr.
    Transcript show: 'HTML WebSocket: ws://localhost:', port asString, '/ws/html'; cr.
    Transcript show: 'Data WebSocket: ws://localhost:', port asString, '/ws/data'; cr.
    Transcript show: '========================================'; cr.
]

{ #category : 'accessing' }
BlennyWebApp >> stop [
    server ifNotNil: [ 
        server stop.
        server := nil ].
    conduit ifNotNil: [ 
        conduit stop.
        conduit := nil ].
    connectedClients removeAll.
    Transcript show: 'Blenny server stopped.'; cr.
]
