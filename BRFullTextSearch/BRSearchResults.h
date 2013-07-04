//
//  BRSearchResults.h
//  BRFullTextSearch
//
//  Created by Matt on 6/6/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "BRSearchResult.h"

typedef void (^BRSearchServiceSearchResultsIterator)(NSUInteger index, id<BRSearchResult> result, BOOL *stop);

@protocol BRSearchResults <NSObject>

- (NSUInteger)count;
- (id<BRSearchResult>)resultAtIndex:(NSUInteger)index;
- (void)iterateWithBlock:(BRSearchServiceSearchResultsIterator)iterator;

// group all results by a given field; the results are assumed to be already sorted
// appropriately; return array of arrays for each group
- (NSArray *)resultsGroupedByField:(NSString *)fieldName;

// group all results by a given field; the field is assumed to contain a time stamp string key;
// the results are assumed to be already sorted appropriately; return array of arrays for each group
- (NSArray *)resultsGroupedByDay:(NSString *)fieldName;

@end
