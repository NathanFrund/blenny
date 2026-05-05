"
I am a Beacon signal logger that records signals to a daily‑rotated log file.

On startup I create or append to `logs/blenny-YYYYMMDD.log` in the image directory.
I write every signal as a timestamped line, then flush the stream immediately.

Usage (typically in a startUp method):

    BlennyFileLogger attachToBeacon.
    StringSignal emit: 'Server started on port 8081'.
"
Class {
	#name : 'BlennyFileLogger',
	#superclass : 'SignalLogger',
	#instVars : [
		'fileStream'
	],
	#classVars : [
		'Current'
	],
	#category : 'Blenny-Core',
	#package : 'Blenny-Core'
}

{ #category : 'as yet unclassified' }
BlennyFileLogger class >> attachToBeacon [
   Current ifNotNil: [ Current stop ].
   Current := self new.
   Current start.
]

{ #category : 'as yet unclassified' }
BlennyFileLogger class >> detachFromBeacon [
   Current ifNotNil: [ Current stop ].
   Current := nil.
]

{ #category : 'initialization' }
BlennyFileLogger >> initialize [
   super initialize.
   self openLogFile.
]

{ #category : 'accessing' }
BlennyFileLogger >> labelFor: aSignal [
   aSignal class = StringSignal ifTrue: [ ^ 'INFO' ].
   aSignal class = WrapperSignal ifTrue: [ ^ 'ERROR' ].
   ^ 'SIGNAL'
]

{ #category : 'logging' }
BlennyFileLogger >> nextPut: aSignal [
   self record: aSignal
]

{ #category : 'logging' }
BlennyFileLogger >> openLogFile [
   | logDir logFile existingContent |
   logDir := FileLocator imageDirectory / 'logs'.
   logDir ensureCreateDirectory.
   logFile := logDir / ('blenny-' , Date today yyyymmdd , '.log').
   
   "Preserve existing content if file exists"
   existingContent := logFile exists
      ifTrue: [ logFile readStream contents ]
      ifFalse: [ '' ].
   
   "Open for write (truncates), then re-write existing content"
   fileStream := logFile writeStream.
   existingContent notEmpty ifTrue: [
      fileStream nextPutAll: existingContent ].
]

{ #category : 'actions api' }
BlennyFileLogger >> record: aSignal [
   | timestamp msg |
   timestamp := DateAndTime now printString.
   msg := String streamContents: [ :s |
      s
         nextPutAll: timestamp;
         nextPutAll: ' [';
         nextPutAll: (self labelFor: aSignal);
         nextPutAll: '] ';
         nextPutAll: aSignal printString;
         crlf ].
   fileStream ifNotNil: [ fileStream nextPutAll: msg; flush ].
]

{ #category : 'registration' }
BlennyFileLogger >> stop [
   fileStream ifNotNil: [ fileStream close ].
   super stop.
]
