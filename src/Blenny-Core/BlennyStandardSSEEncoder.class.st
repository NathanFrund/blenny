"
I produce plain, library‑agnostic Server‑Sent Events.

For messages with category #ui I emit:
    event: message
    data: <payload>

For other categories I use the category symbol as the event name, making it easy for
front‑end code (HTMX, Alpine, vanilla EventSource) to listen for custom events.

I am the default encoder for Blenny.  I depend on nothing outside Blenny-Core.
"
Class {
	#name : 'BlennyStandardSSEEncoder',
	#superclass : 'BlennySSEEncoder',
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'encoding' }
BlennyStandardSSEEncoder >> encodeMessage: aMessage [
   | payload eventName |
   payload := aMessage at: #html ifAbsent: [ aMessage at: #signals ifAbsent: [ ^ nil ] ].
   "Map #ui category to 'message' for HTMX/EventSource defaults, otherwise use the category symbol"
   eventName := (aMessage at: #category ifAbsent: [ #ui ]) = #ui
      ifTrue: [ 'message' ]
      ifFalse: [ (aMessage at: #category) asString ].

   ^ String streamContents: [ :stream |
      stream nextPutAll: 'event: '; nextPutAll: eventName; crlf.
      stream nextPutAll: 'data: '; nextPutAll: payload asString; crlf.
      stream crlf ]

]
