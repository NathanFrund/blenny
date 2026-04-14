"
I read configuration from a JSON file named 'blenny.json' in the current working directory.

I am the third-highest priority provider (after command line and environment, before embedded defaults).

Example blenny.json:
    `{
        ""server.port"": 9000,
        ""server.bind_address"": ""0.0.0.0"",
        ""auth.jwt_secret"": ""my-production-secret"",
        ""auth.session_duration_hours"": 168,
        ""dev_mode"": false
    }`

I use dot notation for nested keys, avoiding the need for nested JSON objects.

My #hasConfig returns true if the file exists and contains configuration.

I am ideal for development and simple deployments where a config file is convenient.

"
Class {
	#name : 'BlennyFileConfigProvider',
	#superclass : 'BlennyConfigProvider',
	#instVars : [
		'config'
	],
	#category : 'Blenny-Config',
	#package : 'Blenny-Config'
}

{ #category : 'accessing' }
BlennyFileConfigProvider >> at: aKey [
    ^ config at: aKey ifAbsent: [ nil ]
]

{ #category : 'testing' }
BlennyFileConfigProvider >> hasConfig [
    ^ config notNil and: [ config isEmpty not ]
]

{ #category : 'initialization' }
BlennyFileConfigProvider >> initialize [ 
	super initialize.
	self loadConfig.
]

{ #category : 'loading' }
BlennyFileConfigProvider >> loadConfig [
    | file |
    file := 'blenny.json' asFileReference.
    file exists ifFalse: [ ^ self ].
    config := STON fromString: file contents.
]
