//
//  StickyNote.m
//  SampleCoreDataProject
//
//  Created by Matt on 8/26/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#import "StickyNote.h"

#import <BRFullTextSearch/BRFullTextSearch.h>
#import <BRFullTextSearch/NSDate+BRFullTextSearchAdditions.h>

const BRSearchObjectType kStickyNoteSearchObjectType = 'n';

@implementation StickyNote

@dynamic created;
@dynamic text;

+ (NSDate *)createdDateForCurrentSystemTime {
	NSCalendar *cal = [NSCalendar currentCalendar];
	NSDateComponents *timestamp = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit)
										 fromDate:[NSDate new]];
	return [cal dateFromComponents:timestamp];
}

#pragma mark - Indexable

- (BRSearchObjectType)indexObjectType {
	return kStickyNoteSearchObjectType;
}

- (NSString *)indexIdentifier {
	return [self.created asIndexTimestampString];
}

- (NSDictionary *)indexFieldsDictionary {
	NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithCapacity:4];
	if ( self.text != nil ) {
		[data setObject:self.text forKey:kBRSearchFieldNameValue];
	}
	[data setObject:[self.created asIndexTimestampString] forKey:kBRSearchFieldNameTimestamp];
	NSLog(@"StickyNote index data: %@", data);
	return data;
}

- (BRIndexableIndexType)indexFieldIndexType:(NSString *)fieldName {
	if ( [kBRSearchFieldNameTimestamp isEqualToString:fieldName] ) {
		return BRIndexableIndexTypeUntokenized;
	}
	return BRIndexableIndexTypeTokenized;
}

@end
