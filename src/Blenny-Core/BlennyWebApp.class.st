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
		'htmlBridge',
		'dataBridge',
		'modules',
		'router'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'accessing' }
BlennyWebApp class >> default [
    "Convenience for quick start - uses SimpleAuth for development"
    ^ self new initializeWithAuth: BlennySimpleAuth new.
]

{ #category : 'as yet unclassified' }
BlennyWebApp class >> withAuth: anAuthProvider [
    ^ self new initializeWithAuth: anAuthProvider
]

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
BlennyWebApp >> authProvider [
    ^ authProvider
]

{ #category : 'publishing' }
BlennyWebApp >> broadcastData: aString [
    self dataBridge publish: (BlennyDataBroadcast payload: aString)
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
BlennyWebApp >> dataBridge [
	^ dataBridge
]

{ #category : 'accessing' }
BlennyWebApp >> dataBridge: aBridge [
	dataBridge := aBridge 
]

{ #category : 'publishing' }
BlennyWebApp >> directData: aString toUser: aUserId [
    self dataBridge publish: (BlennyDataDirect payload: aString toUser: aUserId)
]

{ #category : 'publishing' }
BlennyWebApp >> directHtml: aString toUser: aUserId [
    self htmlBridge publish: (BlennyHTMLDirect payload: aString toUser: aUserId)
]

{ #category : 'modules' }
BlennyWebApp >> discoverModules [
    "Find all classes that use TBlennyModule"
    ^ TBlennyModule users
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
	port := BlennyConfig current at: 'port' ifAbsent: [ 8081 ].
	authProvider := BlennySimpleAuth new.
	modules := OrderedCollection new.
]

{ #category : 'initialization' }
BlennyWebApp >> initializeWithAuth: anAuthProvider [
    "Initialize with a specific auth provider"
    port := 8081.
    authProvider := anAuthProvider.
]

{ #category : 'modules' }
BlennyWebApp >> loadModule: aModuleClass [
    | module |
    module := aModuleClass new.
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

{ #category : 'accessing' }
BlennyWebApp >> server [
	^ server
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

{ #category : 'modules' }
BlennyWebApp >> startModules [
    modules do: [ :module | module startModule ]
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

	| bindAddress |
	ZnServer allInstancesDo: [ :s | s port = port ifTrue: [ s stop ] ].

	bindAddress := BlennyConfig current bindAddress.

	"Create bridges"
	htmlBridge := BlennyAnnouncerBridge new initializeWithEndpoint:
		              'html'.
	dataBridge := BlennyAnnouncerBridge new initializeWithEndpoint:
		              'data'.

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
			          ('htmlBridge' -> htmlBridge).
			          ('dataBridge' -> dataBridge).
			          ('rootPath' -> rootPath) } asDictionary.

	"===== REGISTER MODULES WITH ROUTER ====="
	self registerModulesWithRouter: router.
	"========================================"


	server := ZnServer on: port.
	server bindingAddress:
		(NetNameResolver addressForName: bindAddress) asByteArray.
	server delegate: router.
	server start.

	self htmlBridge: htmlBridge.
	self dataBridge: dataBridge.

	Transcript
		show: '========================================';
		cr.
	Transcript
		show: 'Blenny server started on port ' , port asString;
		cr.
	Transcript
		show: 'HTML WebSocket: ws://localhost:' , port asString , '/ws/html';
		cr.
	Transcript
		show: 'Data WebSocket: ws://localhost:' , port asString , '/ws/data';
		cr.
	Transcript
		show: '========================================';
		cr
]

{ #category : 'accessing' }
BlennyWebApp >> stop [

	"Stop modules first (so they can clean up)"
    modules do: [ :module | module stopModule ].
    
    "Stop bridges (close WebSocket connections)"
    htmlBridge ifNotNil: [ htmlBridge stop ].
    dataBridge ifNotNil: [ dataBridge stop ].


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

    Transcript show: 'Blenny server stopped.'; cr.
]

{ #category : 'modules' }
BlennyWebApp >> stopModules [
    modules do: [ :module | module stopModule ]
]
