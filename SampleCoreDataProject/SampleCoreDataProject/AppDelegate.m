//
//  AppDelegate.m
//  SampleCoreDataProject
//
//  Created by Matt on 8/26/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// set up search, core data
	searchService = [CLuceneSearchService new];
	searchService.supportStemmedPrefixSearches = YES; // new in 1.0.5
	NSLog(@"Lucene index initialized at %@", searchService.indexPath);
	coreDataManager = [CoreDataManager new];
	coreDataManager.searchService = searchService;
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.viewController = [[StickyNoteListViewController alloc] initWithNibName:@"StickyNoteListViewController" bundle:nil];
	self.viewController.searchService = searchService;
	self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
