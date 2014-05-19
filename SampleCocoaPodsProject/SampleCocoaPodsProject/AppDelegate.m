//
//  AppDelegate.m
//  SampleCocoaPodsProject
//
//  Created by Matt on 5/15/14.
//  Copyright (c) 2014 Blue Rocket, Inc. All rights reserved.
//

#import "AppDelegate.h"

#import <BRFullTextSearch/BRFullTextSearch.h>
#import <BRFullTextSearch/CLuceneSearchService.h>
#import "CoreDataManager.h"
#import "StickyNoteListViewController.h"


@implementation AppDelegate {
	CoreDataManager *coreDataManager;
	CLuceneSearchService *searchService;
}

@synthesize searchService;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// set up search, core data
	searchService = [CLuceneSearchService new];
	coreDataManager = [CoreDataManager new];
	coreDataManager.searchService = searchService;
	
    return YES;
}

@end
