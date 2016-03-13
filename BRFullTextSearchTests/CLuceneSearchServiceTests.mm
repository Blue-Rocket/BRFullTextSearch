//
//  CLuceneSearchServiceTests.mm
//  BRFullTextSearch
//
//  Created by Matt on 7/5/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "CLuceneSearchServiceTests.h"

#import <memory>
#import "BRSimpleIndexable.h"
#import "BRSimpleSortDescriptor.h"
#import "CLuceneSearchResult.h"
#import "CLuceneSearchResults.h"
#import "CLuceneSearchService+Subclassing.h"
#import "NSDate+BRFullTextSearchAdditions.h"
#import "TestIndexable.h"

#import "CLucene/analysis/Analyzers.h"

@implementation CLuceneSearchServiceTests {
	CLuceneSearchService *searchService;
	NSString *indexPath;
}

- (void)setUp {
	[super setUp];
	NSString *tmpIndexDir = [BRTestSupport temporaryPathWithPrefix:@"notes" suffix:nil directory:YES];
	[[NSFileManager defaultManager] createDirectoryAtPath:tmpIndexDir withIntermediateDirectories:YES attributes:nil error:nil];
	searchService = [[CLuceneSearchService alloc] initWithIndexPath:tmpIndexDir];
	searchService.bundle = self.bundle;
	searchService.defaultAnalyzerLanguage = @"en";
	indexPath = tmpIndexDir;
	
	// make sure this always starts at 0
	[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:[searchService userDefaultsIndexUpdateCountKey]];
}

- (BRSimpleIndexable *)createTestIndexableInstance {
	return [[BRSimpleIndexable alloc] initWithIdentifier:[BRTestSupport UUID] data:@{
								kBRSearchFieldNameTitle : @"My special note",
								kBRSearchFieldNameValue : @"This is a long winded note with really important details in it."
			}];
}

#pragma mark - Basic search

- (void)testIndexMultipleBRSimpleIndexablesAndSearchForResults {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.date = [n0.date dateByAddingTimeInterval:-4]; // offset dates to test sorting
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = [[NSDate new] dateByAddingTimeInterval:-2];
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = [NSDate new];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2] error:nil];
	
	NSString *n0Id = n0.uid;
	NSString *n1Id = n1.uid;
	NSString *n2Id = n2.uid;
	
	// first test individual results
	id<BRSearchResults> results0 = [searchService search:@"special"];
	XCTAssertEqual([results0 count], (NSUInteger)1, @"results count");
	__block NSUInteger count = 0;
	[results0 iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertEqualObjects([result identifier], n0Id, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
	
	id<BRSearchResults> results1 = [searchService search:@"fancy"];
	XCTAssertEqual([results1 count], (NSUInteger)1, @"results count");
	count = 0;
	[results1 iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertEqualObjects([result identifier], n1Id, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
	
	id<BRSearchResults> results2 = [searchService search:@"pretty"];
	XCTAssertEqual([results2 count], (NSUInteger)1, @"results count");
	count = 0;
	[results2 iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertEqualObjects([result identifier], n2Id, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
}

- (void)testOptimizeIndexFromUpdateThreshold {
	const NSInteger threshold = 4;
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	searchService.indexUpdateOptimizeThreshold = threshold;
	
	for ( NSInteger i = 0; i < threshold; i++ ) {
		n0.title = [NSString stringWithFormat:@"Special note%ld", (long)i];
		[searchService addObjectsToIndexAndWait:@[n0] error:nil];
	}
	
	// at this point, we should have mutliple segment files, and updated count
	NSInteger updateCount = [[NSUserDefaults standardUserDefaults] integerForKey:[searchService userDefaultsIndexUpdateCountKey]];
	XCTAssertEqual(updateCount, threshold, @"update count");
	
	n0.title = [NSString stringWithFormat:@"Special note%ld", (long)threshold];
	[searchService addObjectsToIndexAndWait:@[n0] error:nil];
	
	updateCount = [[NSUserDefaults standardUserDefaults] integerForKey:[searchService userDefaultsIndexUpdateCountKey]];
	XCTAssertEqual(updateCount, (NSInteger)0, @"update count");
}

- (void)testGetResultsByIndex {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.date = [n0.date dateByAddingTimeInterval:-4]; // offset dates to test sorting
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = [[NSDate new] dateByAddingTimeInterval:-2];
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = [NSDate new];
	
	NSError *error = nil;
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2] error:&error];
	XCTAssertNil(error, @"Update: %@", [error localizedDescription]);
	
	NSString *n0Id = n0.uid;
	NSString *n1Id = n1.uid;
	NSString *n2Id = n2.uid;
	
	// now search with a sort...
	id<BRSearchResults> sorted = [searchService search:@"note" sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	XCTAssertEqual([sorted count], (NSUInteger)3, @"sorted count");
	XCTAssertEqualObjects([sorted resultAtIndex:0].identifier, n0Id, @"object by index");
	XCTAssertEqualObjects([sorted resultAtIndex:1].identifier, n1Id, @"object by index");
	XCTAssertEqualObjects([sorted resultAtIndex:2].identifier, n2Id, @"object by index");
}

- (void)testSearchBRSimpleIndexableByIdentifier {
	BRSimpleIndexable *n = [self createTestIndexableInstance];
	[searchService addObjectToIndexAndWait:n error:nil];
	NSString *nIdentifier = n.uid;
	
	id<BRSearchResult> result = [searchService findObject:'?' withIdentifier:nIdentifier];
	XCTAssertNotNil(result, @"search result");
	XCTAssertTrue([result isKindOfClass:[CLuceneSearchResult class]], @"Results must be CLuceneSearchResult");
	XCTAssertEqualObjects([result identifier], nIdentifier, @"object ID");
}

- (void)testSearchResultDictionaryRepresentation {
	BRSimpleIndexable *n = [self createTestIndexableInstance];
	[searchService addObjectToIndexAndWait:n error:nil];
	NSString *nIdentifier = n.uid;
	
	id<BRSearchResult> result = [searchService findObject:'?' withIdentifier:nIdentifier];
	NSDictionary *data = [result dictionaryRepresentation];
	XCTAssertNotNil(data, @"dictionary result");
	NSString *expectedIdentifier = [NSString stringWithFormat:@"%c%@", '?', nIdentifier];
	XCTAssertEqualObjects(data[kBRSearchFieldNameIdentifier], expectedIdentifier, @"object ID");
	XCTAssertEqualObjects(data[kBRSearchFieldNameTitle], n.title, @"title");
	XCTAssertEqualObjects(data[kBRSearchFieldNameValue], n.value, @"value");
	XCTAssertNotNil(data[kBRSearchFieldNameTimestamp], @"timestamp");
}

- (void)testSearchBRSimpleIndexableByFreeText {
	BRSimpleIndexable *n = [self createTestIndexableInstance];
	[searchService addObjectToIndexAndWait:n error:nil];
	NSString *nID = n.uid;
	
	id<BRSearchResults> results = [searchService search:@"special"];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	XCTAssertTrue([results isKindOfClass:[CLuceneSearchResults class]], @"Results must be CLuceneSearchResults");
	__block NSUInteger count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertTrue([result isKindOfClass:[CLuceneSearchResult class]], @"Results must be CLuceneSearchResult");
		XCTAssertEqualObjects([result identifier], nID, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
}

- (void)testSearchBRSimpleIndexableByFreeTextCaseInsensitive {
	BRSimpleIndexable *n = [self createTestIndexableInstance];
	[searchService addObjectToIndexAndWait:n error:nil];
	NSString *nID = n.uid;
	
	id<BRSearchResults> results = [searchService search:@"SPECIAL"];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	XCTAssertTrue([results isKindOfClass:[CLuceneSearchResults class]], @"Results must be LuceneSearchResults");
	__block NSUInteger count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertTrue([result isKindOfClass:[CLuceneSearchResult class]], @"Results must be CLuceneSearchResult");
		XCTAssertEqualObjects([result identifier], nID, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
}

- (void)testSearchBRSimpleIndexableByFreeTextStemmed {
	BRSimpleIndexable *n = [self createTestIndexableInstance];
	n.title = @"My special note with a flower in it.";
	[searchService addObjectToIndexAndWait:n error:nil];
	NSString *nID = n.uid;
	
	// search where the query term is singular, but the index term was plural ("details")
	id<BRSearchResults> results = [searchService search:@"detail"];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	__block NSUInteger count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertEqualObjects([result identifier], nID, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
	
	// search where the query term is plural, but the index term was singular ("flower")
	results = [searchService search:@"flowers"];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertEqualObjects([result identifier], nID, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
}

- (void)testSearchBRSimpleIndexableByFreeTextStopWords {
	BRSimpleIndexable *n = [self createTestIndexableInstance];
	[searchService addObjectToIndexAndWait:n error:nil];
	NSString *nID = n.uid;
	
	// first confirm normal non-stop word search works as expected
	id<BRSearchResults> results = [searchService search:@"special"];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	__block NSUInteger count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertEqualObjects([result identifier], nID, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
	
	// now search for stop words that were present in the note title, we should have no results
	results = [searchService search:@"is a in it"];
	XCTAssertEqual([results count], (NSUInteger)0, @"results count");
}

- (void)testIndexAndViewArrayField {
	BRSimpleIndexable *n = [self createTestIndexableInstance];
	NSArray *array = @[@"1", @"2", @"3"];
	[n setDataObject:array forKey:@"array"];
	[searchService addObjectToIndexAndWait:n error:nil];
	
	id<BRSearchResult> result = [searchService findObject:kBRSimpleIndexableSearchObjectType withIdentifier:n.uid];
	XCTAssertNotNil(result);
	NSDictionary *data = [result dictionaryRepresentation];
	id obj = data[@"array"];
	XCTAssertTrue([obj isKindOfClass:[NSArray class]], @"array field should be returned as an array");
	XCTAssertEqualObjects(obj, array);
	
	obj = [result valueForField:@"array"];
	XCTAssertTrue([obj isKindOfClass:[NSArray class]], @"array field should be returned as an array");
	XCTAssertEqualObjects(obj, array);
}

#pragma mark - Sorted results

- (void)testSortedResultsAscending {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.date = [n0.date dateByAddingTimeInterval:-4]; // offset dates to test sorting
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = [[NSDate new] dateByAddingTimeInterval:-2];
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = [NSDate new];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2] error:nil];
	
	NSString *n0Id = n0.uid;
	NSString *n1Id = n1.uid;
	NSString *n2Id = n2.uid;
	
	// now search with a sort...
	id<BRSearchResults> sorted = [searchService search:@"note" sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	XCTAssertEqual([sorted count], (NSUInteger)3, @"sorted count");
	__block NSUInteger count = 0;
	__block NSString *lastTimestamp = nil;
	NSMutableSet *seen = [NSMutableSet new];
	[sorted iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		NSString *ts = [result valueForField:kBRSearchFieldNameTimestamp];
		if ( lastTimestamp != nil ) {
			XCTAssertTrue([ts compare:lastTimestamp] == NSOrderedDescending, @"sorted ascending");
		}
		lastTimestamp = ts;
		[seen addObject:[result identifier]];
	}];
	XCTAssertEqual(count, (NSUInteger)3, @"results iterated");
	XCTAssertTrue([seen containsObject:n0Id], @"uid");
	XCTAssertTrue([seen containsObject:n1Id], @"uid");
	XCTAssertTrue([seen containsObject:n2Id], @"uid");
}

- (void)testSortedResultsDescending {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.date = [n0.date dateByAddingTimeInterval:-4]; // offset dates to test sorting
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = [[NSDate new] dateByAddingTimeInterval:-2];
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = [NSDate new];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2] error:nil];
	
	NSString *n0Id = n0.uid;
	NSString *n1Id = n1.uid;
	NSString *n2Id = n2.uid;
	
	// reverse sort
	id<BRSearchResults> sorted = [searchService search:@"note" sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:NO];
	XCTAssertEqual([sorted count], (NSUInteger)3, @"sorted count");
	__block NSUInteger count = 0;
	__block NSString *lastTimestamp = nil;
	NSMutableSet *seen = [NSMutableSet new];
	[sorted iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		NSString *ts = [result valueForField:kBRSearchFieldNameTimestamp];
		if ( lastTimestamp != nil ) {
			XCTAssertTrue([ts compare:lastTimestamp] == NSOrderedAscending, @"sorted descending");
		}
		lastTimestamp = ts;
		[seen addObject:[result identifier]];
	}];
	XCTAssertEqual(count, (NSUInteger)3, @"results iterated");
	XCTAssertTrue([seen containsObject:n0Id], @"uid");
	XCTAssertTrue([seen containsObject:n1Id], @"uid");
	XCTAssertTrue([seen containsObject:n2Id], @"uid");
}

// test that if all docs have the same sort key, they are returned in document order
- (void)testSortedSearchResultsUseDocumentOrder {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = n0.date;
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = n0.date;
	
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2] error:nil];
	
	NSString *n0Id = n0.uid;
	NSString *n1Id = n1.uid;
	NSString *n2Id = n2.uid;
	
	// now search with a ascending sort...
	id<BRSearchResults> sorted = [searchService search:@"note" sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	XCTAssertEqual([sorted count], (NSUInteger)3, @"sorted count");
	__block NSUInteger count = 0;
	[sorted iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		switch ( count ) {
			case 0:
				XCTAssertEqualObjects(result.identifier, n0Id);
				break;
				
			case 1:
				XCTAssertEqualObjects(result.identifier, n1Id);
				break;
				
			case 2:
				XCTAssertEqualObjects(result.identifier, n2Id);
				break;
				
			default:
				// shouldn't get here
				break;
				
		}
		count++;
	}];
	XCTAssertEqual(count, (NSUInteger)3, @"results iterated");
	
	// reverse sort
	sorted = [searchService search:@"note" sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:NO];
	XCTAssertEqual([sorted count], (NSUInteger)3, @"sorted count");
	count = 0;
	[sorted iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		switch ( count ) {
			case 0:
				XCTAssertEqualObjects(result.identifier, n2Id);
				break;
				
			case 1:
				XCTAssertEqualObjects(result.identifier, n1Id);
				break;
				
			case 2:
				XCTAssertEqualObjects(result.identifier, n0Id);
				break;
				
			default:
				// shouldn't get here
				break;
				
		}
		count++;
	}];
	XCTAssertEqual(count, (NSUInteger)3, @"results iterated");
}

- (TestIndexable *)createTestIndexable:(NSString *)identifier {
	NSDictionary *data = @{
						   kBRSearchFieldNameTitle : @"My special note",
						   kBRSearchFieldNameValue : @"This is a long winded note with really important details in it."
						   };
	return [[TestIndexable alloc] initWithIdentifier:identifier data:data];
}

- (void)testSearchResultsMultipleSortDescriptors {
	TestIndexable *n0 = [self createTestIndexable:@"0"];
	n0.date = [n0.date dateByAddingTimeInterval:(60 * 60 * 24 * -1)]; // n0 = yesterday
	n0.tags = @[@"A", @"B"];
	TestIndexable *n1 = [self createTestIndexable:@"1"];
	n1.title = @"My other fancy note.";
	n1.date = [[NSDate new] dateByAddingTimeInterval:-60];            // n1 = 1 min ago
	n1.tags = @[@"B"];
	TestIndexable *n2 = [self createTestIndexable:@"2"];
	n2.title = @"My pretty note.";
	n2.date = [NSDate new];                                           // n2 & n3 = right now
	n2.tags = @[@"C"];
	TestIndexable *n3 = [self createTestIndexable:@"3"];
	n3.title = @"My super note.";
	n3.date = n2.date;
	n3.tags = @[@"D"];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2, n3] error:nil];
	
	NSArray<id<BRSortDescriptor>> *sorts;
	NSArray<NSString *> *expectedResultOrder;
	id<BRSearchResults> sorted;
 
	// we will sort descending by date (get newest first) followed by ascending by tag
	expectedResultOrder = @[n2.uid, n3.uid, n1.uid, n0.uid];

	sorts = @[
			  [[BRSimpleSortDescriptor alloc] initWithFieldName:kBRSearchFieldNameTimestamp type:BRSearchSortTypeString ascending:NO],
			  [[BRSimpleSortDescriptor alloc] initWithFieldName:kBRTestIndexableSearchFieldNameTags type:BRSearchSortTypeString ascending:YES],
			  ];

	sorted = [searchService search:@"note" withSortDescriptors:sorts];
	
	XCTAssertEqual([sorted count], expectedResultOrder.count, @"sorted count");
	__block NSUInteger count = 0;
	[sorted iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		XCTAssertEqual(index, count, @"index matches expected count");
		XCTAssertEqualObjects(result.identifier, expectedResultOrder[count], @"result %lu", (unsigned long)count);
		count++;
	}];
	XCTAssertEqual(count, expectedResultOrder.count, @"results iterated");

	// we will sort ascending by date (get oldest first) followed by descending by tag
	expectedResultOrder = @[n0.uid, n1.uid, n3.uid, n2.uid];
	
	sorts = @[
			  [[BRSimpleSortDescriptor alloc] initWithFieldName:kBRSearchFieldNameTimestamp type:BRSearchSortTypeString ascending:YES],
			  [[BRSimpleSortDescriptor alloc] initWithFieldName:kBRTestIndexableSearchFieldNameTags type:BRSearchSortTypeString ascending:NO],
			  ];

	sorted = [searchService search:@"note" withSortDescriptors:sorts];
	
	XCTAssertEqual([sorted count], expectedResultOrder.count, @"sorted count");
	count = 0;
	[sorted iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		XCTAssertEqual(index, count, @"index matches expected count");
		XCTAssertEqualObjects(result.identifier, expectedResultOrder[count], @"result %lu", (unsigned long)count);
		count++;
	}];
	XCTAssertEqual(count, expectedResultOrder.count, @"results iterated");
}

- (void)testSearchResultsGroupedByDay {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.date = [n0.date dateByAddingTimeInterval:(60 * 60 * 24 * -1)]; // offset dates to test grouping
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = [[NSDate new] dateByAddingTimeInterval:-2];
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = [NSDate new];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2] error:nil];
	
	NSString *n0Id = n0.uid;
	NSString *n1Id = n1.uid;
	NSString *n2Id = n2.uid;
	
	// now search with a sort...
	id<BRSearchResults> sorted = [searchService search:@"note" sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	NSArray *groups = [sorted resultsGroupedByDay:kBRSearchFieldNameTimestamp];
	XCTAssertEqual([groups count], (NSUInteger)2, @"group count");
	NSArray *group0 = [groups objectAtIndex:0];
	NSArray *group1 = [groups objectAtIndex:1];
	XCTAssertEqual([group0 count], (NSUInteger)1, @"group 0 count");
	XCTAssertEqual([group1 count], (NSUInteger)2, @"group 1 count");
	XCTAssertEqualObjects([[group0 objectAtIndex:0] identifier], n0Id, @"object by index");
	XCTAssertEqualObjects([[group1 objectAtIndex:0] identifier], n1Id, @"object by index");
	XCTAssertEqualObjects([[group1 objectAtIndex:1] identifier], n2Id, @"object by index");
}

#pragma mark - Index updating

- (void)testIndexNothing {
	// test that API doesn't freak out from empty input
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
	[searchService addObjectToIndexAndWait:nil error:nil];
	[searchService addObjectToIndex:nil queue:NULL finished:NULL];
	[searchService addObjectsToIndexAndWait:nil error:nil];
	[searchService addObjectsToIndexAndWait:[NSArray new] error:nil];
	[searchService addObjectsToIndex:nil queue:NULL finished:NULL];
	[searchService addObjectsToIndex:[NSArray new] queue:NULL finished:NULL];
#pragma clang diagnostic pop
}

- (void)testUpdateDocument {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.date = [n0.date dateByAddingTimeInterval:-4];
	[searchService addObjectsToIndexAndWait:@[n0] error:nil];
	
	NSString *n0Id = n0.uid;
	
	// first test for two results
	id<BRSearchResults> results = [searchService search:@"special"];
	XCTAssertEqual([results count], (NSUInteger)1, @"count");
	__block NSUInteger count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		switch ( count ) {
			case 0:
				XCTAssertEqualObjects([result identifier], n0Id, @"uid");
				break;
		}
		count++;
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
	
	// now update note, to change terms...
	n0.title = @"My pretty note";
	[searchService addObjectsToIndexAndWait:@[n0] error:nil];
	[searchService resetSearcher]; // must reset to pick up changes immediately after first search
	
	// search for old keyword... should NOT find anymore
	results = [searchService search:@"special"];
	XCTAssertEqual([results count], (NSUInteger)0, @"count");
	
	
	// now search for new keywork, and SHOULD find
	results = [searchService search:@"pretty"];
	XCTAssertEqual([results count], (NSUInteger)1, @"count");
	count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		switch ( count ) {
			case 0:
				XCTAssertEqualObjects([result identifier], n0Id, @"uid");
				break;
		}
		count++;
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
}

- (void)testAddTwiceToIndexAndSearchForResults {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.date = [n0.date dateByAddingTimeInterval:-4]; // offset dates to test sorting
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = [[NSDate new] dateByAddingTimeInterval:-2];
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = [NSDate new];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1] error:nil];
	
	NSString *n0Id = n0.uid;
	NSString *n1Id = n1.uid;
	NSString *n2Id = n2.uid;
	
	// first test for two results
	id<BRSearchResults> results = [searchService search:@"note"];
	XCTAssertEqual([results count], (NSUInteger)2, @"result count");
	NSMutableSet *seen = [NSMutableSet new];
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		[seen addObject:[result identifier]];
	}];
	XCTAssertEqual([seen count], (NSUInteger)2, @"results iterated");
	XCTAssertTrue([seen containsObject:n0Id], @"uid");
	XCTAssertTrue([seen containsObject:n1Id], @"uid");
	
	// now add to index, and search again
	[searchService addObjectsToIndexAndWait:@[n2] error:nil];
	[searchService resetSearcher];
	
	results = [searchService search:@"note"];
	XCTAssertEqual([results count], (NSUInteger)3, @"result count");
	[seen removeAllObjects];
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		[seen addObject:[result identifier]];
	}];
	XCTAssertEqual([seen count], (NSUInteger)3, @"results iterated");
	XCTAssertTrue([seen containsObject:n0Id], @"uid");
	XCTAssertTrue([seen containsObject:n1Id], @"uid");
	XCTAssertTrue([seen containsObject:n2Id], @"uid");
}

- (void)testBulkAddToIndex {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = n0.date;
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = n0.date;
	
	NSArray *notes = @[n0, n1, n2];
	BOOL updateResult = [searchService bulkUpdateIndexAndWait:^(id<BRIndexUpdateContext>updateContext) {
		for ( BRSimpleIndexable *n in notes ) {
			[searchService addObjectToIndex:n context:updateContext];
		}
	} error:nil];
	XCTAssertTrue(updateResult, @"Update result");
	
	id<BRSearchResult> result = [searchService findObject:'?' withIdentifier:[n0 indexIdentifier]];
	XCTAssertEqualObjects([result identifier], [n0 uid], @"object ID");
	result = [searchService findObject:'?' withIdentifier:[n1 indexIdentifier]];
	XCTAssertEqualObjects([result identifier], [n1 uid], @"object ID");
	result = [searchService findObject:'?' withIdentifier:[n2 indexIdentifier]];
	XCTAssertEqualObjects([result identifier], [n2 uid], @"object ID");
}

#pragma mark - Delete

- (void)testDeleteAllDocuments {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = n0.date;
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = n0.date;
	
	NSArray *notes = @[n0, n1, n2];
	BOOL updateResult = [searchService bulkUpdateIndexAndWait:^(id<BRIndexUpdateContext>updateContext) {
		for ( BRSimpleIndexable *n in notes ) {
			[searchService addObjectToIndex:n context:updateContext];
		}
	} error:nil];
	XCTAssertTrue(updateResult, @"Update result");
	
	// verify search returns docs
	id<BRSearchResults> results = [searchService searchWithPredicate:[NSPredicate predicateWithFormat:@"o == %@", @"?"] sortBy:nil sortType:BRSearchSortTypeString ascending:NO];
	XCTAssertEqual([results count], 3U, @"Doc count");
	
	NSError *error = nil;
	__block int deleteCount = 0;
	updateResult = [searchService bulkUpdateIndexAndWait:^(id<BRIndexUpdateContext> updateContext) {
		deleteCount = [searchService removeAllObjectsFromIndex:updateContext];
	} error:&error];
	
	XCTAssertTrue(updateResult, @"Delete result");
	XCTAssertEqual(deleteCount, 3, @"Delete count");
	
	// verify search does not return docs
	results = [searchService searchWithPredicate:[NSPredicate predicateWithFormat:@"o == %@", @"?"] sortBy:nil sortType:BRSearchSortTypeString ascending:NO];
	XCTAssertEqual([results count], 0U, @"Doc count");

}

#pragma mark - Predicate search

- (void)testSearchWithSimplePredicate {
	BRSimpleIndexable *n = [self createTestIndexableInstance];
	[searchService addObjectToIndexAndWait:n error:nil];
	NSString *nID = n.uid;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"t like %@", @"special"];
	
	id<BRSearchResults> results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	XCTAssertTrue([results isKindOfClass:[CLuceneSearchResults class]], @"Results must be CLuceneSearchResults");
	__block NSUInteger count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertTrue([result isKindOfClass:[CLuceneSearchResult class]], @"Results must be LuceneBRSimpleIndexableSearchResult");
		XCTAssertEqualObjects([result identifier], nID, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
}

- (void)testSearchWithEscapedPredicate {
	BRSimpleIndexable *n = [self createTestIndexableInstance];
	[searchService addObjectToIndexAndWait:n error:nil];
	NSString *nID = n.uid;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"t like %@", @"-special"]; // the "-" will be escaped and then parsed out of term
	
	id<BRSearchResults> results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	XCTAssertTrue([results isKindOfClass:[CLuceneSearchResults class]], @"Results must be CLuceneSearchResults");
	__block NSUInteger count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertTrue([result isKindOfClass:[CLuceneSearchResult class]], @"Results must be LuceneBRSimpleIndexableSearchResult");
		XCTAssertEqualObjects([result identifier], nID, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
}

- (void)testSearchWithCompoundPredicate {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = n0.date;
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = n0.date;
	
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2] error:nil];
	
	NSString *n1Id = n1.uid;
	NSString *n2Id = n2.uid;
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(t like %@) AND (v like %@)", @"fancy", @"cool"];
	id<BRSearchResults> results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	XCTAssertTrue([results isKindOfClass:[CLuceneSearchResults class]], @"Results must be LuceneSearchResults");
	__block NSUInteger count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertTrue([result isKindOfClass:[CLuceneSearchResult class]], @"Results must be LuceneBRSimpleIndexableSearchResult");
		XCTAssertEqualObjects([result identifier], n1Id, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
	
	predicate = [NSPredicate predicateWithFormat:@"((t like %@) AND (v like %@)) OR (t like %@)", @"fancy", @"note", @"pretty"];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	XCTAssertEqual([results count], (NSUInteger)2, @"results count");
	XCTAssertTrue([results isKindOfClass:[CLuceneSearchResults class]], @"Results must be LuceneSearchResults");
	count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		switch ( index ) {
			case 0:
				XCTAssertEqualObjects([result identifier], n1Id, @"object ID");
				break;
				
			case 1:
				XCTAssertEqualObjects([result identifier], n2Id, @"object ID");
				break;
				
		}
		count++;
		XCTAssertTrue([result isKindOfClass:[CLuceneSearchResult class]], @"Results must be LuceneBRSimpleIndexableSearchResult");
		
	}];
	XCTAssertEqual(count, (NSUInteger)2, @"results iterated");
}

- (void)testSearchWithTimestampPredicateRange {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.date = [NSDate new];
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = [n0.date dateByAddingTimeInterval:4];
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = [n0.date dateByAddingTimeInterval:8];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2] error:nil];
	
	NSString *n0Id = n0.uid;
	NSString *n1Id = n1.uid;
	NSString *n2Id = n2.uid;
	
	// first search for inclusive range for all documents
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(s >= %@) AND (s <= %@)", n0.date, n2.date];
	id<BRSearchResults> results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n0Id, n1Id, n2Id] msg:@"inclusive range"];
	
	// now search for exclusive range...
	predicate = [NSPredicate predicateWithFormat:@"(s > %@) AND (s < %@)", n0.date, n2.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n1Id] msg:@"exclusive range"];

	// now search for inclusive + exclusive range...
	predicate = [NSPredicate predicateWithFormat:@"(s >= %@) AND (s < %@)", n0.date, n2.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n0Id, n1Id] msg:@"inclusive + exclusive range"];

	// now search for exclusive + inclusive range...
	predicate = [NSPredicate predicateWithFormat:@"(s > %@) AND (s <= %@)", n0.date, n2.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n1Id, n2Id] msg:@"exclusive + inclusive range"];
	
	// now search for reversed exclusive + inclusive range...
	predicate = [NSPredicate predicateWithFormat:@"(s < %@) AND (s >= %@)", n2.date, n0.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n0Id, n1Id] msg:@"reversed exclusive + inclusive range"];

	// now search for reversed inclusive + exclusive range...
	predicate = [NSPredicate predicateWithFormat:@"(s <= %@) AND (s > %@)", n2.date, n0.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n1Id, n2Id] msg:@"reversed inclusive + exclusive range"];

	// now search for reversed exclusive range...
	predicate = [NSPredicate predicateWithFormat:@"(s < %@) AND (s > %@)", n2.date, n0.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n1Id] msg:@"reversed exclusive range"];

	// now search for reversed inclusive range...
	predicate = [NSPredicate predicateWithFormat:@"(s <= %@) AND (s >= %@)", n2.date, n0.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n0Id, n1Id, n2Id] msg:@"reversed inclusive range"];
}

- (void)testSearchWithTimestampPredicateRangeMoreThanTwoExpressions {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.date = [NSDate new];
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = [n0.date dateByAddingTimeInterval:4];
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = [n0.date dateByAddingTimeInterval:8];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2] error:nil];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"o = %@ AND ((s >= %@) AND (s <= %@))", @"?", n0.date, n2.date];
	id<BRSearchResults> results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n0.uid, n1.uid, n2.uid] msg:@"object type AND inclusive range"];

	predicate = [NSPredicate predicateWithFormat:@"o = %@ AND ((s > %@) AND (s < %@))", @"?", n0.date, n2.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n1.uid] msg:@"object type AND exclusive range"];
	
	predicate = [NSPredicate predicateWithFormat:@"o = %@ AND ((s > %@) AND (s < %@))", @"!", n0.date, n2.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:nil msg:@"object type AND exclusive range"];
}

- (void)assertSearchResults:(id<BRSearchResults>)results matchingIdentifiers:(NSArray *)expectedIds msg:(NSString *)msg {
	XCTAssertEqual([results count], [expectedIds count], @"results count %@", msg);
	__block NSUInteger count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		XCTAssertEqualObjects([result identifier], expectedIds[count], @"object ID %@", msg);
		count++;
	}];
	XCTAssertEqual(count, [expectedIds count], @"results iterated %@", msg);
}

- (void)testSearchWithTimestampPredicateOpenEndedRange {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.date = [NSDate new];
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = [n0.date dateByAddingTimeInterval:4];
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = [n0.date dateByAddingTimeInterval:8];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2] error:nil];
	
	NSString *n0Id = n0.uid;
	NSString *n1Id = n1.uid;
	NSString *n2Id = n2.uid;
	
	// first search for >= range
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"s >= %@", n0.date];
	id<BRSearchResults> results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n0Id, n1Id, n2Id] msg:@">= range"];
	
	// now search for > range...
	predicate = [NSPredicate predicateWithFormat:@"s > %@", n0.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n1Id, n2Id] msg:@"> range"];
	
	// now search for <= range...
	predicate = [NSPredicate predicateWithFormat:@"s <= %@", n2.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n0Id, n1Id, n2Id] msg:@"<= range"];

	// now search for < range...
	predicate = [NSPredicate predicateWithFormat:@"s < %@", n2.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n0Id, n1Id] msg:@"< range"];

	// now search for > range out of bounds...
	predicate = [NSPredicate predicateWithFormat:@"s > %@", n2.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:nil msg:@"< range out of bounds"];

	// now search for < range out of bounds...
	predicate = [NSPredicate predicateWithFormat:@"s < %@", n0.date];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:nil msg:@"< range out of bounds"];
}

- (void)testIndexUntokenizedArrayAndSearchForResults {
	TestIndexable *n0 = [[TestIndexable alloc] initWithIdentifier:[BRTestSupport UUID]
															 data:@{
																	kBRSearchFieldNameTitle : @"My special note",
																	kBRSearchFieldNameValue : @"This is a long winded note with really important details in it.",
																	kBRTestIndexableSearchFieldNameTags : @[@"dogs", @"cats", @"mice"],
																	}];
	n0.date = [n0.date dateByAddingTimeInterval:-4]; // offset dates to test sorting
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with dogs in it.";
	n1.date = [[NSDate new] dateByAddingTimeInterval:-2];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1] error:nil];
	
	NSString *n0Id = n0.uid;
	NSString *n1Id = n1.uid;
	
	// first test individual results
	id<BRSearchResults> results = [searchService search:@"dog"];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	__block NSUInteger count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertEqualObjects([result identifier], n1Id, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(T == %@)", @"dog"];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	XCTAssertEqual([results count], (NSUInteger)0, @"results count");
	count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
	}];
	XCTAssertEqual(count, (NSUInteger)0, @"results iterated");
	
	predicate = [NSPredicate predicateWithFormat:@"(T == %@)", @"dogs"];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertEqualObjects([result identifier], n0Id, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
	
	predicate = [NSPredicate predicateWithFormat:@"(T == %@)", @"mice"];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertEqualObjects([result identifier], n0Id, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
}

- (void)testIndexUntokenizedSetAndSearchForResults {
	TestIndexable *n0 = [[TestIndexable alloc] initWithIdentifier:[BRTestSupport UUID]
															 data:@{
																	kBRSearchFieldNameTitle : @"My special note",
																	kBRSearchFieldNameValue : @"This is a long winded note with really important details in it.",
																	kBRTestIndexableSearchFieldNameTags : [NSSet setWithArray:@[@"dogs", @"cats", @"mice"]],
																	}];
	n0.date = [n0.date dateByAddingTimeInterval:-4]; // offset dates to test sorting
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with dogs in it.";
	n1.date = [[NSDate new] dateByAddingTimeInterval:-2];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1] error:nil];
	
	NSString *n0Id = n0.uid;
	NSString *n1Id = n1.uid;
	
	// first test individual results
	id<BRSearchResults> results = [searchService search:@"dog"];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	__block NSUInteger count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertEqualObjects([result identifier], n1Id, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(T == %@)", @"dog"];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	XCTAssertEqual([results count], (NSUInteger)0, @"results count");
	count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
	}];
	XCTAssertEqual(count, (NSUInteger)0, @"results iterated");
	
	predicate = [NSPredicate predicateWithFormat:@"(T == %@)", @"dogs"];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertEqualObjects([result identifier], n0Id, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
	
	predicate = [NSPredicate predicateWithFormat:@"(T == %@)", @"mice"];
	results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	XCTAssertEqual([results count], (NSUInteger)1, @"results count");
	count = 0;
	[results iterateWithBlock:^(NSUInteger index, id<BRSearchResult>result, BOOL *stop) {
		count++;
		XCTAssertEqualObjects([result identifier], n0Id, @"object ID");
	}];
	XCTAssertEqual(count, (NSUInteger)1, @"results iterated");
}

#pragma mark - Delete from index

- (void)testDeleteBRSimpleIndexable {
	BRSimpleIndexable *n = [self createTestIndexableInstance];
	[searchService addObjectToIndexAndWait:n error:nil];
	NSString *nIdentifier = n.uid;
	
	// verify we can find that document
	id<BRSearchResult> result = [searchService findObject:'?' withIdentifier:nIdentifier];
	XCTAssertNotNil(result, @"search result");
	
	[searchService removeObjectsFromIndexAndWait:'?' withIdentifiers:[NSSet setWithObject:nIdentifier] error:nil];
	
	// verify we CANNOT find that document
	id<BRSearchResult> result2 = [searchService findObject:'?' withIdentifier:nIdentifier];
	XCTAssertNil(result2, @"search result not found");
	
}

- (void)testDeleteNothing {
	// test that API doesn't freak out from empty sets
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
	[searchService removeObjectsFromIndexAndWait:'?' withIdentifiers:nil error:nil];
	[searchService removeObjectsFromIndexAndWait:'?' withIdentifiers:[NSSet new] error:nil];
	[searchService removeObjectsFromIndex:'?' withIdentifiers:nil queue:NULL finished:NULL];
	[searchService removeObjectsFromIndex:'?' withIdentifiers:[NSSet new] queue:NULL finished:NULL];
#pragma clang diagnostic pop
}

- (void)testBulkDeleteInclusiveRange {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.date = [NSDate new];
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = [n0.date dateByAddingTimeInterval:4];
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = [n0.date dateByAddingTimeInterval:8];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2] error:nil];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((s >= %@) AND (s <= %@))", n0.date, n2.date];
	[searchService removeObjectsFromIndexMatchingPredicateAndWait:predicate error:nil];
	
	id<BRSearchResults> results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:nil msg:@"<= s <="];
}

- (void)testDeleteExclusiveRange {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.date = [NSDate new];
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = [n0.date dateByAddingTimeInterval:4];
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = [n0.date dateByAddingTimeInterval:8];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2] error:nil];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((s > %@) AND (s < %@))", n0.date, n2.date];
	[searchService removeObjectsFromIndexMatchingPredicateAndWait:predicate error:nil];
	
	id<BRSearchResults> results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:nil msg:@"< s <"];
	results = [searchService searchWithPredicate:[NSPredicate predicateWithFormat:@"((s >= %@) AND (s <= %@))", n0.date, n2.date]
										  sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:@[n0.uid, n2.uid] msg:@"s == BulkDeleteExclusiveRange"];
}

- (void)testBulkDelete {
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.date = [NSDate new];
	BRSimpleIndexable *n1 = [self createTestIndexableInstance];
	n1.title = @"My other fancy note.";
	n1.value = @"This is a cool note with other stuff in it.";
	n1.date = [n0.date dateByAddingTimeInterval:4];
	BRSimpleIndexable *n2 = [self createTestIndexableInstance];
	n2.title = @"My pretty note.";
	n2.value = @"Oh this is a note, buddy.";
	n2.date = [n0.date dateByAddingTimeInterval:8];
	
	[searchService addObjectsToIndexAndWait:@[n0, n1, n2] error:nil];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ AND ((s >= %@) AND (s <= %@))",
									kBRSearchFieldNameObjectType,
									StringForBRSearchObjectType(kBRSimpleIndexableSearchObjectType),
									n0.date, n2.date];

	NSCondition *condition = [NSCondition new];
	[condition lock];
	__block BOOL finished = NO;
	[searchService bulkUpdateIndex:^(id<BRIndexUpdateContext> updateContext) {
		// first remove all documents for the date range we're going to re-index for... this takes care of removing documents
		// for events that have been deleted
		[searchService removeObjectsFromIndexMatchingPredicate:predicate context:updateContext];
	} queue:NULL finished:^(int updateCount, NSError *error) {
		[condition lock];
		finished = YES;
		[condition signal];
		[condition unlock];
	}];
	[condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:60]];
	[condition unlock];
	
	[searchService resetSearcher];

	id<BRSearchResults> results = [searchService searchWithPredicate:predicate sortBy:kBRSearchFieldNameTimestamp sortType:BRSearchSortTypeString ascending:YES];
	[self assertSearchResults:results matchingIdentifiers:nil msg:@"o == ? && < s <"];
}

- (void)testCustomAnalyzer {
	std::auto_ptr<Analyzer> wsAnalyzer(new lucene::analysis::WhitespaceAnalyzer());
	[searchService setDefaultAnalyer:wsAnalyzer];
	
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	n0.title = @"This note is tokenized on white-space only.";
	n0.value = nil;
	
	[searchService addObjectsToIndexAndWait:@[n0] error:nil];
	
	id<BRSearchResults> results;
	
	results = [searchService search:@"only"];
	[self assertSearchResults:results matchingIdentifiers:nil msg:@"'only' doesn't match because of period"];

	results = [searchService search:@"only."];
	[self assertSearchResults:results matchingIdentifiers:@[n0.uid] msg:@"'only.' matches because of period"];

	results = [searchService search:@"this"];
	[self assertSearchResults:results matchingIdentifiers:nil msg:@"'this' doesn't match because of case"];
	
	results = [searchService search:@"This"];
	[self assertSearchResults:results matchingIdentifiers:@[n0.uid] msg:@"'This' matches becaues of case"];
}

- (void)testCustomGeneralTextFields {
	searchService.generalTextFields = @[kBRSearchFieldNameValue]; // make value, not title, default general search field
	
	BRSimpleIndexable *n0 = [self createTestIndexableInstance];
	
	[searchService addObjectsToIndexAndWait:@[n0] error:nil];
	
	id<BRSearchResults> results;
	
	results = [searchService search:@"special"];
	[self assertSearchResults:results matchingIdentifiers:nil msg:@"'special' doesn't match because title not default general field"];
	
	results = [searchService search:@"t:special"];
	[self assertSearchResults:results matchingIdentifiers:@[n0.uid] msg:@"'special:t' matches because of explicit title field"];
}

@end
