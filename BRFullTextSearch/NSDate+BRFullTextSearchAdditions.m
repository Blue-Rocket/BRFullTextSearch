//
//  NSDate+BRFullTextSearchAdditions.m
//  BRFullTextSearch
//
//  Created by Matt on 7/4/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "NSDate+BRFullTextSearchAdditions.h"

#import "NSTimeZone+BRFullTextSearchAdditions.h"

@implementation NSDate (BRFullTextSearchAdditions)

+ (NSDateFormatter *)indexTimestampDateFormatter {
	static NSDateFormatter *formatter;
	if ( formatter == nil ) {
		formatter = [NSDateFormatter new];
		NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		[formatter setLocale:enUSPOSIXLocale];
		[formatter setTimeZone:[NSTimeZone GMTTimeZone]];
		[formatter setCalendar:[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]];
		[formatter setDateFormat:@"yyyyMMddHHmmss"];
	}
	return formatter;
}

+ (NSDate *)dateWithIndexTimestampString:(NSString *)string {
	return [[self indexTimestampDateFormatter] dateFromString:string];
}

- (NSString *)asIndexTimestampString {
	return [[NSDate indexTimestampDateFormatter] stringFromDate:self];
}

@end
