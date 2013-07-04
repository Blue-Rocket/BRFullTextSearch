//
//  NSDateComponents+BRFullTextSearchAdditions.h
//  BRFullTextSearch
//
//  Created by Matt on 7/4/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

@interface NSDateComponents (BRFullTextSearchAdditions)

+ (NSCalendar *)localCalendar;
+ (NSDateComponents *)localDayComponentsFromDate:(NSDate *)date;

@end
