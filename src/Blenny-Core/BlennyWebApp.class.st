"
I am the main entry point for a Blenny application.

I manage:
- HTTP/WebSocket server lifecycle (start/stop)
- Authentication provider
- Template rendering (via Conduit)
- Module discovery and loading
- Configuration (via BlennyConfig)

Example usage:
    app := BlennyWebApp new.
    app startOn: nil port: 8081.
    BlennyPublisher broadcastHtml: '<div>Hello</div>'.

To stop:
    app stop.
"
Class {
	#name : 'BlennyWebApp',
	#superclass : 'Object',
	#instVars : [
		'server',
		'port',
		'rootPath',
		'conduit',
		'authProvider',
		'renderer',
		'registerHandler',
		'loginHandler',
		'logoutHandler',
		'sseBridge',
		'optionalTransports',
		'modules',
		'router'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'accessing' }
BlennyWebApp class >> default [
   "Answer the most recently started BlennyWebApp, or nil if none is running."
   | apps |
   apps := self allInstances select: [ :each | each server notNil and: [ each server isRunning ] ].
   ^ apps ifNotEmpty: [ apps last ] ifEmpty: [ nil ]
]

{ #category : 'server' }
BlennyWebApp >> announceStarted [

	| mode |
	mode := rootPath ifNil: [ 'frozen' ] ifNotNil: [ 'disk' ].
	StringSignal emit:
		('Server started on port {1} ({2} mode). SSE: http://localhost:{1}/sse'
			 format: {
					 port.
					 mode })
]

{ #category : 'accessing' }
BlennyWebApp >> authProvider [
    ^ authProvider
]

{ #category : 'broadcasting' }
BlennyWebApp >> broadcast: aMessage toUser: aUserId [

	| allTransports |
	allTransports := { sseBridge } , optionalTransports.
	allTransports do: [ :transport |
			(transport hasConnectionForUser: aUserId) ifTrue: [
					[ transport directMessage: aMessage to: aUserId ]
						on: Error
						do: [ :e |
								StringSignal emit: ('{1} failed for user {2}: {3}' format: {
											 transport transportName.
											 aUserId.
											 e messageText }) ] ] ].
	^ self
]

{ #category : 'publishing' }
BlennyWebApp >> broadcastData: aString [
    self broadcastMessage: (Dictionary with: #signals -> aString with: #category -> #ui)
]

{ #category : 'publishing' }
BlennyWebApp >> broadcastHtml: aString [
    self broadcastMessage: (Dictionary with: #html -> aString with: #category -> #ui)
]

{ #category : 'broadcasting' }
BlennyWebApp >> broadcastMessage: aMessage [

	{ sseBridge } , optionalTransports do: [ :transport |
			[ transport broadcastMessage: aMessage ]
				on: Error
				do: [ :e |
						StringSignal emit: ('{1} broadcast failed: {2}' format: {
									 transport transportName.
									 e messageText }) ] ].
	^ self
]

{ #category : 'accessing' }
BlennyWebApp >> conduit [
	^ conduit
]

{ #category : 'initialization' }
BlennyWebApp >> createAuthProvider [

	| persistenceType repository auth |
	persistenceType := BlennyConfig current
		                   at: 'persistence.type'
		                   ifAbsent: [ 'memory' ].


	repository := BlennyMemoryRepository new.


	auth := BlennySimpleAuth new.


	auth repository: repository.


	^ auth
]

{ #category : 'publishing' }
BlennyWebApp >> directData: aString toUser: aUserId [
   self
      broadcast: (Dictionary with: #signals -> aString with: #category -> #ui)
      toUser: aUserId
]

{ #category : 'publishing' }
BlennyWebApp >> directHtml: aString toUser: aUserId [
    self
      broadcast: (Dictionary with: #html -> aString with: #category -> #ui)
      toUser: aUserId
]

{ #category : 'modules' }
BlennyWebApp >> discoverModules [
    "Find all classes that use TBlennyModule"
    ^ TBlennyModule users select: [ :class | class isEnabled ]
]

{ #category : 'server' }
BlennyWebApp >> enableWebSocketsWithDefaultIntents: intents [
    | bridge |
    bridge := BlennyWebSocketBridge new
        initializeWithName: 'ws';
        start.
    optionalTransports add: bridge.
    ^ bridge   "return the bridge for further configuration if needed"
]

{ #category : 'initialization' }
BlennyWebApp >> initialize [

	super initialize.
	port := BlennyConfig current at: 'port' ifAbsent: [ 8081 ].
	authProvider := self createAuthProvider.
	modules := OrderedCollection new.
]

{ #category : 'modules' }
BlennyWebApp >> loadModule: aModuleClass [
    | module |
    module := aModuleClass new.
    
    "Always inject authProvider and renderer"
    (module respondsTo: #authProvider:) ifTrue: [
        module authProvider: authProvider ].
    (module respondsTo: #renderer:) ifTrue: [
        module renderer: renderer ].
    
    module initializeModule.
    modules add: module.
    StringSignal emit: ('Loaded module: {1}' format: { module moduleName })
]

{ #category : 'modules' }
BlennyWebApp >> loadModules [
    "Load and initialize all discovered modules"
    modules := OrderedCollection new.
    self discoverModules do: [ :moduleClass |
        self loadModule: moduleClass ]
]

{ #category : 'accessing' }
BlennyWebApp >> optionalTransports [
   ^ optionalTransports
]

{ #category : 'modules' }
BlennyWebApp >> registerModulesWithRouter: aRouter [
    modules do: [ :module |
        module registerRoutesOn: aRouter ]
]

{ #category : 'accessing' }
BlennyWebApp >> renderer [ 
	^ renderer 
]

{ #category : 'accessing' }
BlennyWebApp >> router [
	^ router 
]

{ #category : 'accessing' }
BlennyWebApp >> server [
	^ server
]

{ #category : 'middleware' }
BlennyWebApp >> setupDefaultMiddlewareOn: aRouter [
    "Apply default middleware to the router"
    "aRouter use: (BlennyMiddleware recoverSilent)."
    aRouter use: (BlennyMiddleware logRequests).
    aRouter use: (BlennyMiddleware addSecurityHeaders).
]

{ #category : 'private' }
BlennyWebApp >> setupDiskWatcher [
    | templatesPath |
    templatesPath := rootPath / 'templates'.
    templatesPath exists ifFalse: [ ^ self ].
    conduit := Conduit pointingAt: templatesPath pathString.
    conduit start.
]

{ #category : 'accessing' }
BlennyWebApp >> sseBridge [
    ^ sseBridge
]

{ #category : 'modules' }
BlennyWebApp >> startModules [
    modules do: [ :module | module startModule ]
]

{ #category : 'server' }
BlennyWebApp >> startOn: aPath [
    self startOn: aPath port: port.
]

{ #category : 'server' }
BlennyWebApp >> startOn: aPath port: aPortNumber [
    self stop.
    port := aPortNumber.
    rootPath := aPath ifNotNil: [ aPath asFileReference ].
    
    rootPath ifNotNil: [ self setupDiskWatcher ].
    self startServer.
    self announceStarted.
]

{ #category : 'server' }
BlennyWebApp >> startServer [

	| bindAddress encoderClass |
	
	BlennyConfig reset.
	BlennyPublisher reset.
	
	"Start logging"
   BlennyFileLogger attachToBeacon.
	
	ZnServer allInstancesDo: [ :s | s port = port ifTrue: [ s stop ] ].

	bindAddress := BlennyConfig current bindAddress.

	encoderClass := Smalltalk at: (BlennyConfig current
			                 at: 'sse.encoder'
			                 ifAbsent: [ #BlennyStandardSSEEncoder ]) asSymbol.
			
	sseBridge := BlennySSEBridge new
		             initializeWithEncoder: encoderClass new name: 'sse';
		             start.

	"Optional transports (WebSocket sidecar, initially empty)"
	optionalTransports := OrderedCollection new.

	"Create renderer (conduit is now available)"
	renderer := BlennyRenderer new
		            initializeWithConduit: conduit
		            rootPath: rootPath.


	"===== MODULE LOADING ====="
	self loadModules. "← Discover and instantiate modules"
	self startModules. "← Call startModule on each"
	"========================="

	"Create router with ALL dependencies injected"
	router := BlennyRouter new initializeWith: {
			          ('renderer' -> renderer).
			          ('app' -> self). "allows router to fetch bridges on demand"
			          ('rootPath' -> rootPath) } asDictionary.

	"Setup middleware on router"
	self setupDefaultMiddlewareOn: router.
	self registerModulesWithRouter: router.

	"===== REGISTER MODULES WITH ROUTER ====="
	self registerModulesWithRouter: router.
	"========================================"


	server := ZnServer on: port.
	server bindingAddress:
		(NetNameResolver addressForName: bindAddress) asByteArray.
	server delegate: router.
	server start.

		StringSignal emit: ('Server started on port {1}. SSE: http://localhost:{1}/sse. WebSocket optional.' format: { port }).
	
]

{ #category : 'server' }
BlennyWebApp >> stop [

	"1. Stop modules first (so they can clean up)"
	modules do: [ :module | module stopModule ].

	"2. Stop all transports (SSE and WebSocket bridges) – this closes connections cleanly"
	sseBridge ifNotNil: [ sseBridge stop ].
	optionalTransports ifNotNil: [ optionalTransports do: [ :t | t stop ] ].
	
	(Delay forMilliseconds: 100) wait.

	"4 Stop HTTP server"
	server ifNotNil: [
			server stop.
			server := nil ].

	"5 Stop Conduit file watcher"
	conduit ifNotNil: [
			conduit stop.
			conduit := nil ].

	"6 Stop auth janitor"
	authProvider shutdown.

	"6. Reset so next start sees fresh values"
	BlennyConfig reset.
	BlennyPublisher reset.

	StringSignal emit: 'Blenny server stopped.'
]

{ #category : 'modules' }
BlennyWebApp >> stopModules [
    modules do: [ :module | module stopModule ]
]

{ #category : 'accessing' }
BlennyWebApp >> transportNamed: aString [
   self sseBridge transportName = aString ifTrue: [ ^ self sseBridge ].
   ^ optionalTransports detect: [ :each | each transportName = aString ] ifNone: [ nil ]
]
