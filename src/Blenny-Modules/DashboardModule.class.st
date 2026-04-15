"
I am an example module demonstrating the Blenny module system.

I show how to:
- Register HTTP routes (GET /dashboard, POST /dashboard/notify)
- Authenticate users via JWT token
- Render templates with user context
- Broadcast messages to all connected clients

My routes:
    GET  /dashboard        - Display the dashboard (requires authentication)
    POST /dashboard/notify - Broadcast a message to all WebSocket clients

I am discovered automatically because I use the TBlennyModule trait.

To create your own module:
    Object subclass: #MyModule
        uses: TBlennyModule

    MyModule >> registerRoutesOn: aRouter
        aRouter registerGet: '/mypath' handler: [ :req | self handleMyPath: req ].

    MyModule >> handleMyPath: request
        | user |
        user := self authenticatedUserFrom: request.
        user ifNil: [ ^ ZnResponse redirect: '/login' ].
        ^ self renderPage: 'mypage' context: { 'username' -> user } asDictionary.

Modules are automatically loaded, started, and registered by BlennyWebApp.
"
Class {
	#name : 'DashboardModule',
	#superclass : 'Object',
	#traits : 'TBlennyModule',
	#classTraits : 'TBlennyModule classTrait',
	#category : 'Blenny-Modules',
	#package : 'Blenny-Modules'
}

{ #category : 'as yet unclassified' }
DashboardModule >> handleDashboard: request [
    | user |
    user := self authenticatedUserFrom: request.
    user ifNil: [ ^ ZnResponse redirect: '/login' ].

    ^ self renderPage: 'dashboard' 
           context: { 'username' -> user } asDictionary 
           request: request
]

{ #category : 'as yet unclassified' }
DashboardModule >> handleNotify: request [
    | user message formData |
    user := self authenticatedUserFrom: request.
    user ifNil: [ ^ ZnResponse statusCode: 401 ].
    
    formData := request entity fields.
    message := formData at: 'message' ifAbsent: [ ^ ZnResponse statusCode: 400 ].
    
    message ifEmpty: [ ^ ZnResponse statusCode: 400 ].
    
    self broadcastHtml: '<div class="notification">', message, '</div>'.
    
    ^ ZnResponse statusCode: 200
]

{ #category : 'required' }
DashboardModule >> registerRoutesOn: aRouter [
    aRouter registerGet: '/dashboard' handler: [ :request |
        self handleDashboard: request ].
    aRouter registerPost: '/dashboard/notify' handler: [ :request |
        self handleNotify: request ].
]
