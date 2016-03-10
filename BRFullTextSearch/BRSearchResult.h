//
//  BRSearchResult.h
//  BRFullTextSearch
//
//  Created by Matt on 6/5/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "BRSearchFields.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * API for a search result match.
 *
 * When performing searches, individual documents that match the query are returned as
 * objects conforming to this protocol. This API closely mirrors the `BRIndexable` API.
 *
 * @see BRIndexable
 */
@protocol BRSearchResult <NSObject>

/** Get the search document's object type for the match. */
@property (nonatomic, readonly) BRSearchObjectType objectType;

/** Get the search document's unique identifier for the match. */
@property (nonatomic, readonly) NSString *identifier;

/**
 * Get the value of a field.
 *
 * @param fieldName the name of the field to get the value for
 * @return the value of the field, or `nil` if no value is available
 */
- (nullable id)valueForField:(NSString *)fieldName;

/**
 * Get the date components, in local time, for a timestamp field.
 *
 * @param fieldName the name of a field whose value is a timestamp
 * @return the timestamp converted to a `NSDateComponents` in the runtime's current time zone
 */
- (NSDateComponents *)localDayForTimestampField:(NSString *)fieldName;

/**
 * Get all available field values as a dictionary.
 *
 * The keys in the returned dictionary represent the available field names in the search
 * document. The dictionary will include the search document's unique identifier and object type
 * (as `NSString` values). If a field contains more than one value the values will be stored in
 * a `NSArray` in the returned dictionary.
 *
 * @return a dictionary of all available field values
 */
- (NSDictionary *)dictionaryRepresentation;

@end

NS_ASSUME_NONNULL_END
