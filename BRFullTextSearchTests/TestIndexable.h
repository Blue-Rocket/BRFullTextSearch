//
//  TestIndexable.h
//  BRFullTextSearch
//
//  Created by Matt on 11/28/13.
//  Copyright (c) 2013 Blue Rocket. All rights reserved.
//

#import "BRSimpleIndexable.h"

extern NSString * const kBRTestIndexableSearchFieldNameTags;

@interface TestIndexable : BRSimpleIndexable

@property (nonatomic, strong) NSArray *tags;

@end
