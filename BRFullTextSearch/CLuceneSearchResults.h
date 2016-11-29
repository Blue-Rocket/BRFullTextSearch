//
//  CLuceneSearchResults.h
//  BRFullTextSearch
//
//  Created by Matt on 7/1/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <memory>
#import "BRSearchResults.h"

namespace lucene {
	namespace search {
		class Hits;
		class Query;
		class Searcher;
		class Sort;
	}
}

/**
 * CLucene internal implementation of `BRSearchResults`.
 */
@interface CLuceneSearchResults : NSObject <BRSearchResults>

- (id)initWithHits:(std::auto_ptr<lucene::search::Hits>)theHits
			  sort:(std::auto_ptr<lucene::search::Sort>)theSort
			 query:(std::auto_ptr<lucene::search::Query>)theQuery
			 searcher:(std::shared_ptr<lucene::search::Searcher>)theSearcher;

@end
