//
//  BRSimpleSortDescriptorTests.m
//  BRFullTextSearch
//
//  Created by Matt on 25/02/16.
//  Copyright © 2016 Blue Rocket. All rights reserved.
//

#import "BRTestSupport.h"

#import "BRSearchFields.h"
#import "BRSimpleSortDescriptor.h"

@interface BRSimpleSortDescriptorTests : BRTestSupport

@end

@implementation BRSimpleSortDescriptorTests

- (void)testDefaultInit {
	BRSimpleSortDescriptor *d = [[BRSimpleSortDescriptor alloc] init];
	
	XCTAssertEqualObjects(d.sortFieldName, kBRSearchFieldNameTimestamp, @"default sort by timestamp");
	XCTAssertEqual(d.sortType, BRSearchSortTypeString, @"default sort type");
	XCTAssertFalse(d.ascending, @"default descending order");
}

- (void)testDesignatedInit {
	BRSimpleSortDescriptor *d = [[BRSimpleSortDescriptor alloc] initWithFieldName:@"f" type:BRSearchSortTypeInteger ascending:YES];
	XCTAssertEqualObjects(d.sortFieldName, @"f", @"sort field");
	XCTAssertEqual(d.sortType, BRSearchSortTypeInteger, @"sort type");
	XCTAssertTrue(d.ascending, @"order");
}


@end
