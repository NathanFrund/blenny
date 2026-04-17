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
            with: [ spec repository: 'github://NathanFrund/Conduit:main/src' ];
				baseline: 'Soil' 
            with: [ spec repository: 'github://ApptiveGrid/Soil:v4/src' ].

        "2. Internal Package Topology"
        
        "Config is the foundation"
        spec package: 'Blenny-Config'.
        
        "Persistence provides storage contracts"
        spec package: 'Blenny-Persistence'.

        "Core contains the App, Router, Bridges, and Handlers. 
         It requires Config, Persistence, and the external web/asset tools."
        spec package: 'Blenny-Core' with: [ 
            spec requires: #('Blenny-Config' 'Blenny-Persistence' 'ZincHTTPComponents' 'Conduit').
            spec includes: #('ZincHTTPComponents' -> #('WebSocket')) ].

        "Announcements provides the specialized messaging types 
         referenced by BlennyAnnouncerBridge."
        spec package: 'Blenny-Announcements' with: [ 
            spec requires: #('Blenny-Core') ].

        "Auth contains the login/logout logic and providers.
         It depends on Core, Persistence, and JWT for tokens."
        spec package: 'Blenny-Auth' with: [ 
            spec requires: #('Blenny-Core' 'Blenny-Persistence' 'JSONWebToken') ].

        "Middleware provides composable request filters"
        spec package: 'Blenny-Middleware' with: [
            spec requires: #('Blenny-Core') ].

        "Modules provides pluggable application components"
        spec package: 'Blenny-Modules' with: [
            spec requires: #('Blenny-Core' 'Blenny-Auth') ].

        "3. Groups"
        spec 
            group: 'default' with: #('Full');
            group: 'Core' with: #('Blenny-Core' 'Blenny-Config' 'Blenny-Persistence');
            group: 'Auth' with: #('Blenny-Core' 'Blenny-Config' 'Blenny-Persistence' 'Blenny-Auth');
            group: 'Full' with: #('Blenny-Core' 'Blenny-Config' 'Blenny-Persistence' 'Blenny-Auth' 'Blenny-Announcements' 'Blenny-Middleware' 'Blenny-Modules');
				group: 'WithSoil' with: #('Full' 'Blenny-Persistence-Soil').
    ]
]
