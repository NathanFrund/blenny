Class {
	#name : 'BlennyEnvConfigProvider',
	#superclass : 'BlennyConfigProvider',
	#category : 'Blenny-Config',
	#package : 'Blenny-Config'
}

{ #category : 'accessing' }
BlennyEnvConfigProvider >> at: aKey [
    | envKey |
    envKey := 'BLENNY_', aKey asUppercase.
    ^ OSEnvironment current at: envKey ifAbsent: [ nil ]
]

{ #category : 'testing' }
BlennyEnvConfigProvider >> hasConfig [
    "Return true if any Blenny env vars exist"
    ^ (OSEnvironment current keys anySatisfy: [ :key | key beginsWith: 'BLENNY_' ])
]
