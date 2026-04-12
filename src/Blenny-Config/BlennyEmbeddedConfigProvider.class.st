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
	"Embedded defaults - compiled into the image"

	^ {
		  ('jwt_secret' -> 'CHANGE-ME-EMBEDDED-DEFAULT').
		  ('port' -> 8081).
		  ('bind_address' -> '127.0.0.1').
		  ('dev_mode' -> true).
		  ('show_config_warning' -> true) } asDictionary
]

{ #category : 'testing' }
BlennyEmbeddedConfigProvider >> hasConfig [
    ^ true
]

{ #category : 'instance creation' }
BlennyEmbeddedConfigProvider >> sdefaults [
	"Embedded defaults - compiled into the image"

	^ {
		  ('jwt_secret' -> 'CHANGE-ME-EMBEDDED-DEFAULT').
		  ('port' -> 8081).
		  ('bind_address' -> '127.0.0.1').
		  ('dev_mode' -> true).
		  ('show_config_warning' -> true) } asDictionary
]
