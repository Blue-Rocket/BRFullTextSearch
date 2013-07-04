//
//  NSDateComponents+BRFullTextSearchAdditions.m
//  BRFullTextSearch
//
//  Created by Matt on 7/4/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "NSDateComponents+BRFullTextSearchAdditions.h"

static const NSCalendarUnit kBRStandardMonthCalendarUnits = (NSYearCalendarUnit|NSMonthCalendarUnit|NSCalendarCalendarUnit|NSTimeZoneCalendarUnit);
static const NSCalendarUnit kBRStandardDayCalendarUnits = (kBRStandardMonthCalendarUnits|NSDayCalendarUnit);

@implementation NSDateComponents (BRFullTextSearchAdditions)

+ (NSCalendar *)localCalendar {
	return (__bridge_transfer NSCalendar *)CFCalendarCopyCurrent();
}

+ (NSDateComponents *)localDayComponentsFromDate:(NSDate *)date {
	return [[self localCalendar] components:kBRStandardDayCalendarUnits fromDate:date];
}

@end
