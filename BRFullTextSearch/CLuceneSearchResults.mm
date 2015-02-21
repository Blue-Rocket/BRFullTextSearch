//
//  CLuceneSearchResults.mm
//  BRFullTextSearch
//
//  Created by Matt on 7/1/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "CLuceneSearchResults.h"

#import "CLucene.h"
#import "CLuceneSearchResult.h"
#import "NSString+CLuceneAdditions.h"

using namespace lucene::document;
using namespace lucene::search;

@implementation CLuceneSearchResults {
	std::auto_ptr<Hits> hits;
	std::auto_ptr<Sort> sort;
	std::auto_ptr<Query> query;
	std::tr1::shared_ptr<Searcher> searcher;
}

- (id)initWithHits:(std::auto_ptr<lucene::search::Hits>)theHits
			  sort:(std::auto_ptr<lucene::search::Sort>)theSort
			 query:(std::auto_ptr<lucene::search::Query>)theQuery
		  searcher:(std::tr1::shared_ptr<lucene::search::Searcher>)theSearcher {
	if ( (self = [super init]) ) {
		hits = theHits;
		sort = theSort;
		query = theQuery;
		searcher = theSearcher;
	}
	return self;
}

- (NSString *)description {
	NSString *queryDescription = nil;

	TCHAR *queryDebug = NULL;
	queryDebug = query->toString();
	if ( queryDebug != NULL ) {
		queryDescription = [NSString stringWithCLuceneString:queryDebug];
		free(queryDebug);
	}
	return [NSString stringWithFormat:@"CLuceneSearchResults{hits=%lu, query=%@}", (unsigned long)[self count], queryDescription];
}

- (NSUInteger)count {
	return (NSUInteger)hits->length();
}

- (id<BRSearchResult>)resultAtIndex:(NSUInteger)index {
	int32_t luceneIndex = (int32_t)index;
	Document &doc = hits->doc(luceneIndex);
	return [[[CLuceneSearchResult searchResultClassForDocument:doc] alloc] initWithHits:hits.get() index:luceneIndex];
}

- (void)iterateWithBlock:(BRSearchServiceSearchResultsIterator)iterator {
	BOOL stop = NO;
	int32_t i;
	size_t len;
	for ( i = 0, len = hits->length(); i < len && stop == NO; i++ ) {
		@autoreleasepool {
			Document &doc = hits->doc(i);
			CLuceneSearchResult *result = [[[CLuceneSearchResult searchResultClassForDocument:doc] alloc] initWithHits:hits.get() index:i];
			iterator(i, result, &stop);
		}
	}
}

- (NSArray *)resultsGroupedByField:(NSString *)fieldName {
	NSMutableArray *result = [NSMutableArray new];
	NSMutableArray *currGroup = nil;
	id lastValue = nil;
	int32_t i;
	size_t len;
	for ( i = 0, len = hits->length(); i < len; i++ ) {
		Document &doc = hits->doc(i);
		CLuceneSearchResult *sr = [[[CLuceneSearchResult searchResultClassForDocument:doc] alloc] initWithHits:hits.get() index:i];
		id currValue = [sr valueForField:fieldName];
		if ( lastValue == nil || [lastValue isEqual:currValue] == NO ) {
			currGroup = [NSMutableArray new];
			[result addObject:currGroup];
		}
		[currGroup addObject:sr];
		lastValue = currValue;
	}
	return result;
}

- (NSArray *)resultsGroupedByDay:(NSString *)fieldName {
	NSMutableArray *result = [NSMutableArray new];
	NSMutableArray *currGroup = nil;
	NSDateComponents *lastValue = nil;
	int32_t i;
	size_t len;
	for ( i = 0, len = hits->length(); i < len; i++ ) {
		Document &doc = hits->doc(i);
		CLuceneSearchResult *sr = [[[CLuceneSearchResult searchResultClassForDocument:doc] alloc] initWithHits:hits.get() index:i];
		NSDateComponents *currValue = [sr localDayForTimestampField:fieldName];
		if ( lastValue == nil || [lastValue isEqual:currValue] == NO ) {
			currGroup = [NSMutableArray new];
			[result addObject:currGroup];
		}
		[currGroup addObject:sr];
		lastValue = currValue;
	}
	return result;
}

@end
