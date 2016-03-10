//
//  BRSearchResults.h
//  BRFullTextSearch
//
//  Created by Matt on 6/6/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "BRSearchResult.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Block for iterating over search result matches.
 *
 * @param index the zero-based index of the match
 * @param result the match
 * @param stop if set to `YES` then iteration will be stopped
 */
typedef void (^BRSearchServiceSearchResultsIterator)(NSUInteger index, id <BRSearchResult> result, BOOL *stop);

/**
 * API for the results of executing a search.
 *
 * The results  object is a collection of `BRSearchResult` match objects
 */
@protocol BRSearchResults <NSObject>

/**
 * Get the total count of matches in the result of the search.
 *
 * @return number of matches
 */
- (NSUInteger)count;

/**
 * Get a match object for a given result index.
 *
 * @param index the zero-based match index to get
 * @return the match object for the given index
 */
- (id <BRSearchResult> )resultAtIndex:(NSUInteger)index;

/**
 * Iterate over all matches, in search result order.
 *
 * @param iterator the block to execute for each available match
 */
- (void)iterateWithBlock:(BRSearchServiceSearchResultsIterator)iterator;

/**
 * Group all matches by a given field.
 *
 * The results are assumed to be ordered appropriately for the grouping operation to
 * make sense. The resulting array will contain `NSArray` objects for each group, whose
 * values will be `id<BRSearchResult>` objects.
 *
 * @param fieldName the field name by which to group the results
 */
- (NSArray *)resultsGroupedByField:(NSString *)fieldName;

/**
 * Group all matches by a timestamp field, at day precision.
 *
 * The results are assumed to be ordered by date. The grouping keys will be created by
 * calling `localDayForTimestampField:` on each match. The resulting array will contain `NSArray`
 * objects for each group, whose values will be `id<BRSearchResult>` objects.
 */
- (NSArray *)resultsGroupedByDay:(NSString *)fieldName;

@end

NS_ASSUME_NONNULL_END

