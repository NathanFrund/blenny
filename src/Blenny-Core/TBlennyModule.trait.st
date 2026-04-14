Trait {
	#name : 'TBlennyModule',
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'as yet unclassified' }
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

{ #category : 'as yet unclassified' }
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

{ #category : 'initialization' }
TBlennyModule >> initializeModule [
    "Called when module is loaded"
    ^ self
]

{ #category : 'accessing' }
TBlennyModule >> moduleName [
    "Auto-generate name from class"
    ^ self class name withoutSuffix: 'Module' asLowercase
]

{ #category : 'as yet unclassified' }
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

{ #category : 'as yet unclassified' }
TBlennyModule >> startModule [
    "Called when server starts"
    ^ self
]

{ #category : 'as yet unclassified' }
TBlennyModule >> stopModule [
    "Called when server stops"
    ^ self
]
