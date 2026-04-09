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
