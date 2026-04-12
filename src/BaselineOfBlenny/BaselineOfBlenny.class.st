Class {
	#name : 'BaselineOfBlenny',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfBlenny',
	#package : 'BaselineOfBlenny'
}

{ #category : 'baselines' }
BaselineOfBlenny >> baseline: spec [
    <baseline>
    spec for: #common do: [
        "1. External Dependencies"
        spec 
            baseline: 'ZincHTTPComponents' 
            with: [ spec repository: 'github://svenvc/zinc/repository' ];
            baseline: 'JSONWebToken' 
            with: [ spec repository: 'github://ba-st-dependencies/JSONWebToken:v3' ];
            baseline: 'Conduit' 
            with: [ spec repository: 'github://NathanFrund/Conduit:main/src' ].

        "2. Internal Package Topology"
        
        "Config is the foundation"
        spec package: 'Blenny-Config'.

        "Core contains the App, Router, Bridges, and Handlers. 
         It requires Config and the external web/asset tools."
        spec package: 'Blenny-Core' with: [ 
            spec requires: #('Blenny-Config' 'ZincHTTPComponents' 'Conduit').
            spec includes: #('ZincHTTPComponents' -> #('WebSocket')) ].

        "Announcements provides the specialized messaging types 
         referenced by BlennyAnnouncerBridge."
        spec package: 'Blenny-Announcements' with: [ 
            spec requires: #('Blenny-Core') ].

        "Auth contains the login/logout logic and providers.
         It depends on Core (for handlers) and JWT for tokens."
        spec package: 'Blenny-Auth' with: [ 
            spec requires: #('Blenny-Core' 'JSONWebToken') ].

        "3. Groups"
        spec 
            group: 'default' with: #('Full');
            group: 'Core' with: #('Blenny-Core' 'Blenny-Config');
            group: 'Full' with: #('Blenny-Core' 'Blenny-Config' 'Blenny-Auth' 'Blenny-Announcements').
    ]
]
