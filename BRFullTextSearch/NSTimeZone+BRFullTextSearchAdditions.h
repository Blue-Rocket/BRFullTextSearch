//
//  NSTimeZone+BRFullTextSearchAdditions.h
//  BRFullTextSearch
//
//  Created by Matt on 7/4/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

/**
 * Utility methods on time zones useful for search indexes.
 */
@interface NSTimeZone (BRFullTextSearchAdditions)

/**
 * Get the GMT time zone.
 *
 * @return the GMT time zone
 */
+ (NSTimeZone *)GMTTimeZone;

@end
