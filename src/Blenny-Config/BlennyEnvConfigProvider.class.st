"
I read configuration from environment variables.

Environment variables are prefixed with BLENNY_ and use uppercase with underscores.

Example:
    `export BLENNY_SERVER_PORT=9000
    export BLENNY_AUTH_JWT_SECRET=production-secret`

Key conversion:
    `'server.port' → 'BLENNY_SERVER_PORT'
    'auth.jwt_secret' → 'BLENNY_AUTH_JWT_SECRET'`

I am the second-highest priority provider (after command line, before config file).

My #hasConfig returns true if any BLENNY_* environment variables exist.

I am ideal for containerized deployments (Docker, Kubernetes) where environment variables are the standard configuration method.
"
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
