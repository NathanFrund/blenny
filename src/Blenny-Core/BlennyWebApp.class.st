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

{ #category : 'server' }
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
BlennyWebApp >> authProvider [
    ^ authProvider
]

{ #category : 'broadcasting' }
BlennyWebApp >> broadcast: aMessage toUser: aUserId [
   | allTransports |
   allTransports := { sseBridge }, optionalTransports.
   allTransports do: [ :transport |
      (transport hasConnectionForUser: aUserId) ifTrue: [
         [ transport directMessage: aMessage to: aUserId ]
            on: Error do: [ :e | Transcript show: transport transportName, ' failed: ', e messageText ]
      ] ]
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
   { sseBridge }, optionalTransports do: [ :transport |
      [ transport broadcastMessage: aMessage ]
         on: Error do: [ :e | Transcript show: transport transportName, ' broadcast failed: ', e messageText ]
   ]
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
    ^ TBlennyModule users
]

{ #category : 'as yet unclassified' }
BlennyWebApp >> enableWebSocketsWithDefaultIntents: intents [
    | htmlBridge dataBridge |
    "HTML endpoint – sends raw HTML (no JSON wrapper)"
    htmlBridge := BlennyWebSocketBridge new
        initializeWithName: 'ws-html';
        rawPayload: true;
        start.
    optionalTransports add: htmlBridge.

    "Data endpoint – sends full message dictionary as JSON"
    dataBridge := BlennyWebSocketBridge new
        initializeWithName: 'ws-data';
        start.  "rawPayload defaults to false → JSON"
    optionalTransports add: dataBridge.
    
    ^ htmlBridge
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
    Transcript show: 'Loaded module: ', module moduleName; cr.
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

{ #category : 'middle' }
BlennyWebApp >> setupDefaultMiddleware [
    "router use: (BlennyMiddleware recover)."
    router use: (BlennyMiddleware logRequests).
    router use: (BlennyMiddleware addSecurityHeaders).
]

{ #category : 'middleware' }
BlennyWebApp >> setupDefaultMiddlewareOn: aRouter [
    "Apply default middleware to the router"
    aRouter use: (BlennyMiddleware recoverSilent).
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

	"Create handlers"
	registerHandler := BlennyRegisterHandler new
		                   initializeWithAuth: authProvider
		                   renderer: renderer.
	loginHandler := BlennyLoginHandler new
		                initializeWithAuth: authProvider
		                renderer: renderer.
	logoutHandler := BlennyLogoutHandler new initializeWithAuth:
		                 authProvider.


	"===== MODULE LOADING ====="
	self loadModules. "← Discover and instantiate modules"
	self startModules. "← Call startModule on each"
	"========================="

	"Create router with ALL dependencies injected"
	router := BlennyRouter new initializeWith: {
			          ('renderer' -> renderer).
			          ('loginHandler' -> loginHandler).
			          ('registerHandler' -> registerHandler).
			          ('logoutHandler' -> logoutHandler).
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

	Transcript
		show: '========================================';
		cr;
		show: 'Blenny server started on port ' , port asString;
		cr;
		show: 'SSE endpoint: http://localhost:' , port asString , '/sse';
		cr;
		show:
			'WebSocket (optional): enable via #enableWebSocketsWithDefaultIntents:';
		cr;
		show: '========================================';
		cr
]

{ #category : 'server' }
BlennyWebApp >> stop [
	"Stop modules first (so they can clean up)"

	modules do: [ :module | module stopModule ].

	"Stop HTTP server"
	server ifNotNil: [
			server stop.
			server := nil ].

	"Stop Conduit file watcher"
	conduit ifNotNil: [
			conduit stop.
			conduit := nil ].

	"Stop auth janitor"
	authProvider shutdown.

	"Reset config so next start sees fresh values (e.g. blenny.json changes)"
	BlennyConfig reset.

	Transcript
		show: 'Blenny server stopped.';
		cr
]

{ #category : 'modules' }
BlennyWebApp >> stopModules [
    modules do: [ :module | module stopModule ]
]

{ #category : 'as yet unclassified' }
BlennyWebApp >> transportNamed: aString [
   ^ (self sseBridge transportName = aString
      ifTrue: [ self sseBridge ]
      ifFalse: [ nil ])
      ifNil: [ optionalTransports detect: [ :each | each transportName = aString ] ifNone: [ nil ] ]
]
