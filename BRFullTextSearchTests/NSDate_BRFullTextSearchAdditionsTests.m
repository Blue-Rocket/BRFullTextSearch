//
//  NSDate_BRFullTextSearchAdditionsTests.m
//  BRFullTextSearch
//
//  Created by Matt on 9/12/13.
//  Copyright (c) 2013 Blue Rocket. All rights reserved.
//

#import "NSDate_BRFullTextSearchAdditionsTests.h"

#import "NSDate+BRFullTextSearchAdditions.h"

@implementation NSDate_BRFullTextSearchAdditionsTests

- (NSTimeZone *)GMT {
	return [NSTimeZone timeZoneWithName:@"GMT"];
}

- (NSCalendar *)GMTCalendar {
	NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	[cal setTimeZone:[self GMT]];
	return cal;
}

- (NSDateComponents *)componentsForYear:(int)year month:(int)month day:(int)day
								   hour:(int)hour minute:(int)minute second:(int)second {
	NSDateComponents *comp = [[NSDateComponents alloc] init];
	[comp setYear:year];
	[comp setMonth:month];
	[comp setDay:day];
	[comp setHour:hour];
	[comp setMinute:minute];
	[comp setSecond:second];
	return comp;
}

- (void)testEncodeDate {
	NSDateComponents *comp = [self componentsForYear:2013 month:9 day:12 hour:13 minute:5 second:0];
	NSDate *date = [[self GMTCalendar] dateFromComponents:comp];
	NSString *result = [date asIndexTimestampString];
	STAssertEqualObjects(result, @"20130912130500", @"date string");
}

- (void)testDecodeDate {
	NSDate *result = [NSDate dateWithIndexTimestampString:@"20130912130500"];
	NSDateComponents *comp = [[self GMTCalendar] components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
															 |NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit) fromDate:result];
	STAssertEquals([comp year], (NSInteger)2013, @"year");
	STAssertEquals([comp month], (NSInteger)9, @"year");
	STAssertEquals([comp day], (NSInteger)12, @"year");
	STAssertEquals([comp hour], (NSInteger)13, @"year");
	STAssertEquals([comp minute], (NSInteger)5, @"year");
	STAssertEquals([comp second], (NSInteger)0, @"year");
}

@end
