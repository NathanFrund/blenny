"
I handle user logout requests (POST /logout).

My responsibilities:
- Extract JWT token from cookie
- Add token to blacklist (prevents reuse)
- Clear the session cookie (maxAge: 0)
- Redirect to login page

I am created by BlennyWebApp with:
    logoutHandler := BlennyLogoutHandler new
        initializeWithAuth: authProvider.

Usage:
    handler handlePost: request.  ""Process logout""

Note: Supports both GET and POST for development, but POST is recommended for security.
"
Class {
	#name : 'BlennyLogoutHandler',
	#superclass : 'Object',
	#instVars : [
		'authProvider'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'handling' }
BlennyLogoutHandler >> handleGet: request [
    "Support GET for browser testing"
    ^ self handlePost: request
]

{ #category : 'handling' }
BlennyLogoutHandler >> handlePost: request [

    | cookie sessionId |
    
    "Find the 'session' cookie in the request's cookie collection"
    cookie := request cookies 
        detect: [ :each | each name = 'session' ] 
        ifNone: [ nil ].
        
    sessionId := cookie ifNotNil: [ cookie value ].
    
    sessionId ifNotNil: [ authProvider logout: sessionId ].
    
    ^ self redirectToLogin

]

{ #category : 'initialization' }
BlennyLogoutHandler >> initializeWithAuth: anAuthProvider [
    authProvider := anAuthProvider
]

{ #category : 'private' }
BlennyLogoutHandler >> redirectToLogin [
    | response cookie |
    
    response := ZnResponse redirect: '/login'.
    
    cookie := (ZnCookie name: 'session' value: '')
        path: '/';
        maxage: 0;
        httponly: true;
        yourself.
        
    response addCookie: cookie.
    ^ response
]
