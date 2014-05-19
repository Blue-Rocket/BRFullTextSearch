//
//  CLuceneSearchResult.h
//  BRFullTextSearch
//
//  Created by Matt on 7/1/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <memory>
#import "CLucene.h"
#import "BRSearchResult.h"

/**
 * CLucene internal implementation of `BRSearchResult`.
 */
@interface CLuceneSearchResult : NSObject <BRSearchResult>

+ (Class)searchResultClassForObjectTypeField:(const TCHAR *)objectTypeValue;
+ (Class)searchResultClassForDocument:(lucene::document::Document &)doc;

- (id)initWithHits:(lucene::search::Hits *)hits index:(const int32_t)index;
- (id)initWithOwnedHits:(std::auto_ptr<lucene::search::Hits>)hits index:(const int32_t)index;

@end
