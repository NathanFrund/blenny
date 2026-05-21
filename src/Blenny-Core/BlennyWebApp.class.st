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

{ #category : 'as yet unclassified' }
BlennyWebApp >> appPublicPaths [
    "Return application-wide path prefixes that should be public (no authentication).
     Defaults can be overridden via BlennyConfig key 'app.public_paths'."
    ^ BlennyConfig current at: 'app.public_paths' ifAbsent: [ #('/' '/static/' '/health') ]
]

{ #category : 'accessing' }
BlennyWebApp >> authProvider [
    ^ authProvider
]

{ #category : 'refactoring-pass' }
BlennyWebApp >> autoDiscoverAuthProvider [
    | candidates |
    candidates := self modules select: [ :m | m isAuthProvider ].
    
    candidates size > 1 ifTrue: [
        StringSignal emit: ('Multiple auth providers enabled. Using first: ', candidates first class name) ].
    
    ^ candidates ifNotEmpty: [ candidates first ] ifEmpty: [ nil ]
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

{ #category : 'refactoring-pass' }
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

{ #category : 'initialization' }
BlennyWebApp >> createAuthProvider [
    "Return the default auth *module* (not the service)"
    | authService module |
    
    authService := BlennySimpleAuth new.
    authService repository: (BlennyMemoryRepository new).   "adjust as needed"
    
    module := LoginFormAuthModule new.
    module authService: authService.
    module renderer: renderer.
    
    ^ module
]

{ #category : 'as yet unclassified' }
BlennyWebApp >> createAuthService [
    | authService |
    authService := BlennySimpleAuth new.
    authService repository: (BlennyMemoryRepository new).  "or from config"
    ^ authService
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

{ #category : 'refactoring-pass' }
BlennyWebApp >> discoverAuthProvider [
    "Explicit authProvider takes precedence. Falls back to self-assembling discovery."
    authProvider ifNotNil: [ ^ authProvider ].
    ^ self autoDiscoverAuthProvider
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

{ #category : 'refactoring-pass' }
BlennyWebApp >> initializeLoadedModules [
    "Initialize all loaded modules - matches your existing 'modules' collection"
    self modules do: [ :module |
        module initializeModule ]
]

{ #category : 'as yet unclassified' }
BlennyWebApp >> installAuthenticationMiddlewareOn: aRouter using: anAuthModule [
    | allPublicPaths |
    allPublicPaths := Set new.
    allPublicPaths addAll: self appPublicPaths.
    allPublicPaths addAll: anAuthModule publicPaths.  "still need module to provide its own public paths"
    
    aRouter addMiddlewareFirst: [ :nextHandler :request |
        | path user response |
        path := request uri pathPrintString.
        (allPublicPaths anySatisfy: [ :prefix |
            prefix = '/'
                ifTrue: [ path = '/' ]
                ifFalse: [ path beginsWith: prefix ] ])
            ifTrue: [ response := nextHandler value: request ]
            ifFalse: [
                user := anAuthModule authenticateRequest: request.
                user ifNotNil: [
                    response := nextHandler value: request ]
                ifNil: [ response := ZnResponse redirect: '/login' ] ].
        response ].
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

{ #category : 'refactoring-pass' }
BlennyWebApp >> registerAuthRoutes: anAuthModule on: aRouter [
    anAuthModule authRoutes do: [ :dict |
        | method path handler |
        method := dict at: #method ifAbsent: [ #GET ].
        path := dict at: #path.
        handler := dict at: #handler.
Transcript show: 'Registering auth route: ' , method , ' ' , path; cr.        
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
    self announceStarted.
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
	authService := self discoverAuthProvider
		               ifNotNil: [ :provider | provider authService ]
		               ifNil: [ nil ].

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

{ #category : 'modules' }
BlennyWebApp >> stopModules [
    modules do: [ :module | module stopModule ]
]

{ #category : 'accessing' }
BlennyWebApp >> transportNamed: aString [
   self sseBridge transportName = aString ifTrue: [ ^ self sseBridge ].
   ^ optionalTransports detect: [ :each | each transportName = aString ] ifNone: [ nil ]
]
