"
I handle user login requests (GET and POST).

GET /login  - Display the login form
POST /login - Process login credentials, set JWT cookie, redirect to /

My responsibilities:
- Render the login page (GET)
- Validate username/password via authProvider
- Create JWT token on successful authentication
- Set secure HttpOnly cookie with the token
- Redirect to home page on success
- Render error messages on failure

I am created by BlennyWebApp with:
    loginHandler := BlennyLoginHandler new
        initializeWithAuth: authProvider
        renderer: renderer.

Usage:
    handler handleGet: request.   ""Show form""
    handler handlePost: request.  ""Process login""
"
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

{ #category : 'handling' }
BlennyLoginHandler >> handleGet: request [
    ^ renderer renderPage: 'login' context: Dictionary new
]

{ #category : 'handling' }
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

{ #category : 'private' }
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

{ #category : 'private' }
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
