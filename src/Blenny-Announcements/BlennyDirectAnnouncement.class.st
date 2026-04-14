"
I am an abstract base class for direct messages to a specific user.

I extend BlennyAnnouncement with a recipientUserId.

Subclasses:
    BlennyHTMLDirect  - HTML content to specific user
    BlennyDataDirect  - JSON content to specific user

Usage:
    ann := BlennyHTMLDirect payload: '<div>Private</div>' toUser: 'alice'.
    announcer announce: ann.

Instance variables:
    payload         - The message content
    recipientUserId - The target user's ID
"
Class {
	#name : 'BlennyDirectAnnouncement',
	#superclass : 'BlennyAnnouncement',
	#instVars : [
		'recipientUserId'
	],
	#category : 'Blenny-Announcements',
	#package : 'Blenny-Announcements'
}

{ #category : 'instance' }
BlennyDirectAnnouncement class >> payload: aPayload toUser: aUserId [
	^ self new
		payload: aPayload;
		recipientUserId: aUserId ;
		yourself
]

{ #category : 'accessing' }
BlennyDirectAnnouncement >> recipientUserId [

	^ recipientUserId
]

{ #category : 'accessing' }
BlennyDirectAnnouncement >> recipientUserId: anObject [

	recipientUserId := anObject
]
