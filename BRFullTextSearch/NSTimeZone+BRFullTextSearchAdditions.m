//
//  NSTimeZone+BRFullTextSearchAdditions.m
//  BRFullTextSearch
//
//  Created by Matt on 7/4/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "NSTimeZone+BRFullTextSearchAdditions.h"

@implementation NSTimeZone (BRFullTextSearchAdditions)

+ (NSTimeZone *)GMTTimeZone {
	return [NSTimeZone timeZoneWithName:@"GMT"];
}

@end
