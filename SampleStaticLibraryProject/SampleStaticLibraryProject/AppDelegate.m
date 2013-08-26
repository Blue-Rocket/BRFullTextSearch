//
//  AppDelegate.m
//  SampleStaticLibraryProject
//
//  Created by Matt on 7/5/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#import "AppDelegate.h"

#import "ViewController.h"
#import <BRFullTextSearch/BRFullTextSearch.h>
#import <BRFullTextSearch/CLuceneSearchService.h>

NSString * const kIndexProgressNotification = @"IndexUpdateProgress";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
	self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
	
	_searchService = [CLuceneSearchService new];
	[self indexSampleData];
    return YES;
}

- (NSString *)testCopy:(NSUInteger)wordCount {
	if ( wordCount == 0 ) {
		return nil;
	}
	static NSArray *words;
	if ( words == nil ) {
		NSString *copyPath = [[NSBundle mainBundle] pathForResource:@"TestCopy" ofType:@"txt"];
		NSString *copy = [NSString stringWithContentsOfFile:copyPath encoding:NSUTF8StringEncoding error:nil];
		words = [copy componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	return [[words subarrayWithRange:NSMakeRange(0, MIN(wordCount, [words count]))] componentsJoinedByString:@" "];
}

static const NSUInteger kNumDocs = 50;

- (void)indexSampleData {
	// let's index some latin!
	[_searchService bulkUpdateIndex:^(id<BRIndexUpdateContext> updateContext) {
		@autoreleasepool {
			for ( NSUInteger i = 0; i < kNumDocs; i++ ) {
				BRSimpleIndexable *doc = [[BRSimpleIndexable alloc] initWithIdentifier:[NSString stringWithFormat:@"%lu", (unsigned long)i]
																				  data:@{
															  kBRSearchFieldNameTitle : [NSString stringWithFormat:@"Document %lu", (unsigned long)(i+1)],
															  kBRSearchFieldNameValue : [self testCopy:((arc4random() % 100) + 5)]
										  }];
				[_searchService addObjectToIndex:doc context:updateContext];
				[[NSNotificationCenter defaultCenter] postNotificationName:kIndexProgressNotification
																	object:@((double)i / (double)kNumDocs)];
			}
		}
	} queue:NULL finished:^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kIndexProgressNotification object:@(100)];
	}];
}

@end
