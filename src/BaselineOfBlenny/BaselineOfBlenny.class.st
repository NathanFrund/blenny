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
        "External Dependencies"
        spec 
            baseline: 'ZincHTTPComponents' 
            with: [ spec repository: 'github://svenvc/zinc/repository' ].
        spec 
            baseline: 'JSONWebToken' 
            with: [ spec repository: 'github://ba-st-dependencies/JSONWebToken:v3' ].
        spec 
            baseline: 'Conduit' 
            with: [ spec repository: 'github://NathanFrund/Conduit:main/src' ].
        spec 
            baseline: 'Soil' 
            with: [ spec repository: 'github://ApptiveGrid/Soil:v4/src' ].

        "Internal Packages"
        spec package: 'Blenny-Config'.
        spec package: 'Blenny-Persistence'.
        spec package: 'Blenny-Core'.
        spec package: 'Blenny-Announcements'.
        spec package: 'Blenny-Auth'.
        spec package: 'Blenny-Middleware'.
        spec package: 'Blenny-Modules'.

        "Dependencies"
        spec package: 'Blenny-Core' with: [ spec requires: #('Blenny-Config' 'Blenny-Persistence') ].
        spec package: 'Blenny-Announcements' with: [ spec requires: #('Blenny-Core') ].
        spec package: 'Blenny-Auth' with: [ spec requires: #('Blenny-Core' 'Blenny-Persistence') ].
        spec package: 'Blenny-Middleware' with: [ spec requires: #('Blenny-Core') ].
        spec package: 'Blenny-Modules' with: [ spec requires: #('Blenny-Core') ].

        "Groups"
        spec group: 'default' with: #('Blenny-Core' 'Blenny-Config' 'Blenny-Persistence' 'Blenny-Auth' 'Blenny-Announcements' 'Blenny-Middleware' 'Blenny-Modules').
        spec group: 'Core' with: #('Blenny-Core' 'Blenny-Config' 'Blenny-Persistence').
    ]
]
