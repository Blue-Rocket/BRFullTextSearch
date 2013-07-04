//
//  BRSimpleIndexable.h
//  BRFullTextSearch
//
//  A simple, dictionary-based implementation of BRIndexable.
//
//  Created by Matt on 7/5/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRIndexable.h"

extern const BRSearchObjectType kBRSimpleIndexableSearchObjectType;

@interface BRSimpleIndexable : NSObject <BRIndexable>

// data aliases: setting these values modifies the data dictionary returned by indexFieldsDictionary
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *value;
@property (nonatomic, retain) NSDate *date;

// propery alias for identifier
@property (nonatomic, readonly) NSString *uid;

// init with kBRSimpleIndexableSearchObjectType and given identifier and data
- (id)initWithIdentifier:(NSString *)identifier data:(NSDictionary *)data;

// init with given attributes; a kBRSearchFieldNameTimestamp value is populated automatically
- (id)initWithType:(BRSearchObjectType)type identifier:(NSString *)identifier data:(NSDictionary *)data;

@end
