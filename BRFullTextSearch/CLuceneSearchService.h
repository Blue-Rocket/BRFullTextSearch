//
//  CLuceneSearchService.h
//  BRFullTextSearch
//
//  Created by Matt on 6/28/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "BRSearchService.h"

/**
 * Implementation of `BRSearchService` using **CLucene**. When indexing, only NSString, or
 * NSArray/NSSet with NSString values, are supported as field values.
 *
 * # Threading
 * 
 * This service supports concurrent updates and queries across different threads. All index updates
 * occurr internally on a single thread, and only one update operation is allowed to execute at a time.
 * Queries will not see the result of index updates until after the update is committed. For batch
 * updates that means at the completion of the batch operation.
 * 
 * # Exceptions
 * 
 * This service will translate @c CLuceneError C++ exceptions into Objective-C @c NSException instances.
 *
 * # Query syntax
 * 
 * When searching with string queries, the 
 * [lucene::queryParser::QueryParser](http://clucene.sourceforge.net/doc/html/classlucene_1_1queryParser_1_1QueryParser.html#_details)
 * class is used.
 * 
 * # Sorting
 * 
 * Lucene can only sort on fields that have a single term in them. Usually this means you are limited
 * to sorting on untokenized fields only, for example timestamp fields.
 * 
 * # Predicate query support
 * 
 * Predicate queries are fully supported, including nested predicates and boolean predicates.
 * The `NSEqualToPredicateOperatorType` and  `NSNotEqualToPredicateOperatorType` comparisons are 
 * used to match _untokenized_ values. The `NSLikePredicateOperatorType` and `NSMatchesPredicateOperatorType`
 * comparisons are used to match _tokenized_ values, that is the constant value in the expression
 * will be parsed and tokenized itself.
 * 
 * The `NSBeginsWithPredicateOperatorType` comparison results in prefix queries.
 * 
 * The `NSLessThanPredicateOperatorType`, `NSLessThanOrEqualToPredicateOperatorType`,
 * `NSGreaterThanPredicateOperatorType`, and `NSGreaterThanOrEqualToPredicateOperatorType` comparisons
 * result in range queries (note these can be slow and should be used carefully).
 */
@interface CLuceneSearchService : NSObject <BRSearchService>

/** Property to automatically optimize the index for faster searches, after this many updates have occurred. */
@property (nonatomic) NSInteger indexUpdateOptimizeThreshold;

/**
 * The bundle to load resources such as stop words from.
 *
 * Defaults to `[NSBundle mainBundle]`. The stop words resource must be named `stop-words.txt`.
 */
@property (nonatomic, strong) NSBundle *bundle;

/** 
 * The default language to use for text analyzers.
 * 
 * This should be a 2-character language code. Defaults to `en`.
 */
@property (nonatomic, strong) NSString *defaultAnalyzerLanguage;

/**
 * Turn stemming for tokenized fields on/off. Defaults to @c NO.
 *
 * @since 1.0.6
 */
@property (nonatomic, getter=isStemmingDisabled) BOOL stemmingDisabled;

/**
 * Turn support for prefix-based searches on tokenized and stemmed fields. Defaults to @c NO.
 * 
 * @since 1.0.5
 */
@property (nonatomic, getter=isSupportStemmedPrefixSearches) BOOL supportStemmedPrefixSearches;

/**
 * An array of string field names that should be treated as the _default_ tokenized text fields to search
 * when parsing query strings in the `search:` method to determine the _default_ field to use for
 * unprefixed search terms. This is **not** used by the predicate based search methods. You can still
 * explicitly specify the field to search for a query term by prefixing the term with the field name and
 * a colon.
 *
 * For example, by default a search for the phrase `special` will be parsed into the query `t:special OR v:special`.
 * If you configured this property with a single field name `z` the same phrase will be parsed into the
 * query `z:special`.
 * 
 * Defaults to an array with the `kBRSearchFieldNameTitle` (**t**) and `kBRSearchFieldNameValue` (**v**) field names.
 * 
 * @since 1.0.11
 */
@property (nonatomic, copy) NSArray<NSString *> *generalTextFields;

/**
 * Init the search service with a given path to use to store the index files.
 *
 * @param indexPath a directory in which to write the CLucene index files in
 * @return new instance
 */
- (instancetype)initWithIndexPath:(NSString *)indexPath;

/**
 Get the configured index path, which is a directory that contains the Lucene index files.
 */
@property (nonatomic, readonly) NSString *indexPath;

/**
 * Reset the searcher immediately.
 * 
 * Calling this method will reset the cached `lucene::search::Searcher`, so subsequent queries
 * pick up any new changes to the index. Normally this is done automatically on the main thread,
 * after any index modification operation completes. It is only possible to call this method from
 * the main thread, and only necessary to call if after indexing on the main thread you need to 
 * search immediately on the current runloop.
 */
- (void)resetSearcher;

/**
 * A `NSUserDefaults` key used to track the number of index updates between optimizations.
 */
- (NSString *)userDefaultsIndexUpdateCountKey;

@end
