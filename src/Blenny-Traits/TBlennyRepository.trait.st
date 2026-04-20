"
I am the base trait for all Blenny storage backends.

I provide a simple key-value contract that allows Blenny to work with
any storage system (memory, Soil, Redis, file system, etc.).

To implement a storage backend:
    1. Use this trait
    2. Implement at:put:, at:ifAbsent:, removeKey:, and allKeys
    3. The trait provides exists:, keysMatching:, and do: automatically

Example:
    Object subclass: #MyStorage
        uses: TBlennyRepository
    
    MyStorage >> at: aKey put: aValue
        ""Store in your backend""
    
    MyStorage >> at: aKey ifAbsent: aBlock
        ""Retrieve from your backend""
    
    MyStorage >> removeKey: aKey
        ""Delete from your backend""
    
    MyStorage >> allKeys
        ""Return all keys""
!
"
Trait {
	#name : 'TBlennyRepository',
	#category : 'Blenny-Traits',
	#package : 'Blenny-Traits'
}

{ #category : 'accessing' }
TBlennyRepository >> allKeys [
    "Return all keys in the repository"
    self subclassResponsibility
]

{ #category : 'accessing' }
TBlennyRepository >> at: aKey ifAbsent: aBlock [
    "Retrieve a value by key"
    self subclassResponsibility
]

{ #category : 'accessing' }
TBlennyRepository >> at: aKey put: aValue [
    "Store a value by key"
    self subclassResponsibility
]

{ #category : 'enumerating' }
TBlennyRepository >> do: aBlock [
    "Iterate over all key-value pairs"
    self allKeys do: [ :key |
        aBlock value: key value: (self at: key ifAbsent: [ nil ]) ]
]

{ #category : 'public' }
TBlennyRepository >> exists: aKey [
    "Check if key exists"
    ^ (self at: aKey ifAbsent: [ nil ]) notNil
]

{ #category : 'removing' }
TBlennyRepository >> removeKey: aKey [
    "Remove a value by key"
    self subclassResponsibility
]
