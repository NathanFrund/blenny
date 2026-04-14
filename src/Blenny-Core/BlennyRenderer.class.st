"
I bridge Conduit's template rendering to Blenny.

I use the TConduitRenderer and THtmxRenderer traits to provide:
- HTMX-aware rendering (full page vs fragment)
- Template lookup from disk (development) or frozen methods (production)
- Layout support with {{content}} placeholder

I am created by BlennyWebApp with:
    renderer := BlennyRenderer new
        initializeWithConduit: conduit
        rootPath: rootPath.

Usage in routes:
    ""Render a full page with layout""
    html := renderer renderPage: 'dashboard' context: {'user' -> 'alice'} asDictionary.
    
    ""Render just a fragment (for HTMX)""
    html := renderer render: 'partials/form' request: request context: Dictionary new.

I delegate all rendering to the traits, so I mainly exist to hold the conduit reference.
"
Class {
	#name : 'BlennyRenderer',
	#superclass : 'Object',
	#traits : 'TConduitRenderer + THtmxRenderer',
	#classTraits : 'TConduitRenderer classTrait + THtmxRenderer classTrait',
	#instVars : [
		'conduit',
		'rootPath'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'accessing' }
BlennyRenderer >> conduit [
	^ conduit
]

{ #category : 'initialization' }
BlennyRenderer >> initializeWithConduit: aConduit rootPath: aPath [
    conduit := aConduit.
    rootPath := aPath.
]
