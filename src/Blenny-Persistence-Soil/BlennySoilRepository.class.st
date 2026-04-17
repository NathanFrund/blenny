Class {
	#name : 'BlennySoilRepository',
	#superclass : 'Object',
	#traits : 'TBlennyAuthRepository',
	#classTraits : 'TBlennyAuthRepository classTrait',
	#instVars : [
		'soil'
	],
	#category : 'Blenny-Persistence-Soil',
	#package : 'Blenny-Persistence-Soil'
}

{ #category : 'accessing' }
BlennySoilRepository >> allKeys [
    | txn result |
    txn := soil newTransaction.
    [ | root |
        root := txn root.
        result := (root at: 'users') keys , 
                  (root at: 'blacklist') keys , 
                  (root at: 'reset_tokens') keys.
        txn commit.
    ] on: Error do: [ :ex |
        txn abort.
        ex pass ].
    ^ result
]

{ #category : 'accessing' }
BlennySoilRepository >> at: aKey ifAbsent: aBlock [
    | txn |
    txn := soil newTransaction.
    ^ [ | root bucket |
        root := txn root.
        bucket := root at: (self bucketFor: aKey) ifAbsent: [ ^ aBlock value ].
        bucket at: aKey ifAbsent: aBlock
    ] ensure: [ txn abort ]
]

{ #category : 'accessing' }
BlennySoilRepository >> at: aKey put: aValue [
    self execute: [ :txn | | root bucket |
        root := txn root.
        bucket := root at: (self bucketFor: aKey) ifAbsentPut: [ Dictionary new ].
        bucket at: aKey put: aValue.
        
        "Essential for Soil v4 to persist changes"
        txn markDirty: root ].
    ^ aValue
]

{ #category : 'as yet unclassified' }
BlennySoilRepository >> bucketFor: aKey [
    "Determine which root bucket a key belongs to"
    (aKey beginsWith: 'user_') ifTrue: [ ^ 'users' ].
    (aKey beginsWith: 'blacklist_') ifTrue: [ ^ 'blacklist' ].
    (aKey beginsWith: 'reset_') ifTrue: [ ^ 'reset_tokens' ].
    ^ 'users'
]

{ #category : 'blacklist' }
BlennySoilRepository >> cleanupExpiredBlacklist [
    | now |
    now := DateAndTime now.
    soil commit: [ :txn |
        | blacklistBucket |
        blacklistBucket := txn root at: 'blacklist'.
        blacklistBucket keys copy do: [ :key |
            (blacklistBucket at: key) <= now ifTrue: [
                blacklistBucket removeKey: key ] ].
        txn markDirty: txn root ].
]

{ #category : 'as yet unclassified' }
BlennySoilRepository >> ensureRoots [
    soil commit: [ :txn |
        txn root ifNil: [ 
            txn root: Dictionary new.
            "Create your specific buckets right away"
            txn root at: 'users' put: Dictionary new.
            txn root at: 'blacklist' put: Dictionary new.
            txn markDirty: txn root ] ]
]

{ #category : 'execution' }
BlennySoilRepository >> execute: aBlock [
    | txn wasCommitted |
    txn := soil newTransaction.
    wasCommitted := false.
    ^ [ 
        | result |
        result := aBlock cull: txn.
        "Only commit if the transaction isn't read-only"
        txn commit.
        wasCommitted := true.
        result
    ] ensure: [ 
        wasCommitted ifFalse: [ txn abort ] ]
]

{ #category : 'initialization' }
BlennySoilRepository >> initializeWithPath: aPath [
    | pathRef |
    pathRef := aPath asFileReference.
    
    "Check if the soil index file exists to determine if the DB is already there"
    soil := (pathRef / 'soil.index') exists
        ifTrue: [ Soil openOnPath: pathRef fullName ]
        ifFalse: [ Soil createOnPath: pathRef fullName ].

    "Now that it is open/created, ensure the root structure exists"
    self ensureRoots.

    ^ soil
]

{ #category : 'removing' }
BlennySoilRepository >> removeKey: aKey [
    | txn |
    txn := soil newTransaction.
    [ | root bucket |
        root := txn root.
        bucket := root at: (self bucketFor: aKey) ifAbsent: [ ^ self ].
        bucket removeKey: aKey ifAbsent: [].
        txn commit.
    ] on: Error do: [ :ex |
        txn abort.
        ex pass ].
]
