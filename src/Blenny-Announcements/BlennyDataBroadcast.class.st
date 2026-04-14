"
I represent a JSON message to broadcast to all connected WebSocket clients.

I am published to the announcer, and BlennyAnnouncerBridge sends me to all clients on the '/ws/data' endpoint.

Usage:
    announcer announce: (BlennyDataBroadcast payload: '{""type"":""update"",""value"":42}').

Convenience via BlennyWebApp:
    BlennyWebApp broadcastData: '{""type"":""update"",""value"":42}'.
"
Class {
	#name : 'BlennyDataBroadcast',
	#superclass : 'BlennyAnnouncement',
	#category : 'Blenny-Announcements',
	#package : 'Blenny-Announcements'
}
