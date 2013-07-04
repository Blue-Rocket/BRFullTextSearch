//
//  BRIndexable.h
//  BRFullTextSearch
//
//  Created by Matt on 6/6/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "BRSearchFields.h"

typedef enum {
	BRIndexableStorageTypeStore = 0,		// store the original in the index
	BRIndexableStorageTypeNone,				// do not store the original in the index
	BRIndexableStorageTypeCompressed,		// store the original in compressed form
} BRIndexableStorageType;

typedef enum {
	BRIndexableIndexTypeTokenized = 0,		// normal string tokenization
	BRIndexableIndexTypeUntokenized,		// do not tokenize
	BRIndexableIndexTypeNone,				// do not index
} BRIndexableIndexType;

@protocol BRIndexable <NSObject>

@required

- (BRSearchObjectType)indexObjectType;

// get an index-wide unique identifier
- (NSString *)indexIdentifier;

// get a dictionary of all fields to add to index; keys must be strings
- (NSDictionary *)indexFieldsDictionary;

@optional

// get the language to use for this Indexable
// TODO: (NSString *)indexAnalyzerLanguage:(NSString *)fieldName;

// get the storage type for a given field; as BRIndexableStorageType defaults to BRIndexableStorageTypeStore
// this need only be implemented if some field should be treated differently.
- (BRIndexableStorageType)indexFieldStorageType:(NSString *)fieldName;

// get the index type for a given field; as BRIndexableIndexType defaults to BRIndexableIndexTypeTokenized
// this need only be implemented if some field should be treated differently.
- (BRIndexableIndexType)indexFieldIndexType:(NSString *)fieldName;

@end
