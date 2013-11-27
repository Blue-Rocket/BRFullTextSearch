//
//  BRSimpleIndexable.m
//  BRFullTextSearch
//
//  Created by Matt on 7/5/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRSimpleIndexable.h"

#import "NSDate+BRFullTextSearchAdditions.h"

const BRSearchObjectType kBRSimpleIndexableSearchObjectType = '?';

@implementation BRSimpleIndexable {
	NSString *identifier;
	NSDictionary *data;
	BRSearchObjectType objectType;
}

- (id)init {
	return [self initWithIdentifier:nil data:nil];
}

- (id)initWithIdentifier:(NSString *)theIdentifier data:(NSDictionary *)theData {
	return [self initWithType:kBRSimpleIndexableSearchObjectType identifier:theIdentifier data:theData];
}

- (id)initWithType:(BRSearchObjectType)type identifier:(NSString *)theIdentifier data:(NSDictionary *)theData {
	if ( (self = [super init]) ) {
		identifier = theIdentifier;
		data = theData;
		if ( [data objectForKey:kBRSearchFieldNameTimestamp] == nil ) {
			self.date = [NSDate new];
		}
		objectType = type;
	}
	return self;
}

- (BRSearchObjectType)indexObjectType {
	return objectType;
}

- (NSString *)indexIdentifier {
	return identifier;
}

- (NSDictionary *)indexFieldsDictionary {
	return data;
}

- (BRIndexableIndexType)indexFieldIndexType:(NSString *)fieldName {
	if ( [fieldName isEqualToString:kBRSearchFieldNameTimestamp] ) {
		return BRIndexableIndexTypeUntokenized;
	}
	return BRIndexableIndexTypeTokenized;
}

#pragma mark - Field alias support

- (void)setDataObject:(id)object forKey:(NSString *)key {
	if ( object == nil ) {
		if ( [data objectForKey:key] != nil ) {
			NSMutableDictionary *mutable = [data mutableCopy];
			[mutable removeObjectForKey:key];
			data = [mutable copy];
		}
	} else {
		// don't just call mutableCopy, as data might be nil here
		NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:([data count] + 1)];
		[d addEntriesFromDictionary:data];
		[d setObject:object forKey:key];
		data = [d copy];
	}
}

- (NSDate *)date {
	return [NSDate dateWithIndexTimestampString:[data objectForKey:kBRSearchFieldNameTimestamp]];
}

- (void)setDate:(NSDate *)date {
	[self setDataObject:[date asIndexTimestampString] forKey:kBRSearchFieldNameTimestamp];
}

- (NSString *)title {
	return [data objectForKey:kBRSearchFieldNameTitle];
}

- (void)setTitle:(NSString *)title {
	[self setDataObject:title forKey:kBRSearchFieldNameTitle];
}

- (NSString *)value {
	return [data objectForKey:kBRSearchFieldNameValue];
}

- (void)setValue:(NSString *)value {
	[self setDataObject:value forKey:kBRSearchFieldNameValue];
}

- (NSString *)uid {
	return identifier;
}

@end
