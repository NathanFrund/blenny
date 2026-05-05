"
I aggregate multiple BlennyConfigProvider instances in priority order.

I consult each provider in turn, returning the first non-nil value.
This allows a blenny.json file to override only the keys it contains, while
falling back to environment variables and embedded defaults.

Usage:
    composite := BlennyCompositeConfigProvider new.
    composite addProvider: BlennyFileConfigProvider new.
    composite addProvider: BlennyEmbeddedConfigProvider new.
    BlennyConfig new provider: composite.
"
Class {
	#name : 'BlennyCompositeConfigProvider',
	#superclass : 'BlennyConfigProvider',
	#instVars : [
		'providers'
	],
	#category : 'Blenny-Config',
	#package : 'Blenny-Config'
}

{ #category : 'adding' }
BlennyCompositeConfigProvider >> addProvider: aConfigProvider [
   providers add: aConfigProvider.
]

{ #category : 'accessing' }
BlennyCompositeConfigProvider >> at: aKey [
   providers do: [ :provider |
      | value |
      value := provider at: aKey ifAbsent: [ nil ].
      value notNil ifTrue: [ ^ value ] ].
   ^ nil.
]

{ #category : 'testing' }
BlennyCompositeConfigProvider >> hasConfig [
   ^ providers anySatisfy: [ :p | p hasConfig ].
]

{ #category : 'initialization' }
BlennyCompositeConfigProvider >> initialize [
   super initialize.
   providers := OrderedCollection new.
]
