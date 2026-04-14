"
I represent an HTML message to send directly to a specific user.

I am published to the announcer, and BlennyAnnouncerBridge sends me only to the specified user's connections on the '/ws/html' endpoint.

Usage:
    announcer announce: (BlennyHTMLDirect payload: '<div>Private</div>' toUser: 'alice').

Convenience via BlennyWebApp:
    BlennyWebApp directHtml: '<div>Private</div>' toUser: 'alice'
"
Class {
	#name : 'BlennyHTMLDirect',
	#superclass : 'BlennyDirectAnnouncement',
	#category : 'Blenny-Announcements',
	#package : 'Blenny-Announcements'
}
