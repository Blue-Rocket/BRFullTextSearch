//
//  BRSimpleIndexable.h
//  BRFullTextSearch
//
//  Created by Matt on 7/5/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRIndexable.h"

extern const BRSearchObjectType kBRSimpleIndexableSearchObjectType;

/**
 * A simple, dictionary-based implementation of `BRIndexable`.
 *
 * This implementation of `BRIndexable` manages search fields interally as dictionary of field name
 * keys and their associated values.
 */
@interface BRSimpleIndexable : NSObject <BRIndexable>

/** Convenience property for accessing a `kBRSearchFieldNameTitle` field. */
@property (nonatomic, retain) NSString *title;

/** Convenience property for accessing a `kBRSearchFieldNameValue` field. */
@property (nonatomic, retain) NSString *value;

/** Convenience property for accessing a `kBRSearchFieldNameTimestamp` field. */
@property (nonatomic, retain) NSDate *date;

/** Convenience property for accessing a `kBRSearchFieldNameIdentifier` field. */
@property (nonatomic, readonly) NSString *uid;

/**
 * Init with a specific unique identifier and field dictionary.
 *
 * The object type will be set to `kBRSimpleIndexableSearchObjectType`. A `kBRSearchFieldNameTimestamp` field
 * will be populated automatically if one does not exist already in the provided field dictionary.
 *
 * @param identifier the unique identifer for this search document
 * @param data the field values to associate with this search document
 */
- (instancetype)initWithIdentifier:(NSString *)identifier data:(NSDictionary *)data;

/**
 * Init with a specific object type, unique identifier, and field dictionary.
 *
 * A `kBRSearchFieldNameTimestamp` field will be populated automatically if one does not exist already
 * in the provided field dictionary.
 *
 * @param type the object type for this search document
 * @param identifier the unique identifer for this search document
 * @param data the field values to associate with this search document
 */
- (instancetype)initWithType:(BRSearchObjectType)type identifier:(NSString *)identifier data:(NSDictionary *)data;

/**
 * Directly modify the value for a field, or remove a field.
 *
 * @param object the field value to set, or `nil` to remove the field
 * @param key the field name to modify
 */
- (void)setDataObject:(id)object forKey:(NSString *)key;

@end
