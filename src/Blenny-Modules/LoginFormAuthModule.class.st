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
		'authProvider',
		'renderer',
		'loginHandler',
		'registerHandler',
		'logoutHandler'
	],
	#category : 'Blenny-Modules',
	#package : 'Blenny-Modules'
}

{ #category : 'accessing' }
LoginFormAuthModule >> authProvider [
   ^ authProvider
]

{ #category : 'accessing' }
LoginFormAuthModule >> authProvider: anAuthProvider [
   authProvider := anAuthProvider
]

{ #category : 'initialization' }
LoginFormAuthModule >> initializeModule [
   loginHandler := BlennyLoginHandler new
      initializeWithAuth: authProvider renderer: renderer.
   registerHandler := BlennyRegisterHandler new
      initializeWithAuth: authProvider renderer: renderer.
   logoutHandler := BlennyLogoutHandler new
      initializeWithAuth: authProvider.
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
