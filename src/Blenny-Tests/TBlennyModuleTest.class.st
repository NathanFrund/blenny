Class {
	#name : 'TBlennyModuleTest',
	#superclass : 'TestCase',
	#category : 'Blenny-Tests',
	#package : 'Blenny-Tests'
}

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
