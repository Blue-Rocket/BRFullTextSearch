//
//  CLuceneIndexUpdateContext.m
//  BRFullTextSearch
//
//  Created by Matt on 6/28/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "CLuceneIndexUpdateContext.h"

using namespace lucene::document;
using namespace lucene::index;
using namespace lucene::search;

@implementation CLuceneIndexUpdateContext {
	std::list<Document*> docs; // default constructor called in alloc by runtime, and delete in dealloc
	IndexModifier *modifier;
	std::auto_ptr<Searcher> searcher;
	uint32_t updateCount;
}

@synthesize updateCount;

- (id)initWithIndexModifier:(IndexModifier *)theModifier {
	if ( (self = [super init]) ) {
		modifier = theModifier;
		updateCount = 0;
	}
	return self;
}

- (void)dealloc {
	[self removeAllDocuments];
}

- (IndexModifier *)modifier {
	return modifier;
}

- (Searcher *)searcher {
	if ( searcher.get() == NULL ) {
		searcher.reset(new IndexSearcher(modifier->getDirectory()));
	}
	return searcher.get();
}

- (void)addDocument:(std::auto_ptr<Document>)doc {
	// we are claiming ownership of doc now!
	Document *d = doc.release();
	docs.push_back(d);
}

- (size_t)documentCount {
	return docs.size();
}

- (void)removeAllDocuments {
	// we claimed ownership of all added docs, so delete them when removing
	std::list<Document *>::iterator i;
	for ( i = docs.begin(); i != docs.end(); i++ ) {
		delete *i;
	}
	docs.clear();
}

- (void)enumerateDocumentsUsingBlock:(void (^)(lucene::document::Document *obj, BOOL *remove))block {
	std::list<Document *>::iterator i = docs.begin();
	BOOL remove;
	while ( i != docs.end() ) {
		remove = NO;
		block(*i, &remove);
		if ( remove ) {
			delete *i;
			i = docs.erase(i);
		} else {
			++i;
		}
	}
}

@end
