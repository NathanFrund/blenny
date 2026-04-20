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
            baseline: 'NeoJSON'
            with: [ spec repository: 'github://svenvc/NeoJSON/repository' ].
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
            baseline: 'P3' 
            with: [ spec repository: 'github://svenvc/P3' ].

        "Internal Packages - Re-ordered to ensure Persistence loads LAST"
        spec
            package: 'Blenny-Config';
            
            "Core now only depends on Config and Conduit (Traits)"
            package: 'Blenny-Core'
            with: [ spec requires: #( 'Blenny-Config' 'Conduit' ) ];
            
            package: 'Blenny-Announcements'
            with: [ spec requires: #( 'Blenny-Core' ) ];
            
            "Auth now only depends on Core and JSON"
            package: 'Blenny-Auth' 
            with: [ spec requires: #( 'Blenny-Core' 'JSONWebToken' ) ];
            
            "Persistence is now the 'Final Boss'—it requires everything else to be present"
            package: 'Blenny-Persistence' 
            with: [ spec requires: #( 'P3' 'Blenny-Core' 'Blenny-Auth' ) ];
            
            package: 'Blenny-Middleware'
            with: [ spec requires: #( 'Blenny-Core' 'ZincHTTPComponents' ) ];
            
            package: 'Blenny-Modules'
            with: [ spec requires: #( 'Blenny-Core' 'Blenny-Persistence' ) ].

        "Groups"
        spec
            group: 'default'
            with: #( 'Blenny-Core' 'Blenny-Config' 'Blenny-Persistence'
                   'Blenny-Auth' 'Blenny-Announcements' 'Blenny-Middleware'
                   'Blenny-Modules' );
            group: 'Core'
            with: #( 'Blenny-Core' 'Blenny-Config' 'Blenny-Persistence' );
            group: 'PostgreSQL' with: #( 'Blenny-Persistence' ) ]
]
