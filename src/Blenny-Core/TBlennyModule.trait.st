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
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'authentication' }
TBlennyModule >> authenticatedUserFrom: request [
    | token |
    token := request uri queryAt: 'token' ifAbsent: [ nil ].
    token ifNil: [
        token := self extractTokenFromCookie: request ].
    token ifNil: [ ^ nil ].
    ^ BlennyPublisher currentWebApp authProvider validateToken: token
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

{ #category : 'authentication' }
TBlennyModule >> extractTokenFromCookie: request [
    | cookieHeader cookies |
    cookieHeader := request headers at: 'Cookie' ifAbsent: [ ^ nil ].
    cookies := Dictionary new.
    (cookieHeader splitOn: '; ') do: [ :pair |
        | key value |
        key := (pair copyUpTo: $=).
        value := (pair copyAfter: $=).
        cookies at: key put: value ].
    ^ cookies at: 'session' ifAbsent: [ nil ]
]

{ #category : 'lifecycle' }
TBlennyModule >> initializeModule [
    "Called when module is loaded"
    ^ self
]

{ #category : 'accessing' }
TBlennyModule >> moduleName [
    "Returns 'blennyauth' if the class is BlennyAuthModule"
    ^ (self class name asString withoutSuffix: 'Module') asLowercase
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
TBlennyModule >> renderPage: aTemplateName context: aDictionary [
    ^ BlennyPublisher currentWebApp renderer 
        renderPage: aTemplateName context: aDictionary
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
