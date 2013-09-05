//
//  BRSearchService.h
//  BRFullTextSearch
//
//  Created by Matt on 6/5/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "BRIndexable.h"
#import "BRIndexUpdateContext.h"
#import "BRSearchFields.h"
#import "BRSearchResult.h"
#import "BRSearchResults.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
	BRSearchSortTypeString = 0,
	BRSearchSortTypeInteger,
	BRSearchObjectTypeFloat,
} BRSearchSortType;

#ifdef __cplusplus
}
#endif

// standard completion callback; if error will be nil unless a problem occurred
typedef void (^BRSearchServiceCallbackBlock)(NSError *error);
typedef void (^BRSearchServiceUpdateCallbackBlock)(int updateCount, NSError *error);

@protocol BRSearchService <NSObject>

#pragma mark - Indexing

// add an object to the index, calling the finished block on completion (if not NULL) using the provided queue
// or a global queue if finishedQueue is NULL
- (void)addObjectToIndex:(id<BRIndexable>)object queue:(dispatch_queue_t)finishedQueue finished:(BRSearchServiceCallbackBlock)finished;
- (void)addObjectsToIndex:(NSArray *)objects queue:(dispatch_queue_t)finishedQueue finished:(BRSearchServiceCallbackBlock)finished;

// add an object to the index and block until it has been added
- (void)addObjectToIndexAndWait:(id<BRIndexable>)object error:(NSError *__autoreleasing *)error;
- (void)addObjectsToIndexAndWait:(NSArray *)objects error:(NSError *__autoreleasing *)error;

// bulk update
typedef void (^BRSearchServiceIndexUpdateBlock)(id<BRIndexUpdateContext>updateContext);
- (void)bulkUpdateIndex:(BRSearchServiceIndexUpdateBlock)updateBlock queue:(dispatch_queue_t)finishedQueue finished:(BRSearchServiceUpdateCallbackBlock)finishedBlock;
- (BOOL)bulkUpdateIndexAndWait:(BRSearchServiceIndexUpdateBlock)updateBlock error:(NSError *__autoreleasing *)error;
- (void)addObjectToIndex:(id<BRIndexable>)object context:(id<BRIndexUpdateContext>)updateContext;

// return count of documents removed, or -1 for error
- (int)removeObjectFromIndex:(BRSearchObjectType)type withIdentifier:(NSString *)identifier context:(id<BRIndexUpdateContext>)updateContext;
- (int)removeObjectsFromIndexMatchingPredicate:(NSPredicate *)predicate context:(id<BRIndexUpdateContext>)updateContext;

// remove a set of objects from the index based on their identifiers, calling the finished block on completion (if not NULL)
// using the provided queue or a global queue if queue is NULL
- (void)removeObjectsFromIndex:(BRSearchObjectType)type
			   withIdentifiers:(NSSet *)identifiers
						 queue:(dispatch_queue_t)finishedQueue
					  finished:(BRSearchServiceUpdateCallbackBlock)finished;

// remove a set of objects from the index based on their identifiers, blocking until finished
- (int)removeObjectsFromIndexAndWait:(BRSearchObjectType)type
					  withIdentifiers:(NSSet *)identifiers
							   error:(NSError *__autoreleasing *)error;

// remove a set of objects from the index matching a search result set, calling the finished block on completion (if not NULL)
// using the provided queue or a global queue if queue is NULL
- (void)removeObjectsFromIndexMatchingPredicate:(NSPredicate *)predicate
										  queue:(dispatch_queue_t)finishedQueue
									   finished:(BRSearchServiceUpdateCallbackBlock)finished;

// remove a set of objects from the index matching a search result set, blocking until finished
- (int)removeObjectsFromIndexMatchingPredicateAndWait:(NSPredicate *)predicate error:(NSError *__autoreleasing *)error;

#pragma mark - Searching

// search using a native search query; the query string must be parseable by the implementing search service;
// results are ordered according to relevancy in descending order (most relevant first)
- (id<BRSearchResults>)search:(NSString *)query;

// search and sort the results by a field
- (id<BRSearchResults>)search:(NSString *)query
					 sortBy:(NSString *)sortFieldName
				   sortType:(BRSearchSortType)sortType
				  ascending:(BOOL)ascending;

// search for a specific object in the index; return nil if not found
- (id<BRSearchResult>)findObject:(BRSearchObjectType)type withIdentifier:(NSString *)identifier;

// search using a predicate
- (id<BRSearchResults>)searchWithPredicate:(NSPredicate *)predicate
									sortBy:(NSString *)sortFieldName
								  sortType:(BRSearchSortType)sortType
								 ascending:(BOOL)ascending;

@end
