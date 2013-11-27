//
//  TestIndexable.h
//  BRFullTextSearch
//
//  Created by Matt on 11/28/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRSimpleIndexable.h"

extern NSString * const kBRTestIndexableSearchFieldNameTags;

@interface TestIndexable : BRSimpleIndexable

@property (nonatomic, strong) NSArray *tags;

@end
