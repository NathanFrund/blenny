"
I hold configuration for a Blenny HTTP server instance.

I aggregate:
- port (e.g., 8081)
- rootPath (a FileReference to the application root, or nil for frozen mode)
- bindAddress (IP address to bind to, e.g., '0.0.0.0')
- derived properties: isDiskMode (true if rootPath not nil), templatesPath

I am instantiated by BlennyWebApp when starting the server, typically from
command‑line arguments, environment, or config file.

Example:

    config := BlennyServerConfig new.
    config port: 8081.
    config rootPath: '.' asFileReference.
    config bindAddress: '0.0.0.0'.
    (config isDiskMode) ifTrue: [ ... ]

I am used only during server setup; after that, the web app reads values from me.
"
Class {
	#name : 'BlennyServerConfig',
	#superclass : 'Object',
	#instVars : [
		'port',
		'bindAddress',
		'rootPath'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'instance creation' }
BlennyServerConfig class >> fromWebApp: aWebApp [
    "Create config from an existing BlennyWebApp (for transition)"
    ^ self new
        port: aWebApp port;
        rootPath: aWebApp rootPath;
        bindAddress: BlennyConfig current bindAddress;
        yourself
]

{ #category : 'accessing' }
BlennyServerConfig >> bindAddress [
    ^ bindAddress ifNil: [ '0.0.0.0' ]

]

{ #category : 'accessing' }
BlennyServerConfig >> bindAddress: aString [
    bindAddress := aString
]

{ #category : 'testing' }
BlennyServerConfig >> isDiskMode [
    ^ rootPath notNil
]

{ #category : 'accessing' }
BlennyServerConfig >> port [
    ^ port
]

{ #category : 'accessing' }
BlennyServerConfig >> port: anInteger [
    port := anInteger
]

{ #category : 'accessing' }
BlennyServerConfig >> rootPath [
    ^ rootPath
]

{ #category : 'accessing' }
BlennyServerConfig >> rootPath: aPath [
    rootPath := aPath
]

{ #category : 'accessing' }
BlennyServerConfig >> templatesPath [
    ^ rootPath ifNotNil: [ rootPath / 'templates' ]
]
