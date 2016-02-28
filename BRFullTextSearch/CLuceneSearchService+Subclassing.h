//
//  CLuceneSearchService+Subclassing.h
//  BRFullTextSearch
//
//  Created by Matt on 29/02/16.
//  Copyright © 2016 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "CLuceneSearchService.h"

#import <memory>
#import "CLucene/_ApiHeader.h"
#import "CLucene/analysis/AnalysisHeader.h"

NS_ASSUME_NONNULL_BEGIN

using namespace lucene::analysis;

/**
 An API to help with subclassing `CLuceneSearchService`. Classes that wish to extend `CLuceneSearchService` can import
 this header to expose additional methods that can be overridden in subclasses. This API is kept separate so that
 C++ objects are not exposed to "normal" users of the class.
 */
@interface CLuceneSearchService (Subclassing)

/**
 The `lucene::analysis::Analyzer` to use for tokenized fields during indexing as well as unprefixed query terms
 when searching with the `search:` method. If not configured, a `lucene::analysis::snowball::BRSnowballAnalyzer` 
 instance will be created and returned.
 
 @return The analyzer to use.
 */
- (Analyzer *)defaultAnalyzer;

/**
 Set the `lucene::analysis::Analyzer` to use for tokenized fields during indexing as well as unprefixed query terms
 when searching with the `search:` method.
 
 If a class that does not extend from `lucene::analysis::snowball::BRSnowballAnalyzer` is used, then the 
 `supportStemmedPrefixSearches` property might also need to be overridden because that property mutates the 
 `prefixMode` property of `BRSnowballAnalyzer`. Similarly, the `stemmingDisabled` property might also need to be
 overridden because that property mutates the property also named `stemmingDisabled` of `BRSnowballAnalyzer`.

 @param analyzer The analyzer to use.
 @since 1.0.11
 */
- (void)setDefaultAnalyer:(std::auto_ptr<Analyzer>)analyzer;

@end

NS_ASSUME_NONNULL_END
