//
//  NSDate+BRFullTextSearchAdditions.h
//  BRFullTextSearch
//
//  Created by Matt on 7/4/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

/**
 * Utility methods on dates useful for search indexes.
 */
@interface NSDate (BRFullTextSearchAdditions)

/**
 * Convert the receiver into a date-formatted string value.
 *
 * The format pattern is `yyyyMMddHHmmss` and is in the GMT time zone.
 *
 * @return the receiver formatted as an "index timestamp"
 */
- (NSString *)asIndexTimestampString;

/**
 * Convert an "index timestamp" string into a date.
 *
 * @param string an index timestamp string, as returned by asIndexTimestampString
 */
+ (NSDate *)dateWithIndexTimestampString:(NSString *)string;

@end
