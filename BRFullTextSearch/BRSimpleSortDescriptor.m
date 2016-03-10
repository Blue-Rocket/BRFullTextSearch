//
//  BRSimpleSortDescriptor.m
//  BRFullTextSearch
//
//  Created by Matt on 25/02/16.
//  Copyright © 2016 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRSimpleSortDescriptor.h"

#import "BRSearchFields.h"

@implementation BRSimpleSortDescriptor {
	NSString *sortFieldName;
	BRSearchSortType sortType;
	BOOL ascending;
}

@synthesize sortFieldName;
@synthesize sortType;
@synthesize ascending;

- (instancetype)init {
	return [self initWithFieldName:kBRSearchFieldNameTimestamp type:BRSearchSortTypeString ascending:NO];
}

- (instancetype)initWithFieldName:(NSString *)fieldName type:(BRSearchSortType)type ascending:(BOOL)asc {
	if ( (self = [super init]) ) {
		sortFieldName = fieldName;
		sortType = type;
		ascending = asc;
	}
	return self;
}

@end
