//
//  BRSearchResult.h
//  BRFullTextSearch
//
//  Created by Matt on 6/5/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "BRSearchFields.h"

@protocol BRSearchResult <NSObject>

@property (nonatomic, readonly) BRSearchObjectType objectType;

// some unique identifier (unique to objectType) for the result
@property (nonatomic, readonly) NSString *identifier;

// get the value of a field
- (id)valueForField:(NSString *)fieldName;

// get a date components, in local time, for a given timestamp field
- (NSDateComponents *)localDayForTimestampField:(NSString *)fieldName;

// get the values for all fields (including the identifier and object type) as a dictionary;
// if a field contains more than one value the values will be stored as an array in the returned dictionary
- (NSDictionary *)dictionaryRepresentation;

@end
