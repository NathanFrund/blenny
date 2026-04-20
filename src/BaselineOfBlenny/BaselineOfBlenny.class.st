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
            with: [ spec repository: 'github://svenvc/NeoJSON/repository' ];
            baseline: 'ZincHTTPComponents'
            with: [ spec repository: 'github://svenvc/zinc/repository' ];
            baseline: 'JSONWebToken'
            with: [ spec repository: 'github://ba-st-dependencies/JSONWebToken:v3' ];
            baseline: 'Conduit'
            with: [ spec repository: 'github://NathanFrund/Conduit:main/src' ];
            baseline: 'P3' 
            with: [ spec repository: 'github://svenvc/P3' ].

        "Internal Packages"
        spec
            package: 'Blenny-Config';
            
            "1. Traits Package: This must load first as it has no internal dependencies"
            package: 'Blenny-Traits'
            with: [ spec requires: #( 'Blenny-Config' ) ];
            
            "2. Core: Now depends on Traits instead of defining them"
            package: 'Blenny-Core'
            with: [ spec requires: #( 'Blenny-Config' 'Blenny-Traits' 'Conduit' ) ];
            
            "3. Auth: Uses Traits, depends on Core"
            package: 'Blenny-Auth' 
            with: [ spec requires: #( 'Blenny-Core' 'Blenny-Traits' 'JSONWebToken' ) ];
            
            "4. Persistence: Uses Traits, depends on P3 and Core"
            package: 'Blenny-Persistence' 
            with: [ spec requires: #( 'P3' 'Blenny-Core' 'Blenny-Traits' ) ];
            
            package: 'Blenny-Announcements'
            with: [ spec requires: #( 'Blenny-Core' ) ];
            
            package: 'Blenny-Middleware'
            with: [ spec requires: #( 'Blenny-Core' 'ZincHTTPComponents' ) ];
            
            package: 'Blenny-Modules'
            with: [ spec requires: #( 'Blenny-Core' 'Blenny-Persistence' ) ].

        "Groups"
        spec
            group: 'default'
            with: #( 'Blenny-Traits' 'Blenny-Core' 'Blenny-Config' 'Blenny-Persistence'
                   'Blenny-Auth' 'Blenny-Announcements' 'Blenny-Middleware'
                   'Blenny-Modules' );
            group: 'Core'
            with: #( 'Blenny-Traits' 'Blenny-Core' 'Blenny-Config' 'Blenny-Persistence' );
            group: 'PostgreSQL' with: #( 'Blenny-Persistence' ) ]
]
