Class {
	#name : 'BlennyRouterTest',
	#superclass : 'TestCase',
	#instVars : [
		'authProvider',
		'renderer',
		'loginHandler',
		'router'
	],
	#category : 'Blenny-Tests',
	#package : 'Blenny-Tests'
}

{ #category : 'running' }
BlennyRouterTest >> setUp [
    authProvider := BlennySimpleAuth new.
    renderer := BlennyRenderer new.
    loginHandler := BlennyLoginHandler new
        initializeWithAuth: authProvider renderer: renderer.
    
    router := BlennyRouter new initializeWith: {
        'renderer' -> renderer.
        'loginHandler' -> loginHandler.
        'registerHandler' -> nil.
        'logoutHandler' -> nil.
        'htmlBridge' -> nil.
        'dataBridge' -> nil.
        'rootPath' -> nil.
    } asDictionary.
]

{ #category : 'tests' }
BlennyRouterTest >> testEnsureResponseWithNil [
    | response |
    response := router ensureResponse: nil.
    self assert: response statusLine code equals: 500.
]

{ #category : 'tests' }
BlennyRouterTest >> testEnsureResponseWithResponse [
    | originalResponse response |
    originalResponse := ZnResponse ok: (ZnEntity text: 'OK').
    response := router ensureResponse: originalResponse.
    self assert: response == originalResponse.
]

{ #category : 'tests' }
BlennyRouterTest >> testEnsureResponseWithString [
    | response |
    response := router ensureResponse: 'Hello'.
    self assert: (response isKindOf: ZnResponse).
    self assert: response statusLine code equals: 200.
]

{ #category : 'tests' }
BlennyRouterTest >> testRouteRegistration [
    router registerGet: '/test' handler: [ :req | 'Hello' ].
    self assert: router routes size equals: 1.
    self assert: (router routes first at: 'path') equals: '/test'.
    self assert: (router routes first at: 'method') equals: #GET.
]
