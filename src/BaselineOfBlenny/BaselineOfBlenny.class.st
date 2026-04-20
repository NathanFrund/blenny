Class {
	#name : 'BaselineOfBlenny',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfBlenny',
	#package : 'BaselineOfBlenny'
}

{ #category : 'baselines' }
BaselineOfBlenny >> baseline: spec [

	<baseline>
	spec for: #common do: [ "External Dependencies"
			spec
				baseline: 'NeoJSON'
				with: [ spec repository: 'github://svenvc/NeoJSON/repository' ].
			spec
				baseline: 'ZincHTTPComponents'
				with: [ spec repository: 'github://svenvc/zinc/repository' ].
			spec
				baseline: 'JSONWebToken'
				with: [
				spec repository: 'github://ba-st-dependencies/JSONWebToken:v3' ].
			spec
				baseline: 'Conduit'
				with: [ spec repository: 'github://NathanFrund/Conduit:main/src' ].
			spec baseline: 'P3' with: [ spec repository: 'github://svenvc/P3' ].

			"Internal Packages - Requirements explicitly inlined to ensure Trait availability"
			spec
				package: 'Blenny-Config';
				package: 'Blenny-Persistence' with: [ spec requires: #( 'P3' ) ];
				"Core requires Conduit because of TConduitRenderer and THtmxRenderer usage"
				package: 'Blenny-Core'
				with: [
						spec requires:
								#( 'Blenny-Config' 'Blenny-Persistence' 'Conduit' ) ];
				package: 'Blenny-Announcements'
				with: [ spec requires: #( 'Blenny-Core' ) ];
				package: 'Blenny-Auth' with: [
						spec requires:
								#( 'Blenny-Core' 'Blenny-Persistence' 'JSONWebToken' ) ];
				package: 'Blenny-Middleware'
				with: [ spec requires: #( 'Blenny-Core' 'ZincHTTPComponents' ) ];
				package: 'Blenny-Modules'
				with: [ spec requires: #( 'Blenny-Core' ) ].

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
