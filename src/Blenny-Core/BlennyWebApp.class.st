Class {
	#name : 'BlennyWebApp',
	#superclass : 'Object',
	#traits : 'TConduitRenderer + THtmxRenderer',
	#classTraits : 'TConduitRenderer classTrait + THtmxRenderer classTrait',
	#instVars : [
		'conduit',
		'rootPath',
		'server',
		'port'
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

{ #category : 'accessing' }
BlennyWebApp >> conduit [
	^ conduit
]

{ #category : 'accessing' }
BlennyWebApp >> conduit: aConduit [
conduit := aConduit 
]

{ #category : 'websocket' }
BlennyWebApp >> handleWebSocket: aWebSocket [
    Transcript show: '!!! WebSocket Connected'; cr.
    
    [ aWebSocket isConnected ] whileTrue: [
        | message |
        [ 
            "1. Robust Read: Catch the internal Zinc error immediately"
            message := [ aWebSocket readMessage ] on: Error do: [ :ex | 
                Transcript show: '!!! Zinc Internal Close: ', ex description; cr.
                ^ self ]. "Exit immediately on ANY error during read"

            "2. If message is nil, the stream ended normally"
            message ifNil: [ 
                Transcript show: '!!! Client disconnected'; cr.
                ^ self ].

            "3. Safe Processing"
            Transcript show: 'Received: ', message asString; cr.
            aWebSocket sendMessage: 'Echo: ', message asString.

        ] on: Error do: [ :ex | 
            Transcript show: 'Outer loop catch: ', ex description; cr.
            ^ self 
        ].
        (Delay forMilliseconds: 20) wait.
    ].
    
    Transcript show: '!!! WebSocket Closed'; cr.
]

{ #category : 'initialization' }
BlennyWebApp >> initialize [
    super initialize.
    port := 8081.
]

{ #category : 'module-loading' }
BlennyWebApp >> loadModulesInto: aDispatcher [
    "Discover and load all modules"
    (Smalltalk allClasses select: [ :cls |
        cls includesBehavior: TBlennyModule ]) do: [ :moduleClass |
            moduleClass registerRoutesOn: aDispatcher ].
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
    self startUnifiedServer.
    self announceStarted.
]

{ #category : 'server' }
BlennyWebApp >> startUnifiedServer [
    | delegate |
    "Cleanup old servers on this port"
    ZnServer allInstancesDo: [ :s | s port = port ifTrue: [ s stop ] ].
    
    "Initialize your custom delegate with the app state"
    delegate := BlennyStaticDelegate new
        rootPath: rootPath; "Passed from BlennyWebApp instance variable"
        webApp: self;       "Allows delegate to call self renderPage:"
        yourself.
    
    "Start Zinc using the custom delegate object"
    server := (ZnServer on: port)
        delegate: delegate;
        start.
    
    Transcript show: 'Blenny server started on port ', port asString, ' with custom delegate.'; cr.
]

{ #category : 'public' }
BlennyWebApp >> stop [
    "Completely stop the server and clean up"
    
    server ifNotNil: [ 
        server stop.
        server := nil ].
    conduit ifNotNil: [ 
        conduit stop.
        conduit := nil ].
    
    "Force cleanup of any lingering servers"
    ZnServer allInstancesDo: [ :s | 
        s isRunning ifTrue: [ s stop ] ].
    
    Teapot stopAll.
    Smalltalk garbageCollect.
    
    Transcript show: 'Blenny server stopped.'; cr.

]
