"
I am the abstract protocol for authentication providers in Blenny.

I define the contract that all auth providers must implement. This allows Blenny to work with any authentication system (in-memory, file, database, LDAP, OAuth, etc.).

Required methods (subclasses must implement):
    authenticate:username:password:  ""Return session token or nil""
    validateToken:                  ""Return userId or nil""
    logout:                         ""Invalidate session token""

Optional methods (default implementations provided):
    userExists:                     ""Check if user exists""
    createUser:password:            ""Create new user""
    deleteUser:                     ""Remove user""

Blenny ships with BlennySimpleAuth as a reference implementation (in-memory, JWT-based, for development).

To create a custom provider:
    Blenn圏AuthProvider subclass: #MyCustomAuth
        ""Implement authenticate:, validateToken:, and logout:""

Example:
    auth := MyCustomAuth new.
    token := auth authenticate: 'alice' password: 'secret'.
    userId := auth validateToken: token.
"
Class {
	#name : 'BlennyAuthProvider',
	#superclass : 'Object',
	#category : 'Blenny-Auth',
	#package : 'Blenny-Auth'
}
