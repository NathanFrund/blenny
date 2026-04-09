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
