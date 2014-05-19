//
//  NSDateComponents+BRFullTextSearchAdditions.h
//  BRFullTextSearch
//
//  Created by Matt on 7/4/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

/**
 * Utility methods for date components useful for search indexes.
 */
@interface NSDateComponents (BRFullTextSearchAdditions)

/**
 * Get a local calendar instance.
 *
 * This method could be relatively slow to execute.
 *
 * @return a new calendar instance, based on the current runtime calendar
 */
+ (NSCalendar *)localCalendar;

/**
 * Get the year, month, and day components for a date.
 *
 * The `NSCalendar` and `NSTimeZone` components will be included in the result.
 *
 * @param date the date to turn into components
 * @return the components, based on the current local calendar
 */
+ (NSDateComponents *)localDayComponentsFromDate:(NSDate *)date;

@end
