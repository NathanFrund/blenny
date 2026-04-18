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
        
        spec package: 'Blenny-Config'.
        spec package: 'Blenny-Persistence'.

        spec package: 'Blenny-Core' with: [ 
            spec requires: #('Blenny-Config' 'Blenny-Persistence' 'ZincHTTPComponents' 'Conduit') ].

        spec package: 'Blenny-Announcements' with: [ 
            spec requires: #('Blenny-Core') ].

        spec package: 'Blenny-Auth' with: [ 
            spec requires: #('Blenny-Core' 'Blenny-Persistence' 'JSONWebToken') ].

        spec package: 'Blenny-Middleware' with: [
            spec requires: #('Blenny-Core') ].

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
