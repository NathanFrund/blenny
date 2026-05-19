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
   "Ensure we write a proper string representation:
    - strings (html) pass through
    - anything else (e.g., Dictionary for signals) is JSON-encoded"
   payload := payload isString 
      ifTrue: [ payload ] 
      ifFalse: [ NeoJSONWriter toString: payload ].
   eventName := (aMessage at: #category ifAbsent: [ #ui ]) = #ui
      ifTrue: [ 'message' ]
      ifFalse: [ (aMessage at: #category) asString ].
   ^ String streamContents: [ :stream |
      stream nextPutAll: 'event: '; nextPutAll: eventName; crlf.
      stream nextPutAll: 'data: '; nextPutAll: payload; crlf.
      stream crlf ]
]
