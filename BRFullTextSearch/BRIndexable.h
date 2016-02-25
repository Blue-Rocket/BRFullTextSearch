//
//  BRIndexable.h
//  BRFullTextSearch
//
//  Created by Matt on 6/6/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "BRSearchFields.h"

NS_ASSUME_NONNULL_BEGIN

/** A search document original field value storage type. */
typedef NS_ENUM (unsigned int, BRIndexableStorageType) {
	/** Store the original field value in the index. Useful for tokenized or omitted field index types. */
	BRIndexableStorageTypeStore = 0,

	/** Do not store the original field value in the index. Useful for untokenized field types.*/
	BRIndexableStorageTypeNone,

	/** Store the original field value in compressed form in the index. Useful for large text values. */
	BRIndexableStorageTypeCompressed,
};

/** A search document field value index type. */
typedef NS_ENUM (unsigned int, BRIndexableIndexType) {
	/** Tokenize the field value in some way into implementation-specific search tokens. */
	BRIndexableIndexTypeTokenized = 0,

	/** Use the original field value as-is, without tokenization, in the index. Useful for document keys and flags. */
	BRIndexableIndexTypeUntokenized,

	/**
	 * Do not add the field value to the search index, meaning this field will not be considered when searching.
	 * The original value can still be stored in the search document for display in search results.
	 */
	BRIndexableIndexTypeNone,
};

/**
 * API for an object that is able to be indexed, that is added to the search index
 * as a unique search document.
 *
 * This API represents the information stored in a unique search index document.
 * Search index documents are assumed to be uniquely identified by both their
 * `indexObjectType` and `indexIdentifier` values. Thus two documents with the same
 * `indexIdentifier` but different `indexObjectType` values are considered distinct
 * documents.
 *
 * A search document is comprised of a set of named field values. A field might hold
 * multiple values, in which case its value will be returned as a `NSArray` object.
 */
@protocol BRIndexable <NSObject>

@required

/**
 * Get the type of object this document represents.
 *
 * Search documents are uniquely identified by combining their `indexObjectType` **and**
 * `indexIdentifier` values. The actual values used are arbitrary and application dependent.
 * Simple applications might use a single value for all search documents.
 *
 * @return the type of object
 */
- (BRSearchObjectType)indexObjectType;

/**
 * Get an object type-specific unique identifier this document represents.
 *
 * Search documents are uniquely identified by combining their `indexObjectType` **and**
 * `indexIdentifier` values.
 *
 * @return the type-specific unique identifier
 */
- (NSString *)indexIdentifier;

/**
 * Get a dictionary of search document fields.
 *
 * The keys in this dictionary must be `NSString` instances. The supported value types
 * is implementation dependent, but should at a minimum support `NSString` values. In
 * addition, if a given field can hold more than one value, it should be represented by
 * a `NSArray` of those values.
 *
 * @return a dictionary of search document fields; the keys must be strings
 */
- (NSDictionary *)indexFieldsDictionary;

@optional

// get the language to use for this Indexable
// TODO: (NSString *)indexAnalyzerLanguage:(NSString *)fieldName;

/**
 * Get the field stoarge type to use for a given field name.
 *
 * Field values may or may not be stored in their original form with the search document. You can save
 * processing time and storage space by not storing field values. If you want to be able to display
 * the original field value using the search document, however, you must store the field value.
 *
 * The default value for a field is `BRIndexableStorageTypeStore`. Implementations of this protocol
 * need only implement this method if they need to define a different value for one or more fields.
 *
 * @return the field storage type to use for the given field name
 */
- (BRIndexableStorageType)indexFieldStorageType:(NSString *)fieldName;

/**
 * Get the field index type to use for a given field name.
 *
 * Field values can be *tokenized* into search terms and the tokens stored in the index rather than the
 * original field value. Field values can also be *untokenized* to add the field value to the index as-is.
 * Finally, field values can be left out of the index completely, which is useful if you want to be able
 * to show the field in search results, but not consider that field when searching.
 *
 * The default value for a field is `BRIndexableIndexTypeTokenized`. Implementations of this protocol
 * need only implement this method if they need to define a different value for one or more fields.
 */
- (BRIndexableIndexType)indexFieldIndexType:(NSString *)fieldName;

@end

NS_ASSUME_NONNULL_END
