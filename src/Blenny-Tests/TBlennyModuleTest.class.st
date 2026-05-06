Class {
	#name : 'TBlennyModuleTest',
	#superclass : 'TestCase',
	#category : 'Blenny-Tests',
	#package : 'Blenny-Tests'
}

{ #category : 'tests' }
TBlennyModuleTest >> testIsEnabledFlag [
    "Verify that TBlennyModule's isEnabled flag controls module discovery."
    | enabledClass disabledClass discovered |
    
    [ 
        "1. Create an enabled module using the Fluid API"
        enabledClass := Object << #TestEnabledModule
            traits: TBlennyModule;
            package: 'Blenny-Tests-Temp';
            install.
        
        "2. Create a disabled module"
        disabledClass := Object << #TestDisabledModule
            traits: TBlennyModule;
            package: 'Blenny-Tests-Temp';
            install.
            
        "Override the class-side method provided by the trait"
        disabledClass class compile: 'isEnabled ^ false' classified: 'testing'.
        
        "Act: Filter users of the trait based on the flag"
        discovered := TBlennyModule users select: [ :each | each isEnabled ].
        
        "Assert"
        "Note: TBlennyModule isEnabled returns true by default "
        self assert: (discovered includes: enabledClass).
        self deny: (discovered includes: disabledClass).

    ] ensure: [ 
        "Cleanup"
        enabledClass ifNotNil: [ enabledClass removeFromSystem ].
        disabledClass ifNotNil: [ disabledClass removeFromSystem ].
    ].
]

{ #category : 'tests' }
TBlennyModuleTest >> testModuleDiscovery [
    | modules |
    modules := TBlennyModule users.
    "At minimum, DashboardModule should be found"
    self assert: (modules includes: DashboardModule).
]

{ #category : 'tests' }
TBlennyModuleTest >> testModuleName [
    | module |
    module := DashboardModule new.
    self assert: module moduleName equals: 'dashboard'.
]
