"
I represent a JSON message to send directly to a specific user.

I am published to the announcer, and BlennyAnnouncerBridge sends me only to the specified user's connections on the '/ws/data' endpoint.

Usage:
    announcer announce: (BlennyDataDirect payload: '{""private"":true}' toUser: 'alice').

Convenience via BlennyWebApp:
    BlennyWebApp directData: '{""private"":true}' toUser: 'alice'.

"
Class {
	#name : 'BlennyDataDirect',
	#superclass : 'BlennyDirectAnnouncement',
	#category : 'Blenny-Announcements',
	#package : 'Blenny-Announcements'
}
