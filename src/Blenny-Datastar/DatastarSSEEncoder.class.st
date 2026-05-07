"
I format messages as Datastar Server‑Sent Events.

I live in the Blenny-Datastar package and require the Datastar-Pharo-SDK.

For #html messages I generate  event: datastar-patch-elements
For #signals            event: datastar-patch-signals
For #script            forwarded to DatastarGenerator>>executeScript:

Activate me by setting the config key 'sse.encoder' to #DatastarSSEEncoder in blenny.json.
"
Class {
	#name : 'DatastarSSEEncoder',
	#superclass : 'BlennySSEEncoder',
	#category : 'Blenny-Datastar',
	#package : 'Blenny-Datastar'
}

{ #category : 'as yet unclassified' }
DatastarSSEEncoder >> encodeMessage: aMessage [
   | stream generator |
   stream := WriteStream on: String new.
   generator := DatastarGenerator on: stream.
   aMessage at: #html ifPresent: [ :v | generator patchElements: v ].
   aMessage at: #signals ifPresent: [ :v | generator patchSignals: v ].
   aMessage at: #script ifPresent: [ :v | generator executeScript: v ].
   ^ stream contents
]
