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
		'authService',
		'authProvider',
		'renderer',
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

{ #category : 'authentication' }
BlennyWebApp >> appPublicPaths [
    "Return application-wide path prefixes that should be public (no authentication).
     Defaults can be overridden via BlennyConfig key 'app.public_paths'."
    ^ BlennyConfig current at: 'app.public_paths' ifAbsent: [ #('/' '/static/' '/health') ]
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
    self broadcastMessage: (Dictionary with: #signals -> aString with: #category -> #data)
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

{ #category : 'router' }
BlennyWebApp >> buildRouter [

	| activeAuth |
	activeAuth := self discoverAuthProvider.

	router := BlennyRouter new initializeWith: {
			          ('renderer' -> renderer).
			          ('app' -> self).
			          ('rootPath' -> rootPath) } asDictionary.

	"1. Install authentication middleware (core framework responsibility)"
	activeAuth ifNotNil: [
			router := self
				          installAuthenticationMiddlewareOn: router
				          using: activeAuth.
			self registerAuthRoutes: activeAuth on: router ].

	"2. Register normal modules"
	self registerModulesWithRouter: router.

	"3. Default middleware (logging, security)"
	self setupDefaultMiddlewareOn: router.

	^ router
]

{ #category : 'accessing' }
BlennyWebApp >> conduit [
	^ conduit
]

{ #category : 'authentication' }
BlennyWebApp >> createAuthService [
    "FIXME: Make configurable via blenny.json (auth.service_class, auth.repository_class)."
    ^ BlennySimpleAuth new
        repository: BlennyMemoryRepository new;
        yourself
]

{ #category : 'publishing' }
BlennyWebApp >> directData: aString toUser: aUserId [
   self
      broadcast: (Dictionary with: #signals -> aString with: #category -> #data)
      toUser: aUserId
]

{ #category : 'publishing' }
BlennyWebApp >> directHtml: aString toUser: aUserId [
    self
      broadcast: (Dictionary with: #html -> aString with: #category -> #ui)
      toUser: aUserId
]

{ #category : 'authentication' }
BlennyWebApp >> discoverAuthProvider [
    "Return the explicit authProvider if set, otherwise find the first module that answers true for #isAuthProvider."
    authProvider ifNotNil: [ ^ authProvider ].
    ^ self modules detect: [ :m | m isAuthProvider ] ifNone: [ nil ]
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
	modules := OrderedCollection new.
]

{ #category : 'authentication' }
BlennyWebApp >> installAuthenticationMiddlewareOn: aRouter using: anAuthModule [
    | allPublicPaths |
    allPublicPaths := Set new.
    allPublicPaths addAll: self appPublicPaths.
    allPublicPaths addAll: anAuthModule publicPaths.
    
    aRouter addMiddlewareFirst: [ :nextHandler :request |
        | path user |
        path := request uri pathPrintString.
        (allPublicPaths anySatisfy: [ :prefix |
            prefix = '/'
                ifTrue: [ path = '/' ]
                ifFalse: [ path beginsWith: prefix ] ])
            ifTrue: [ nextHandler value: request ]
            ifFalse: [
                user := anAuthModule authenticateRequest: request.
                user ifNotNil: [ nextHandler value: request ]
                ifNil: [ ZnResponse redirect: '/login' ] ] ].
    ^ aRouter
]

{ #category : 'modules' }
BlennyWebApp >> loadModule: aModuleClass [
    | module |
    module := aModuleClass new.
    
    "Always inject authProvider and renderer"
    (module respondsTo: #authService:) ifTrue: [
        module authService: self createAuthService ].
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
BlennyWebApp >> modules [
	^ modules
]

{ #category : 'accessing' }
BlennyWebApp >> optionalTransports [
   ^ optionalTransports
]

{ #category : 'authentication' }
BlennyWebApp >> registerAuthRoutes: anAuthModule on: aRouter [
    anAuthModule authRoutes do: [ :dict |
        | method path handler |
        method := dict at: #method ifAbsent: [ #GET ].
        path := dict at: #path.
        handler := dict at: #handler.       
        method = #GET ifTrue: [ aRouter registerGet: path handler: handler ].
        method = #POST ifTrue: [ aRouter registerPost: path handler: handler ].
]
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
	conduit ifNotNil: [ ^ self ].
	templatesPath := rootPath / 'templates'.
	templatesPath exists ifFalse: [ ^ self ].
	conduit := Conduit pointingAt: templatesPath pathString.
	conduit start
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
]

{ #category : 'server' }
BlennyWebApp >> startServer [

	| bindAddress encoderClass |
	BlennyConfig reset.
	BlennyPublisher reset.
	BlennyFileLogger attachToBeacon.

	ZnServer allInstancesDo: [ :s | s port = port ifTrue: [ s stop ] ].

	bindAddress := BlennyConfig current bindAddress.
	encoderClass := Smalltalk at: (BlennyConfig current
			                 at: 'sse.encoder'
			                 ifAbsent: [ #BlennyStandardSSEEncoder ]) asSymbol.

	sseBridge := BlennySSEBridge new
		             initializeWithEncoder: encoderClass new name: 'sse';
		             start.

	optionalTransports := OrderedCollection new.

	renderer := BlennyRenderer new
		            initializeWithConduit: conduit
		            rootPath: rootPath.

	"===== MODULE LOADING ====="
	self loadModules.
	self startModules.
	"========================="

	"Build router with new pluggable auth system"
	router := self buildRouter.

	"Retain the auth service for cleanup"
	"Retain the auth service for cleanup"
	authService := self discoverAuthProvider ifNotNil: [ :provider |
		               provider authService ].

	"Start HTTP server"
	server := ZnServer on: port.
	server bindingAddress:
		(NetNameResolver addressForName: bindAddress) asByteArray.
	server delegate: router.
	server start.

	self announceStarted
]

{ #category : 'server' }
BlennyWebApp >> stop [

	"1. Stop modules first (so they can clean up)"
	modules do: [ :module | module stopModule ].

	"2. Stop all transports (SSE and WebSocket bridges) – this closes connections cleanly"
	sseBridge ifNotNil: [ sseBridge stop ].
	optionalTransports ifNotNil: [ optionalTransports do: [ :t | t stop ] ].
	
	(Delay forMilliseconds: 100) wait.

	"3 Stop HTTP server"
	server ifNotNil: [
			server stop.
			server := nil ].

	"4. Stop auth service (token validator)"
    authService ifNotNil: [ authService shutdown ].

	"6. Reset so next start sees fresh values"
	BlennyConfig reset.
	BlennyPublisher reset.

	StringSignal emit: 'Blenny server stopped.'
]

{ #category : 'accessing' }
BlennyWebApp >> transportNamed: aString [
   self sseBridge transportName = aString ifTrue: [ ^ self sseBridge ].
   ^ optionalTransports detect: [ :each | each transportName = aString ] ifNone: [ nil ]
]
