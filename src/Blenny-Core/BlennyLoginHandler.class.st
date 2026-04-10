Class {
	#name : 'BlennyLoginHandler',
	#superclass : 'Object',
	#instVars : [
		'authProvider',
		'renderer'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'accessing' }
BlennyLoginHandler >> authProvider [ 
	^ authProvider 
]

{ #category : 'as yet unclassified' }
BlennyLoginHandler >> handleGet: request [
    ^ renderer renderPage: 'login' context: Dictionary new
]

{ #category : 'as yet unclassified' }
BlennyLoginHandler >> handlePost: request [
    | formData username password sessionId |
    
    formData := request entity fields.
    username := formData at: 'username' ifAbsent: [ 
        ^ self renderError: 'Username required' request: request ].
    password := formData at: 'password' ifAbsent: [ 
        ^ self renderError: 'Password required' request: request ].
    
    sessionId := authProvider authenticate: username password: password.
    sessionId ifNil: [ 
        ^ self renderError: 'Invalid credentials' request: request ].
    
    ^ self redirectWithCookie: sessionId
]

{ #category : 'initialization' }
BlennyLoginHandler >> initializeWithAuth: anAuthProvider renderer: aRenderer [
    authProvider := anAuthProvider.
    renderer := aRenderer.
]

{ #category : 'as yet unclassified' }
BlennyLoginHandler >> redirectWithCookie: sessionId [

    | response cookie |
    
    "Corrected: Use 'redirect:' for a 302 Found response"
    response := ZnResponse redirect: '/'.
    
    "Use the proper Zinc cookie object"
    cookie := (ZnCookie name: 'session' value: sessionId)
        path: '/';
        httponly: true;
        yourself.
        
    response addCookie: cookie.
    ^ response



]

{ #category : 'rendering' }
BlennyLoginHandler >> renderError: errorMessage request: aRequest [

    | context formData |
    context := Dictionary new.
    
    "Corrected: Access the pre-parsed fields from the entity"
    formData := aRequest entity fields. 
    
    context at: 'error' put: errorMessage.
    context at: 'email' put: (formData at: 'email' ifAbsent: [ '' ]).
    
    ^ renderer render: 'partials/register_form' request: aRequest context: context

]

{ #category : 'accessing' }
BlennyLoginHandler >> renderer [
	^ renderer 
]
