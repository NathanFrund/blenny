"
I am the standard authentication UI module for Blenny.

I register routes for the traditional username/password login, registration, and logout
flows, using the existing BlennyLoginHandler, BlennyRegisterHandler, and BlennyLogoutHandler.
Templates are served from the Conduit registry ('login_form', 'register_form', etc.) and
can be customised by setting the appropriate error template names on the handlers.

I use the TBlennyModule trait, so I am automatically discovered and loaded by BlennyWebApp.
To disable me, override the class-side method #isEnabled to return false.

Alternative authentication UIs (tabletop, QR code, passwordless) can be created by writing
their own module classes that implement TBlennyModule and register different routes.
"
Class {
	#name : 'LoginFormAuthModule',
	#superclass : 'Object',
	#traits : 'TBlennyModule',
	#classTraits : 'TBlennyModule classTrait',
	#instVars : [
		'authService',
		'renderer',
		'loginHandler',
		'registerHandler',
		'logoutHandler'
	],
	#category : 'Blenny-Modules',
	#package : 'Blenny-Modules'
}

{ #category : 'authentication' }
LoginFormAuthModule >> authRoutes [
    "Return your login/register/logout routes"
    ^ {
        { #method -> #GET.  #path -> '/login'.    #handler -> [ :req | self loginHandler handleGet: req ] } asDictionary.
        { #method -> #POST. #path -> '/login'.    #handler -> [ :req | self loginHandler handlePost: req ] } asDictionary.
        { #method -> #GET.  #path -> '/register'. #handler -> [ :req | self registerHandler handleGet: req ] } asDictionary.
        { #method -> #POST. #path -> '/register'. #handler -> [ :req | self registerHandler handlePost: req ] } asDictionary.
        { #method -> #GET.  #path -> '/logout'.   #handler -> [ :req | self logoutHandler handleGet: req ] } asDictionary.
    }
]

{ #category : 'accessing' }
LoginFormAuthModule >> authService [ 
	^ authService 
]

{ #category : 'accessing' }
LoginFormAuthModule >> authService: anAuthService [
    authService := anAuthService
]

{ #category : 'initialization' }
LoginFormAuthModule >> initializeModule [
    loginHandler := BlennyLoginHandler new 
        initializeWithAuth: authService renderer: renderer.
    loginHandler loginTemplate: 'auth/login'.
    loginHandler loginErrorTemplate: 'auth/login_form'.
    
    registerHandler := BlennyRegisterHandler new 
        initializeWithAuth: authService renderer: renderer.
    registerHandler registerTemplate: 'auth/register'.
    registerHandler registerErrorTemplate: 'auth/register_form'.
    
    logoutHandler := BlennyLogoutHandler new 
        initializeWithAuth: authService.

]

{ #category : 'testing' }
LoginFormAuthModule >> isAuthProvider [ 
	^ true
]

{ #category : 'as yet unclassified' }
LoginFormAuthModule >> loginHandler [
    ^ loginHandler
]

{ #category : 'accessing' }
LoginFormAuthModule >> logoutHandler [
    ^ logoutHandler
]

{ #category : 'auth-configuration' }
LoginFormAuthModule >> publicPaths [
    ^ { '/login'. '/register'. '/logout'. '/static/'. '/health' }
]

{ #category : 'accessing' }
LoginFormAuthModule >> registerHandler [
    ^ registerHandler
]

{ #category : 'required' }
LoginFormAuthModule >> registerRoutesOn: aRouter [
   aRouter registerGet: '/login' handler: [ :req | loginHandler handleGet: req ].
   aRouter registerPost: '/login' handler: [ :req | loginHandler handlePost: req ].
   aRouter registerGet: '/register' handler: [ :req | registerHandler handleGet: req ].
   aRouter registerPost: '/register' handler: [ :req | registerHandler handlePost: req ].
   aRouter registerGet: '/logout' handler: [ :req | logoutHandler handlePost: req ].
   aRouter registerPost: '/logout' handler: [ :req | logoutHandler handlePost: req ].

]

{ #category : 'accessing' }
LoginFormAuthModule >> renderer [
   ^ renderer
]

{ #category : 'accessing' }
LoginFormAuthModule >> renderer: aRenderer [
   renderer := aRenderer
]

{ #category : 'shutdown' }
LoginFormAuthModule >> shutdown [
	"do nothing yet"
]

{ #category : 'auth-token' }
LoginFormAuthModule >> validateToken: aToken [
    ^ authService validateToken: aToken
]
