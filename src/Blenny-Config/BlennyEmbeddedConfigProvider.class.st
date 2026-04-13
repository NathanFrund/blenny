Class {
	#name : 'BlennyEmbeddedConfigProvider',
	#superclass : 'BlennyConfigProvider',
	#category : 'Blenny-Config',
	#package : 'Blenny-Config'
}

{ #category : 'accessing' }
BlennyEmbeddedConfigProvider >> at: aKey [
    ^ self defaults at: aKey ifAbsent: [ nil ]
]

{ #category : 'instance creation' }
BlennyEmbeddedConfigProvider >> defaults [

	^ {
		  ('server.port' -> 8081).
		  ('server.bind_address' -> '0.0.0.0').
		  ('auth.jwt_secret' -> 'CHANGE-ME-EMBEDDED-DEFAULT').
		  ('auth.session_duration_hours' -> 720).
		  ('dev_mode' -> true) } asDictionary
]

{ #category : 'testing' }
BlennyEmbeddedConfigProvider >> hasConfig [
    ^ true
]
