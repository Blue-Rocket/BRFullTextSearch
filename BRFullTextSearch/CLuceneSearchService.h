//
//  CLuceneSearchService.h
//  BRFullTextSearch
//
//  Implementation of BRSearchService using CLucene. When indexing, only NSString, or
//  NSArray/NSSet with NSString values, are supported as field values.
//
//  Created by Matt on 6/28/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "BRSearchService.h"

@interface CLuceneSearchService : NSObject <BRSearchService>

// after this many updates, perform an optimize for faster searches
@property (nonatomic) NSInteger indexUpdateOptimizeThreshold;

// the bundle to load resources such as stop words from; defaults to [NSBundle mainBundle];
// the resource must be named "stop-words.txt"
@property (nonatomic, strong) NSBundle *bundle;

// the default language to use for text analyzers; defaults to "en"
@property (nonatomic, strong ) NSString *defaultAnalyzerLanguage;

- (id)initWithIndexPath:(NSString *)indexPath;

// can call to reset the cached lucene::search::Searcher, to pick up changes to the index;
// only thread safe if called from the main thread; only needed if after indexing you need
// to search immediately from the main thread before the searcher is automatically reset on
// the next main thread run loop execution.
- (void)resetSearcher;

// the NSUserDefaults key used to track the number of index updates between optimizations
- (NSString *)userDefaultsIndexUpdateCountKey;

@end
