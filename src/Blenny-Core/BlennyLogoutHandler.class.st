Class {
	#name : 'BlennyLogoutHandler',
	#superclass : 'Object',
	#instVars : [
		'authProvider'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'as yet unclassified' }
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

{ #category : 'as yet unclassified' }
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
