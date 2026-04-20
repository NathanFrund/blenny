"
I am a PostgreSQL implementation of TBlennyAuthRepository using prepared statements.

I store key-value data in a PostgreSQL table. All operations use prepared statements
for security and performance.

Connection URL format: psql://username:password@host:port/database

Example:
    ""Using URL directly""
    repo := BlennyPostgresRepository new
        connectTo: 'psql://blenny:secret@localhost:5432/blenny_db';
        autoMigrate.
    
    ""Using convenience constructor (easier to read)""
    repo := BlennyPostgresRepository 
        forHost: 'localhost'
        database: 'blenny_db'
        user: 'blenny'
        password: 'secret'.
    
    ""Auth methods come from TBlennyAuthRepository trait""
    repo saveUser: {'username' -> 'alice'. 'password' -> 'hash'} asDictionary.
    user := repo findUserByUsername: 'alice'.
"
Class {
	#name : 'BlennyPostgresRepository',
	#superclass : 'Object',
	#traits : 'TBlennyAuthRepository',
	#classTraits : 'TBlennyAuthRepository classTrait',
	#instVars : [
		'client',
		'connectionString',
		'tableName',
		'insertStatement',
		'selectStatement',
		'deleteStatement'
	],
	#category : 'Blenny-Persistence',
	#package : 'Blenny-Persistence'
}

{ #category : 'instance creation' }
BlennyPostgresRepository class >> forHost: aHost database: aDbName user: aUser password: aPassword table: aTableName [
    "Create a new repository with explicit credentials and table name"
    | url |
    url := 'psql://', aUser, ':', aPassword, '@', aHost, '/', aDbName.
    ^ self new
        connectTo: url;
        useTable: aTableName;
        autoMigrate;
        yourself
]

{ #category : 'instance creation' }
BlennyPostgresRepository class >> forHost: aHost port: aPort database: aDbName user: aUser password: aPassword table: aTableName [
    "Create a new repository with explicit credentials, custom port, and table name"
    | url |
    url := 'psql://', aUser, ':', aPassword, '@', aHost, ':', aPort asString, '/', aDbName.
    ^ self new
        connectTo: url;
        useTable: aTableName;
        autoMigrate;
        yourself
]

{ #category : 'instance creation' }
BlennyPostgresRepository class >> newWithConnectionString: aString [
    ^ self new
        connectTo: aString;
        autoMigrate;
        yourself
]

{ #category : 'accessing' }
BlennyPostgresRepository >> allKeys [
    "Return all keys in the repository"
    | sql result |
    sql := 'SELECT key FROM ', tableName, ' ORDER BY key'.
    result := client query: sql.
    ^ result data collect: [ :row | row first ]
]

{ #category : 'accessing' }
BlennyPostgresRepository >> at: aKey ifAbsent: aBlock [
    "Retrieve a value by key using prepared statement"
    | result |
    result := selectStatement query: { aKey asString }.
    
    "Check if the P3Result has any rows"
    result data ifEmpty: [ ^ aBlock value ].
    
    "The first 'first' gets the row, the second gets the 'value' column"
    ^ self deserializeValue: result data first first
]

{ #category : 'accessing' }
BlennyPostgresRepository >> at: aKey put: aValue [
    "Store a value by key using prepared statement"
    | json |
    json := self serializeValue: aValue.
    insertStatement execute: { aKey asString. json }.
    ^ aValue
]

{ #category : 'initialization' }
BlennyPostgresRepository >> autoMigrate [
    "Automatically create the storage table and prepare statements"
    self assert: [ tableName notNil ] 
        description: 'Table name not set. Call useTable: first.'.
    self createTableIfNeeded.
    self prepareStatements.
    ^ self
]

{ #category : 'transactions' }
BlennyPostgresRepository >> beginTransaction [
    client execute: 'BEGIN'.
]

{ #category : 'blacklist' }
BlennyPostgresRepository >> cleanupExpiredBlacklist [
    | now |
    now := DateAndTime now.
    self allKeys do: [ :key |
        (key beginsWith: 'blacklist_') ifTrue: [
            | expiration |
            expiration := self at: key ifAbsent: [ nil ].
            expiration ifNotNil: [
                "Handle legacy string format"
                (expiration isString) ifTrue: [
                    expiration := [ DateAndTime fromString: expiration ]
                        on: Error
                        do: [ nil ] ].
                (expiration isKindOf: DateAndTime) ifTrue: [
                    expiration <= now ifTrue: [
                        self removeKey: key ] ] ] ] ]
]

{ #category : 'accessing' }
BlennyPostgresRepository >> clear [
    | sql |
    sql := 'TRUNCATE TABLE ', tableName.
    client execute: sql
]

{ #category : 'initialize-release' }
BlennyPostgresRepository >> close [
    self closeStatements.
    client ifNotNil: [ client close ].
]

{ #category : 'initialization' }
BlennyPostgresRepository >> closeStatements [
    "Close all prepared statements"
    insertStatement ifNotNil: [ insertStatement close. insertStatement := nil ].
    selectStatement ifNotNil: [ selectStatement close. selectStatement := nil ].
    deleteStatement ifNotNil: [ deleteStatement close. deleteStatement := nil ].
]

{ #category : 'transactions' }
BlennyPostgresRepository >> commitTransaction [
    client execute: 'COMMIT'.
]

{ #category : 'initialization' }
BlennyPostgresRepository >> connectTo: aUrlString [
    "Connect to PostgreSQL using a full connection URL
     Format: psql://username:password@host:port/database"
    connectionString := aUrlString.
    client := P3Client new url: aUrlString.
    ^ self
]

{ #category : 'initialization' }
BlennyPostgresRepository >> createTableIfNeeded [
    "Create the storage table with the appropriate schema"
    | createSQL indexSQL |
    createSQL := 'CREATE TABLE IF NOT EXISTS ', tableName, ' (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )'.
    
    client execute: createSQL.
    
    indexSQL := 'CREATE INDEX IF NOT EXISTS idx_', tableName, '_updated_at 
        ON ', tableName, ' (updated_at)'.
    
    client execute: indexSQL.
]

{ #category : 'private - serialization' }
BlennyPostgresRepository >> deserializeValue: aString [
    "Convert STON string back into a real Pharo object"
    aString ifNil: [ ^ nil ].
    ^ STON fromString: aString
]

{ #category : 'initialization' }
BlennyPostgresRepository >> initialize [
    super initialize.
    "No default table name - MUST be set explicitly"
    tableName := nil.
    client := nil.
    connectionString := nil.
    insertStatement := nil.
    selectStatement := nil.
    deleteStatement := nil.
]

{ #category : 'blacklist' }
BlennyPostgresRepository >> isBlacklisted: jti [
    | expiration |
    expiration := self at: ('blacklist_', jti) ifAbsent: [ ^ false ].
    
    "If we got a String back (old JSON), convert it or skip it"
    (expiration isString) ifTrue: [ 
        expiration := [ DateAndTime fromString: expiration ] on: Error do: [ ^ false ] ].
    
    "Only compare if it's actually a DateAndTime"
    ^ (expiration isKindOf: DateAndTime) 
        ifTrue: [ expiration > DateAndTime now ]
        ifFalse: [ false ]
]

{ #category : 'testing' }
BlennyPostgresRepository >> isConnected [
    ^ client notNil and: [ client isConnected ]
]

{ #category : 'testing' }
BlennyPostgresRepository >> isEmpty [
    ^ self size = 0
]

{ #category : 'accessing' }
BlennyPostgresRepository >> keysContaining: aSubstring [
    ^ self keysMatching: '%', aSubstring, '%'
]

{ #category : 'accessing' }
BlennyPostgresRepository >> keysMatching: aPattern [
    "Return all keys matching a pattern (SQL LIKE)"
    | sql statement result |
    sql := 'SELECT key FROM ', tableName, ' WHERE key LIKE $1 ORDER BY key'.
    statement := client prepare: sql.
    result := statement query: { aPattern }.
    statement close.
    ^ result data collect: [ :row | row first ]

]

{ #category : 'accessing' }
BlennyPostgresRepository >> keysStartingWith: aPrefix [
    ^ self keysMatching: aPrefix, '%'
]

{ #category : 'initialization' }
BlennyPostgresRepository >> prepareStatements [
    "Prepare all SQL statements for reuse"
    | insertSQL selectSQL deleteSQL |
    
    insertSQL := 'INSERT INTO ', tableName, ' (key, value, updated_at)
        VALUES ($1, $2, CURRENT_TIMESTAMP)
        ON CONFLICT (key) DO UPDATE SET 
            value = $2, 
            updated_at = CURRENT_TIMESTAMP'.
    
    selectSQL := 'SELECT value FROM ', tableName, ' WHERE key = $1'.
    
    deleteSQL := 'DELETE FROM ', tableName, ' WHERE key = $1'.
    
    insertStatement := client prepare: insertSQL.
    selectStatement := client prepare: selectSQL.
    deleteStatement := client prepare: deleteSQL.
]

{ #category : 'initialization' }
BlennyPostgresRepository >> reconnect [
    self close.
    self connectTo: connectionString.
    self prepareStatements.
]

{ #category : 'removing' }
BlennyPostgresRepository >> removeKey: aKey [
    "Remove a value by key using prepared statement"
    deleteStatement execute: { aKey asString }.
]

{ #category : 'transactions' }
BlennyPostgresRepository >> rollbackTransaction [
    client execute: 'ROLLBACK'.

]

{ #category : 'private - serialization' }
BlennyPostgresRepository >> serializeValue: aValue [
    "Convert any Pharo object into a STON string"
    ^ STON toString: aValue
]

{ #category : 'accessing' }
BlennyPostgresRepository >> size [
    "Return the number of entries in the repository"
    | sql result |
    sql := 'SELECT COUNT(*) as count FROM ', tableName.
    result := client query: sql.
    ^ result data first first asInteger
]

{ #category : 'initialization' }
BlennyPostgresRepository >> useTable: aString [
    "Set the table name for storage (default: 'blenny_storage')"
    tableName := aString.
    "Invalidate prepared statements since table name changed"
    insertStatement := nil.
    selectStatement := nil.
    deleteStatement := nil.
    ^ self
]

{ #category : 'transactions' }
BlennyPostgresRepository >> withTransaction: aBlock [
    self beginTransaction.
    ^ [ aBlock value ]
        on: Error
        do: [ :ex | self rollbackTransaction. ex pass ].
    self commitTransaction
]
