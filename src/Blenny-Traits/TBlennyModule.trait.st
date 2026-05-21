"
I am the trait for creating pluggable Blenny modules.

To create a module:
    Object subclass: #MyModule
        uses: TBlennyModule

Required method:
    registerRoutesOn: aRouter   ""Register your HTTP routes""

Optional methods:
    initializeModule   ""Called when module is loaded""
    startModule        ""Called when server starts""
    stopModule         ""Called when server stops""

Your module can also use these provided methods:
    authenticatedUserFrom:   ""Get current user from request""
    broadcastHtml:           ""Send to all connected clients""
    directHtml:toUser:       ""Send to specific user""
    renderPage:context:      ""Render a template""
"
Trait {
	#name : 'TBlennyModule',
	#category : 'Blenny-Traits',
	#package : 'Blenny-Traits'
}

{ #category : 'testing' }
TBlennyModule classSide >> isEnabled [
   ^ true
]

{ #category : 'adding' }
TBlennyModule >> addAuthenticationTo: aRouter appPublicPaths: appPublicPaths [
    | allPublicPaths |
    allPublicPaths := Set new.
    allPublicPaths addAll: self publicPaths.
    allPublicPaths addAll: appPublicPaths.
    
    aRouter addMiddlewareFirst: [ :nextHandler :request |
        | path user response |
        path := request uri pathPrintString.
        Transcript show: 'Auth middleware checking path: ' , path; cr.
        Transcript show: 'Public paths: ' , allPublicPaths asArray printString; cr.
        
        (allPublicPaths anySatisfy: [ :prefix |
            prefix = '/'
                ifTrue: [ path = '/' ]
                ifFalse: [ path beginsWith: prefix ] ])
            ifTrue: [ response := nextHandler value: request ]
            ifFalse: [
                user := self authenticateRequest: request.
                user ifNotNil: [
                    request environment at: #user put: user.
                    response := nextHandler value: request ]
                ifNil: [ response := self unauthorizedResponseFor: request ] ].
        response ].
    ^ aRouter

]

{ #category : 'accessing' }
TBlennyModule >> authProvider [
    "Subclasses must provide this"
    self subclassResponsibility
]

{ #category : 'authentication' }
TBlennyModule >> authRoutes [
    ^ #()
]

{ #category : 'auth-private' }
TBlennyModule >> authenticateRequest: request [
    | token |
    token := self extractTokenFrom: request.
    token ifNil: [ ^ nil ].
    ^ self validateToken: token
]

{ #category : 'authentication' }
TBlennyModule >> authenticatedUserFrom: request [
    | token userId |
    token := request uri queryAt: 'token' ifAbsent: [ nil ].
    token ifNil: [ token := BlennyMiddleware extractTokenFromCookie: request ].
    token ifNil: [ ^ nil ].
    
    "Assume authProvider is injected"
    userId := self authProvider validateToken: token.
    ^ userId

]

{ #category : 'publishing' }
TBlennyModule >> broadcastData: aString [
    BlennyPublisher broadcastData: aString
]

{ #category : 'publishing' }
TBlennyModule >> broadcastHtml: aString [
    BlennyPublisher broadcastHtml: aString
]

{ #category : 'publishing' }
TBlennyModule >> directData: aString toUser: aUserId [
    BlennyPublisher directData: aString toUser: aUserId
]

{ #category : 'publishing' }
TBlennyModule >> directHtml: aString toUser: aUserId [
    BlennyPublisher directHtml: aString toUser: aUserId
]

{ #category : 'auth-private' }
TBlennyModule >> extractTokenFrom: request [
    | cookie auth |
    "Priority 1: blenny_token cookie"
    cookie := request cookies detect: [ :c | c name = 'blenny_token' ] ifNone: [ nil ].
    cookie ifNotNil: [ ^ cookie value ].
    
    "Priority 2: Authorization: Bearer <token>"
    auth := request headers at: 'authorization' ifAbsent: [ ^ nil ].
    (auth beginsWith: 'Bearer ') ifTrue: [
        ^ auth size >= 8 
            ifTrue: [ (auth copyFrom: 8) trimBoth ]
            ifFalse: [ nil ]
    ].
    
    ^ nil
]

{ #category : 'lifecycle' }
TBlennyModule >> initializeModule [
    "Called when module is loaded"
    ^ self
]

{ #category : 'authentication' }
TBlennyModule >> isAuthProvider [
    ^ false
]

{ #category : 'accessing' }
TBlennyModule >> moduleName [
    "Returns 'blennyauth' if the class is BlennyAuthModule"
    ^ (self class name asString withoutSuffix: 'Module') asLowercase
]

{ #category : 'auth-configuration' }
TBlennyModule >> publicPaths [
    ^ #()
]

{ #category : 'required' }
TBlennyModule >> registerRoutesOn: aRouter [
    self subclassResponsibility
]

{ #category : 'rendering' }
TBlennyModule >> render: aTemplateName request: aRequest context: aDictionary [
    ^ BlennyPublisher currentWebApp renderer 
        render: aTemplateName request: aRequest context: aDictionary
]

{ #category : 'rendering' }
TBlennyModule >> renderPage: templateName context: aDictionary [
    "Default entry point for simple renders"
    ^ self renderPage: templateName context: aDictionary request: nil
]

{ #category : 'rendering' }
TBlennyModule >> renderPage: templateName context: aDictionary request: aRequest [
    | renderer html |
    renderer := BlennyPublisher currentWebApp renderer.
    
    "1. Intelligent Branching: Full Page vs. HTMX Fragment"
    html := (aRequest notNil and: [ renderer isHtmxRequest: aRequest ])
        ifTrue: [ renderer renderFragment: templateName context: aDictionary ]
        ifFalse: [ renderer renderPage: templateName context: aDictionary ].
    
    "2. Anti-Fragility: If the renderer already returned a Response, pass it through"
    (html isKindOf: ZnResponse) ifTrue: [ ^ html ].
    
    "3. Type Safety: Ensure we have a string before wrapping"
    (html isString) ifFalse: [ 
        Transcript show: 'CRITICAL: Render failed for ', templateName, '. Result was: ', html class name; cr.
        ^ ZnResponse serverError: 'Template Rendering Failed' ].

    "4. Final Wrap: Fulfill the middleware contract"
    ^ ZnResponse ok: (ZnEntity html: html)
]

{ #category : 'lifecycle' }
TBlennyModule >> startModule [
    "Called when server starts"
    ^ self
]

{ #category : 'lifecycle' }
TBlennyModule >> stopModule [
    "Called when server stops"
    ^ self
]

{ #category : 'auth-token' }
TBlennyModule >> unauthorizedResponseFor: request [
    "Redirect to login page."
    ^ ZnResponse redirect: '/login'
]

{ #category : 'auth-token' }
TBlennyModule >> validateToken: aToken [
    self subclassResponsibility
]
