//
//  CLuceneSearchResult.m
//  BRFullTextSearch
//
//  Created by Matt on 7/1/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "CLuceneSearchResult.h"

#import "CLucene/_ApiHeader.h"
#import "NSDate+BRFullTextSearchAdditions.h"
#import "NSDateComponents+BRFullTextSearchAdditions.h"
#import "NSString+CLuceneAdditions.h"

using namespace lucene::document;
using namespace lucene::search;

@implementation CLuceneSearchResult {
	Hits *hits;
	std::auto_ptr<Hits> ownedHits;
	int32_t index;
	BRSearchObjectType objectType;
}

+ (Class)searchResultClassForObjectTypeField:(const TCHAR *)objectTypeValue {
	/*TODO: hook for result type class */
	Class srClass = [CLuceneSearchResult class];
	return srClass;
}

+ (Class)searchResultClassForDocument:(Document &)doc {
	return [self searchResultClassForObjectTypeField:doc.get([kBRSearchFieldNameObjectType asCLuceneString])];
}

- (id)init {
	return [self initWithHits:NULL index:0];
}

- (id)initWithHits:(lucene::search::Hits *)theHits index:(const int32_t)docIndex {
	if ( (self = [super init]) ) {
		hits = theHits;
		index = docIndex;
	}
	return self;
}

- (id)initWithOwnedHits:(std::auto_ptr<lucene::search::Hits>)theHits index:(const int32_t)docIndex {
	if ( (self = [super init]) ) {
		ownedHits = theHits;
		hits = ownedHits.get();
		index = docIndex;
	}
	return self;
}

- (BRSearchObjectType)objectType {
	if ( objectType < 1 ) {
		NSString *ident = [self valueForField:kBRSearchFieldNameIdentifier];
		if ( [ident length] > 0 ) {
			objectType = BRSearchObjectTypeForString([ident substringToIndex:1]);
		}
	}
	return objectType;
}

- (NSString *)identifier {
	NSString *ident = [self valueForField:kBRSearchFieldNameIdentifier];
	if ( [ident length] > 1 ) {
		return [ident substringFromIndex:1];
	}
	return nil;
}

- (id)valueForField:(NSString *)fieldName {
	const Document &doc = hits->doc(index);
	const Document::FieldsType *fields = doc.getFields();
	const TCHAR *name = [fieldName asCLuceneString];
	Document::FieldsType::const_iterator itr;
	id result = nil;
	NSMutableArray *array = nil;
	for ( itr = fields->begin(); itr != fields->end(); itr++ ){
		Field *f = *itr;
		if ( _tcscmp(f->name(), name) == 0 && f->stringValue() != NULL ) {
			if ( result == nil ) {
				// put first match into result to start
				result = [NSString stringWithCLuceneString:f->stringValue()];
			} else  {
				// multi-value result... stash in array
				if ( array == nil ) {
					array = [NSMutableArray arrayWithCapacity:4];
					[array addObject:result];
					result = array;
				}
				[array addObject:[NSString stringWithCLuceneString:f->stringValue()]];
			}
		}
	}
	return result;
}

- (NSDateComponents *)localDayForTimestampField:(NSString *)fieldName {
	NSString *secondsKey = [self valueForField:fieldName];
	NSDate *d = [NSDate dateWithIndexTimestampString:secondsKey];
	return [NSDateComponents localDayComponentsFromDate:d];
}

- (NSDictionary *)dictionaryRepresentation {
	NSMutableDictionary *dict = [NSMutableDictionary new];
	const Document &doc = hits->doc(index);
	const Document::FieldsType *fields = doc.getFields();
	Document::FieldsType::const_iterator itr;
	for ( itr = fields->begin(); itr != fields->end(); itr++ ){
		Field *f = *itr;
		NSString *fName = [NSString stringWithCLuceneString:f->name()];
		NSString *fValue = [NSString stringWithCLuceneString:f->stringValue()];
		if ( fValue == nil ) {
			// could be from garbage string :-(
			continue;
		}
		id existing = [dict objectForKey:fName];
		if ( existing == nil ) {
			[dict setObject:fValue forKey:fName];
		} else if ( [existing isKindOfClass:[NSMutableArray class]] ) {
			// add to existing multi-value array
			[existing addObject:fValue];
		} else {
			// turn into a multi-value array
			NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:2];
			[array addObject:existing];
			[array addObject:fValue];
			[dict setObject:array forKey:fName];
		}
	}
	return dict;
}

@end
