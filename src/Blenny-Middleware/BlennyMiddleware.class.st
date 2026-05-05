Class {
	#name : 'BlennyMiddleware',
	#superclass : 'Object',
	#category : 'Blenny-Middleware',
	#package : 'Blenny-Middleware'
}

{ #category : 'security' }
BlennyMiddleware class >> addSecurityHeaders [
    ^ [ :handler :request |
        | response |
        response := handler value: request.
        response headers at: 'X-Content-Type-Options' put: 'nosniff'.
        response headers at: 'X-Frame-Options' put: 'DENY'.
        response headers at: 'X-XSS-Protection' put: '1; mode=block'.
        response ]

]

{ #category : 'chaining' }
BlennyMiddleware class >> chain: middlewareList [
    ^ [ :handler :request |
        | currentHandler |
        currentHandler := handler.
        middlewareList reverseDo: [ :mw |
            currentHandler := [ :req | mw value: currentHandler value: req ] ].
        currentHandler value: request ]

]

{ #category : 'authentication' }
BlennyMiddleware class >> currentUserFrom: request using: authProvider [

	| token |
	token := request uri queryAt: 'token' ifAbsent: [ nil ].


	token ifNil: [ token := self extractTokenFromCookie: request ].

	token ifNil: [ ^ nil ].


	^ authProvider validateToken: token
]

{ #category : 'private' }
BlennyMiddleware class >> extractTokenFromCookie: request [
    | cookieHeader |
    StringSignal emit: 'extractTokenFromCookie called'.
    
    cookieHeader := request headers at: 'Cookie' ifAbsent: [ 
        StringSignal emit: 'No Cookie header found'.
        ^ nil ].
    
    (cookieHeader splitOn: '; ') do: [ :pair |
        | key value |
        key := (pair copyUpTo: $=) trimBoth.
        value := (pair copyAfter: $=) trimBoth.
        key = 'session' ifTrue: [ ^ value ] ].
    
    StringSignal emit: 'No session cookie found'.
    ^ nil
]

{ #category : 'logging' }
BlennyMiddleware class >> logRequests [
    ^ [ :handler :request |
        | response |
        response := handler value: request.
        
        "Ensure it's a response before calling statusLine"
        (response isKindOf: ZnResponse) ifTrue: [
             StringSignal emit: ('← {1}' format: { response statusLine code asString }).
        ] ifFalse: [
             StringSignal emit: '← [Non-Response Returned]'.
        ].
        
        response ]
]

{ #category : 'logging' }
BlennyMiddleware class >> logSlowRequests: thresholdSeconds [

	^ [ :handler :request |
		  | start response duration |
		  start := DateAndTime now.
		  response := handler value: request.
		  duration := (DateAndTime now - start) asSeconds.
		  duration > thresholdSeconds ifTrue: [
				  StringSignal emit: ('SLOW: {1} {2} - {3}s' format: {
							   request method.
							   request uri path.
							   duration asString }) ].
		  response ]
]

{ #category : 'rate-limiting' }
BlennyMiddleware class >> rateLimit: requestsPerWindow windowSeconds: windowSeconds [
    | counts |
    counts := Dictionary new.
    ^ [ :handler :request |
        | response ip key count |
        ip := request headers at: 'X-Forwarded-For' ifAbsent: [ 'unknown' ].
        key := ip, '_', DateAndTime now asDate yyyymmdd, '_', (DateAndTime now hour24 printString).
        count := counts at: key ifAbsent: [ 0 ].
        count >= requestsPerWindow ifTrue: [
            ^ (ZnResponse statusCode: 429)
                entity: (ZnEntity text: 'Too many requests');
                yourself ].
        counts at: key put: count + 1.
        response := handler value: request.
        response ]

]

{ #category : 'recovery' }
BlennyMiddleware class >> recover [
    ^ [ :handler :request |
        [ handler value: request ]
            on: Error
            do: [ :ex |
                "This ensures we don't recurse if the Transcript itself fails"
                StringSignal emit: ('ERROR: {1}' format: { ex description }).
                ZnResponse serverError: 'Internal Server Error' ] ]

]

{ #category : 'recovery' }
BlennyMiddleware class >> recoverSilent [
    ^ [ :handler :request |
        [ handler value: request ]
            on: Error
            do: [ :ex |
                StringSignal emit: ('FATAL ERROR: {1}' format: { ex description }).
                (ZnResponse statusCode: 500)
                    entity: (ZnEntity text: 'Internal Server Error');
                    yourself ] ]
]

{ #category : 'authentication' }
BlennyMiddleware class >> requireAuth: authProvider [
    ^ [ :handler :request |
        | response user |
        user := self currentUserFrom: request using: authProvider.
        user ifNil: [ ^ ZnResponse redirect: '/login' ].
        response := handler value: request.
        response ]
]
