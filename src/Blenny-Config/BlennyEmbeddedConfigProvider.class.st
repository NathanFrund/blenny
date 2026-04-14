"
I provide configuration values compiled directly into the image.

I am the lowest-priority provider and serve as the fallback when no other provider has values.

My defaults are defined in the #defaults method:
    server.port → 8081
    server.bind_address → '0.0.0.0'
    auth.jwt_secret → 'CHANGE-ME-EMBEDDED-DEFAULT'
    auth.session_duration_hours → 720 (30 days)
    dev_mode → true

I always return true for #hasConfig, ensuring there is always at least one provider.

To change the embedded defaults, modify the #defaults method and rebuild the image.

I am used automatically by BlennyConfig when no other provider is available.
"
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
