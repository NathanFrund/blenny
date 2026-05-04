"
I am the abstract strategy for encoding Blenny’s transport‑agnostic messages into SSE text.

My single responsibility is:
  encodeMessage: aMessage  →  return a String in SSE format

Subclasses decide the wire format.  Blenny ships with two concrete encoders:
  - BlennyStandardSSEEncoder   (default, plain SSE – works with EventSource / HTMX)
  - DatastarSSEEncoder         (optional, loaded via Blenny-Datastar package)

The message dictionary passed to #encodeMessage: contains keys like #html, #signals, #script, and #category.  

Encoders are free to ignore keys they don’t support.
"
Class {
	#name : 'BlennySSEEncoder',
	#superclass : 'Object',
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'encoding' }
BlennySSEEncoder >> encodeMessage: aMessage [
   self subclassResponsibility
]
