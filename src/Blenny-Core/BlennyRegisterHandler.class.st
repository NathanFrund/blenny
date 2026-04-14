"
I handle user registration requests (GET and POST).

GET /register    - Display the registration form
POST /register   - Create new user account

My responsibilities:
- Render the registration page (GET)
- Validate form data (email, password, confirm password)
- Check if user already exists
- Create new user via authProvider
- Optionally auto-login after registration (configurable)
- Redirect to login page (or dashboard if auto-login)

I am created by BlennyWebApp with:
    registerHandler := BlennyRegisterHandler new
        initializeWithAuth: authProvider
        renderer: renderer.

Configuration:
    handler autoLoginAfterRegistration: true.   ""Auto-login after signup""

Usage:
    handler handleGet: request.   ""Show form""
    handler handlePost: request.  ""Process registration""
"
Class {
	#name : 'BlennyRegisterHandler',
	#superclass : 'Object',
	#instVars : [
		'authProvider',
		'renderer',
		'autoLoginAfterRegistration'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'accessing' }
BlennyRegisterHandler >> autoLoginAfterRegistration: aBoolean [
    autoLoginAfterRegistration := aBoolean.
]

{ #category : 'handling' }
BlennyRegisterHandler >> handleGet: request [
    | context email |
    context := Dictionary new.
    email := request uri queryAt: 'email' ifAbsent: [ nil ].
    email ifNotNil: [ context at: 'email' put: email ].
    ^ renderer renderPage: 'register' context: context
]

{ #category : 'handling' }
BlennyRegisterHandler >> handlePost: request [
    | formData email password confirm |
    
    formData := request entity fields.
    email := formData at: 'email' ifAbsent: [ 
        ^ self renderError: 'Email required' request: request ].
    password := formData at: 'password' ifAbsent: [ 
        ^ self renderError: 'Password required' request: request ].
    confirm := formData at: 'password_confirm' ifAbsent: [ 
        ^ self renderError: 'Please confirm password' request: request ].
    
    password ~= confirm ifTrue: [ 
        ^ self renderError: 'Passwords do not match' request: request ].
    
    (authProvider userExists: email) ifTrue: [ 
        ^ self renderError: 'Email already registered' request: request ].
    
    authProvider createUser: email password: password.
    
    autoLoginAfterRegistration ifTrue: [
        | sessionId |
        sessionId := authProvider authenticate: email password: password.
        ^ self redirectWithCookie: sessionId ].
    
    ^ self redirectToLogin
]

{ #category : 'initialization' }
BlennyRegisterHandler >> initializeWithAuth: anAuthProvider renderer: aRenderer [
    authProvider := anAuthProvider.
    renderer := aRenderer.
    autoLoginAfterRegistration := false.
]

{ #category : 'private' }
BlennyRegisterHandler >> redirectToLogin [
    | response cookie |
    
    response := ZnResponse redirect: '/login?registered=true'.
    
    "Clear the cookie if it exists"
    cookie := (ZnCookie name: 'session' value: '')
        path: '/';
        maxage: 0;
        yourself.
        
    response addCookie: cookie.
    ^ response
]

{ #category : 'private' }
BlennyRegisterHandler >> redirectWithCookie: sessionId [
    | response cookie |
    
    response := ZnResponse redirect: '/dashboard'.
    
    cookie := (ZnCookie name: 'session' value: sessionId)
        path: '/';
        httponly: true;
        yourself.
        
    response addCookie: cookie.
    ^ response
]

{ #category : 'private' }
BlennyRegisterHandler >> renderError: errorMessage request: aRequest [
    | context formData |
    context := Dictionary new.
    formData := aRequest entity fields.
    context at: 'error' put: errorMessage.
    context at: 'email' put: (formData at: 'email' ifAbsent: [ '']).
    ^ renderer render: 'partials/register_form' request: aRequest context: context
]
