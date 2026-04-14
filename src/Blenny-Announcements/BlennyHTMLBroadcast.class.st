"
I represent an HTML message to broadcast to all connected WebSocket clients.

I am published to the announcer, and BlennyAnnouncerBridge sends me to all clients on the '/ws/html' endpoint.

Usage:
    announcer announce: (BlennyHTMLBroadcast payload: '<div class=""alert"">Update</div>').

Convenience via BlennyWebApp:
    BlennyWebApp broadcastHtml: '<div>Update</div>'.
"
Class {
	#name : 'BlennyHTMLBroadcast',
	#superclass : 'BlennyAnnouncement',
	#category : 'Blenny-Announcements',
	#package : 'Blenny-Announcements'
}
