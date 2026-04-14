"
!BlennyArgConfigProvider commentStamp: '2026-04-14 15:00' prior: 0!
I read configuration from command line arguments passed when launching the Pharo image.

I am the highest-priority provider, taking precedence over environment variables, config files, and embedded defaults.

Format:
    ./pharo Blenny.image --key=value --other-key=123

Example:
    ./pharo Blenny.image --server.port=9000 --auth.jwt_secret=cli-secret

Key conversion:
    '--server.port=9000' → key 'server.port' value '9000'

My #hasConfig returns true if any arguments begin with '--' and contain an equals sign.

I am ideal for:
- One-off configuration changes
- Scripting and automation
- Overriding settings without changing files or environment

Note: Values are always strings. Use the appropriate accessor (integerAt:, booleanAt:) for type conversion.

Precedence order:
    1. Command line arguments (this provider)
    2. Environment variables
    3. Config file
    4. Embedded defaults
"
Class {
	#name : 'BlennyArgConfigProvider',
	#superclass : 'BlennyConfigProvider',
	#instVars : [
		'args'
	],
	#category : 'Blenny-Config',
	#package : 'Blenny-Config'
}

{ #category : 'accessing' }
BlennyArgConfigProvider >> at: aKey [
    ^ args at: aKey ifAbsent: [ nil ]
]

{ #category : 'testing' }
BlennyArgConfigProvider >> hasConfig [
    ^ args notEmpty
]

{ #category : 'initialization' }
BlennyArgConfigProvider >> initialize [ 
	super initialize.
	self parseArgs.
]

{ #category : 'parsing' }
BlennyArgConfigProvider >> parseArgs [
    args := Dictionary new.
    (Smalltalk commandLine arguments) do: [ :arg |
        (arg beginsWith: '--') ifTrue: [
            | key value |
            key := (arg copyFrom: 3 to: (arg indexOf: $=) - 1).
            value := (arg copyAfter: $=).
            args at: key put: value ] ]

]
