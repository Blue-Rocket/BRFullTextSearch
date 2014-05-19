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

/**
 * A search result field value sort type.
 *
 * When sorting search results by a particular field, all field values are assumed to
 * have the same data type, as specified by these constants.
 */
typedef NS_ENUM (unsigned int, BRSearchSortType) {
	/** Sort based on lexicographical order of field values. */
	BRSearchSortTypeString = 0,

	/** Sort based on integer order of field values. */
	BRSearchSortTypeInteger,

	/** Sort based on floating point order of field values. */
	BRSearchSortTypeFloat,
};

#ifdef __cplusplus
}
#endif

/** A `NSError` domain for search services to use. */
extern NSString *const BRSearchServiceErrorDomain;

/**
 * A simple completion block callback.
 *
 * @param error an error, or `nil` if no error occurred
 */
typedef void (^BRSearchServiceCallbackBlock)(NSError *error);

/**
 * An update operation completion block callback.
 *
 * @param updateCount the number of updates that occurred
 * @param error an error, or `nil` if no error occurred
 */
typedef void (^BRSearchServiceUpdateCallbackBlock)(int updateCount, NSError *error);

/**
 * API for a service supporting both indexing documents and executing queries to find matches to those documents.
 *
 * This API works by supporting adding `BRIndexable` objects to, or removing them from, a searchable database,
 * or index. Once added to the index, other methods can be called to query for `BRSearchResult` objects matching
 * the query.
 *
 * Thread safety is implementation specific, however the API supports the notion of making modifications to the
 * index on background threads. Methods supporting modifications to the index generally accept a block callback
 * argument that will be executed when the modification is complete, as well as a dispatch queue to execute the
 * callback on. This does not guarantee the implementation actually supports modifying the index from arbitrary
 * threads, however. Consult the documentation of classes conforming to this protocol for details on the
 * threading model they support.
 */
@protocol BRSearchService <NSObject>

#pragma mark - Adding

///
/// @name Adding to the index
///

/**
 * Add a single object to the index.
 *
 * The `finished` block will be called when the index modification is complete.
 *
 * @param object the object to add to the index
 * @param finishedQueue the dispatch queue to execute the completion block on, or `NULL` for an arbitrary global queue
 * @param finished a block to execute after adding the object to the index, or `NULL`
 */
- (void)addObjectToIndex:(id <BRIndexable> )object queue:(dispatch_queue_t)finishedQueue finished:(BRSearchServiceCallbackBlock)finished;

/**
 * Add an array of objects to the index.
 *
 * The array is assumed to contain objects conforming to `BRIndexable`. The `finished` block will be called when
 * the index modification is complete.
 *
 * @param objects the array of `BRIndexable` objects to add to the index
 * @param finishedQueue the dispatch queue to execute the completion block on, or `NULL` for an arbitrary global queue
 * @param finished a block to execute after adding the object to the index, or `NULL`
 */
- (void)addObjectsToIndex:(NSArray *)objects queue:(dispatch_queue_t)finishedQueue finished:(BRSearchServiceCallbackBlock)finished;

/**
 * Add a single object to the index on the current thread.
 *
 * This method will block the calling thread until the object has been added to the index.
 *
 * @param object the object to add to the index
 * @param error a pointer to a `NSError` which will be set if some error occurs; pass `nil` if the error is not needed
 */
- (void)addObjectToIndexAndWait:(id <BRIndexable> )object error:(NSError *__autoreleasing *)error;

/**
 * Add an array of objects to the index on the current thread.
 *
 * The array is assumed to contain objects conforming to `BRIndexable`. This method will block the calling thread
 * until the objects have been added to the index.
 *
 * @param objects the array of `BRIndexable` objects to add to the index
 * @param error a pointer to a `NSError` which will be set if some error occurs; pass `nil` if the error is not needed
 */
// TODO: this should return a BOOL
- (void)addObjectsToIndexAndWait:(NSArray *)objects error:(NSError *__autoreleasing *)error;

#pragma mark - Removing

///
/// @name Removing from the index
///

/**
 * Remove a set of objects of the same type based on their unique identifiers.
 *
 * @param type the object type to remove
 * @param identifiers a set of search document unique identifiers to remove
 * @param finishedQueue the dispatch queue to execute the completion block on, or `NULL` for an arbitrary global queue
 * @param finished a block to execute after removing the objects from the index, or `NULL`
 */
- (void)removeObjectsFromIndex:(BRSearchObjectType)type
               withIdentifiers:(NSSet *)identifiers
                         queue:(dispatch_queue_t)finishedQueue
                      finished:(BRSearchServiceUpdateCallbackBlock)finished;

/**
 * Remove a set of objects of the same type based on their unique identifiers on the current thread.
 *
 * This method will block the calling thread until the object has been added to the index.
 *
 * @param type the object type to remove
 * @param identifiers a set of search document unique identifiers to remove
 * @param error a pointer to a `NSError` which will be set if some error occurs; pass `nil` if the error is not needed
 * @return the number of documents removed from the index
 */
- (int)removeObjectsFromIndexAndWait:(BRSearchObjectType)type
                     withIdentifiers:(NSSet *)identifiers
                               error:(NSError *__autoreleasing *)error;

/**
 * Remove a set of documents from the search index that match a predicate query.
 *
 * @param predicate the query to execute; all matching documents will be removed from the index
 * @param finishedQueue the dispatch queue to execute the completion block on, or `NULL` for an arbitrary global queue
 * @param finished a block to execute after removing the objects from the index, or `NULL`
 * @see searchWithPredicate:sortBy:sortType:ascending: for a discussion on predicate queries
 */
- (void)removeObjectsFromIndexMatchingPredicate:(NSPredicate *)predicate
                                          queue:(dispatch_queue_t)finishedQueue
                                       finished:(BRSearchServiceUpdateCallbackBlock)finished;

/**
 * Remove a set of documents from the search index that match a predicate query, on the current thread.
 *
 * This method will block the calling thread until the object has been added to the index.
 *
 * @param predicate the query to execute; all matching documents will be removed from the index
 * @param error a pointer to a `NSError` which will be set if some error occurs; pass `nil` if the error is not needed
 * @return the number of documents removed from the index
 * @see searchWithPredicate:sortBy:sortType:ascending: for a discussion on predicate queries
 */
- (int)removeObjectsFromIndexMatchingPredicateAndWait:(NSPredicate *)predicate error:(NSError *__autoreleasing *)error;

#pragma mark - Bulk modifications

///
/// @name Bulk modify the index
///

/**
 * A block callback function.
 *
 * @param updateContext an implementation-specific update context to pass to the bulk update methods
 */
typedef void (^BRSearchServiceIndexUpdateBlock)(id <BRIndexUpdateContext> updateContext);

/**
 * Perform a batch set of index update operations.
 *
 * Bulk updates to the index can be more efficient than a series of individual add or remove method calls. The
 * bulk update API works by first calling this method and providing a `BRSearchServiceIndexUpdateBlock` callback.
 * Within the callback you may then call any other bulk update method on the same search service, that is any
 * other method that accepts a `id<BRIndexUpdateContext>` method parameter. Upon return from the
 * `BRSearchServiceIndexUpdateBlock` callback, the index modifications will be committed to the index.
 *
 * @param updateBlock the bulk operations to perform
 * @param finishedQueue the dispatch queue to execute the completion block on, or `NULL` for an arbitrary global queue
 * @param finished a block to execute after the bulk operations are complete, or `NULL`
 */
- (void)bulkUpdateIndex:(BRSearchServiceIndexUpdateBlock)updateBlock queue:(dispatch_queue_t)finishedQueue finished:(BRSearchServiceUpdateCallbackBlock)finished;

/**
 * Perform a batch set of index update operations on the current thread.
 *
 * This method will block the calling thread until the bulk operations are complete.
 *
 * @param updateBlock the bulk operations to perform
 * @param error a pointer to a `NSError` which will be set if some error occurs; pass `nil` if the error is not needed
 * @return `YES` if the operations completed without error, `NO` otherwise
 * @see bulkUpdateIndex:queue:finished:
 */
- (BOOL)bulkUpdateIndexAndWait:(BRSearchServiceIndexUpdateBlock)updateBlock error:(NSError *__autoreleasing *)error;

#pragma mark - Bulk operations

///
/// @name Bulk operations
///

- (void)addObjectToIndex:(id <BRIndexable> )object context:(id <BRIndexUpdateContext> )updateContext;

// return count of documents removed, or -1 for error
/**
 * Bulk operation to remove a document from the search index.
 *
 * @param type the object type to remove
 * @param identifier the unique identifier of the object to remove
 * @param updateContext the bulk update context
 * @return the number of documents removed from the index, or `-1` if some error occurred
 */
- (int)removeObjectFromIndex:(BRSearchObjectType)type withIdentifier:(NSString *)identifier context:(id <BRIndexUpdateContext> )updateContext;

/**
 * Bulk operation to remove a set of documents from the search index that match a predicate query.
 *
 * @param predicate the query to execute; all matching documents will be removed from the index
 * @param updateContext the bulk update context
 * @return the number of documents removed from the index, or `-1` if some error occurred
 * @see searchWithPredicate:sortBy:sortType:ascending: for a discussion on predicate queries
 */
- (int)removeObjectsFromIndexMatchingPredicate:(NSPredicate *)predicate context:(id <BRIndexUpdateContext> )updateContext;

/**
 * Bulk operation to remove all documents from the search index.
 *
 * @param updateContext the bulk update context
 * @return the number of documents removed from the index, or `-1` if some error occurred
 */
- (int)removeAllObjectsFromIndex:(id <BRIndexUpdateContext> )updateContext;

#pragma mark - Searching

/**
 * Get a specific search document based on its unique identifier.
 *
 * @param type the object type to find
 * @param identifier the unique identifier of the object to find
 * @return the matching search document, or `nil` if not found
 */
- (id <BRSearchResult> )findObject:(BRSearchObjectType)type withIdentifier:(NSString *)identifier;

/**
 * Execute a search using an implementation-specific query string.
 *
 * The query string must be parseable by the implementing search service. The results are ordered according to
 * relevancy in descending order (most relevant first).
 *
 * @param query the search query
 * @return the search results
 */
- (id <BRSearchResults> )search:(NSString *)query;

/**
 * Execute a search using an implementation-specific query string, optionally sorting the results by a search document field.
 *
 * The query string must be parseable by the implementing search service.
 *
 * @param query the search query
 * @param sortFieldName the name of the search document field to order the matches by, or `nil` to sort by relevance
 * @param sortType the data type of the sort field (ignored if `sortFieldName` is `nil`)
 * @param ascending `YES` for ascending sort order, `NO` for descending (ignored if `sortFieldName` is `nil`)
 */
- (id <BRSearchResults> )search:(NSString *)query
                         sortBy:(NSString *)sortFieldName
                       sortType:(BRSearchSortType)sortType
                      ascending:(BOOL)ascending;

/**
 * Execute a search using a predicate, optionally sorting the results by a search document field.
 *
 * Predicates are constructed with field names as the left-hand expression, and the right-hand expression the constant
 * value to search for within that field. The supported comparison types is implementation specific, as is the support
 * for nested predicates and boolean predicates. Consult the documentation of the implementation for more information.
 *
 * @param sortFieldName the name of the search document field to order the matches by, or `nil` to sort by relevance
 * @param sortType the data type of the sort field (ignored if `sortFieldName` is `nil`)
 * @param ascending `YES` for ascending sort order, `NO` for descending (ignored if `sortFieldName` is `nil`)
 */
- (id <BRSearchResults> )searchWithPredicate:(NSPredicate *)predicate
                                      sortBy:(NSString *)sortFieldName
                                    sortType:(BRSearchSortType)sortType
                                   ascending:(BOOL)ascending;

@end
