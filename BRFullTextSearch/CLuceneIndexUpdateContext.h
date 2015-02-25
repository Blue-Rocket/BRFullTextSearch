//
//  CLuceneIndexUpdateContext.h
//  BRFullTextSearch
//
//  Created by Matt on 6/28/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "BRIndexUpdateContext.h"

#import "CLucene.h"
#import "Clucene/index/IndexModifier.h"

/**
 * CLucene internal implementation of `BRIndexUpdateContext` to support bulk index modifications.
 */
@interface CLuceneIndexUpdateContext : NSObject <BRIndexUpdateContext>

- (id)initWithIndexModifier:(lucene::index::IndexModifier *)modifier;

@property (nonatomic) uint32_t updateCount;

/** Boolean flag to indicate that the index should be optimized for searching when the update is complete. */
@property (nonatomic) BOOL optimizeWhenDone;

- (lucene::index::IndexModifier *)modifier;
- (lucene::search::Searcher *)searcher;
- (void)addDocument:(std::auto_ptr<lucene::document::Document>)doc;
- (void)removeAllDocuments;
- (size_t)documentCount;
- (void)enumerateDocumentsUsingBlock:(void (^)(lucene::document::Document *obj, BOOL *remove))block;

@end
