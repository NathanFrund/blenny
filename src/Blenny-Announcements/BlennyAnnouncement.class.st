"
I am the abstract base class for all Blenny announcements.

I provide a payload that can carry any data (string, dictionary, etc.).

Subclasses should specialize for specific message types:
    BlennyHTMLBroadcast   - HTML to all connected clients
    BlennyHTMLDirect      - HTML to specific user
    BlennyDataBroadcast   - JSON to all connected clients
    BlennyDataDirect      - JSON to specific user

Usage:
    ann := BlennyHTMLBroadcast payload: '<div>Hello</div>'.
    announcer announce: ann.

Instance variables:
    payload - The message content (string, dictionary, etc.)
"
Class {
	#name : 'BlennyAnnouncement',
	#superclass : 'Announcement',
	#instVars : [
		'payload'
	],
	#category : 'Blenny-Announcements',
	#package : 'Blenny-Announcements'
}

{ #category : 'accessing' }
BlennyAnnouncement class >> payload: anObject [
	^ self new payload: anObject
]

{ #category : 'accessing' }
BlennyAnnouncement >> payload [ 
	^ payload 
]

{ #category : 'accessing' }
BlennyAnnouncement >> payload: anObject [
	payload := anObject 
]
