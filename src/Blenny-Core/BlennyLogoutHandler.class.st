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

{ #category : 'private' }
BlennyLogoutHandler >> handlePost: request [
    | cookie token |
    Transcript show: 'Logout handler called'; cr.
    cookie := request cookies detect: [ :each | each name = 'blenny_token' ] ifNone: [ nil ].
    token := cookie ifNotNil: [ cookie value ].
    Transcript show: 'Token found: ' , (token ifNil: ['nil'] ifNotNil: [token]); cr.
    token ifNotNil: [ authProvider logout: token ].
    ^ self redirectToLogin

]

{ #category : 'initialization' }
BlennyLogoutHandler >> initializeWithAuth: anAuthProvider [
    authProvider := anAuthProvider
]

{ #category : 'private' }
BlennyLogoutHandler >> redirectToLogin [
    | response cookie |
    Transcript show: 'Logout handler called'; cr.
    response := ZnResponse redirect: '/login'.

	Transcript show: 'Logout called!'.
    
    cookie := (ZnCookie name: 'blenny_token' value: '')
        path: '/';
        maxage: 0;
        httponly: true;
        yourself.
        
    response addCookie: cookie.
Transcript show: 'Logout response headers: ' , response headers asString; cr.
    ^ response
]
