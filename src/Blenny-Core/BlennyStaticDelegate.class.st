Class {
	#name : 'BlennyStaticDelegate',
	#superclass : 'Object',
	#instVars : [
		'webApp',
		'rootPath'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'public' }
BlennyStaticDelegate >> handleRequest: request [
    | uri path segments |
    uri := request uri.
    path := uri pathPrintString. "Force a visible string like '/' or '/static/css/style.css'"
    segments := uri segments.
    
    Transcript show: '--- New Request ---'; cr.
    Transcript show: 'Raw Path: ', path; cr.
    Transcript show: 'Segments: ', segments asString; cr.
    
    "1. Home Route - Check if segments is empty or just a slash"
    (path = '/' or: [ segments isEmpty ]) ifTrue: [
        Transcript show: 'Matched Home'; cr.
        ^ ZnResponse ok: (ZnEntity html: (webApp renderPage: 'index')) ].

    "2. Static Asset Route - Check the first segment"
    (segments notEmpty and: [ segments first = 'static' ]) ifTrue: [
        | diskFile subSegments |
        Transcript show: 'Matched Static'; cr.
        
        "Get everything after 'static'"
        subSegments := segments allButFirst.
        
        "Build file reference"
        diskFile := subSegments inject: rootPath asFileReference into: [ :parent :segment | parent / segment ].
        
        Transcript show: 'Looking for: ', diskFile pathString; cr.
        
        diskFile exists ifTrue: [
            Transcript show: '✓ Found'; cr.
            ^ ZnResponse ok: (ZnEntity with: diskFile binaryReadStream contents 
                                          type: (ZnMimeType forFilenameExtension: diskFile extension)) ].
        
        Transcript show: '✗ Not found on disk'; cr.
        ^ ZnResponse notFound: path ].

    "3. Fallback"
    Transcript show: 'No match, sending 404'; cr.
    ^ ZnResponse notFound: path.
]

{ #category : 'accessing' }
BlennyStaticDelegate >> rootPath: aRootPath [

rootPath := aRootPath 
]

{ #category : 'accessing' }
BlennyStaticDelegate >> webApp [
	^ webApp 
]

{ #category : 'accessing' }
BlennyStaticDelegate >> webApp: aWebApp [
	webApp := aWebApp 
]
