//
//  CoreDataManager.m
//  SampleCoreDataProject
//
//  Created by Matt on 8/26/13.
//  Copyright (c) 2013 Blue Rocket, Inc. All rights reserved.
//

#import "CoreDataManager.h"

#import <BRFullTextSearch/BRFullTextSearch.h>

@implementation CoreDataManager

- (id)init {
	if ( (self = [super init]) ) {
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			[MagicalRecord setupCoreDataStack];
		});
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(maintainSearchIndexFromManagedObjectDidSave:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:[NSManagedObjectContext MR_defaultContext]];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)maintainSearchIndexFromManagedObjectDidSave:(NSNotification *)notification {
	NSMutableSet *changed = [NSMutableSet new];
	[changed addObjectsFromArray:[[notification.userInfo objectForKey:NSUpdatedObjectsKey] allObjects]];
	[changed addObjectsFromArray:[[notification.userInfo objectForKey:NSInsertedObjectsKey] allObjects]];
	NSMutableArray *updatedIndexables = [[NSMutableArray alloc] initWithCapacity:[changed count]];
	for ( id obj in changed ) {
		if ( [obj conformsToProtocol:@protocol(BRIndexable)] ) {
			[updatedIndexables addObject:obj];
		}
	}
	NSSet *deleted = [notification.userInfo objectForKey:NSDeletedObjectsKey];
	NSMutableArray *deletedIndexableIds = [[NSMutableArray alloc] initWithCapacity:[deleted count]];
	for ( id obj in deleted ) {
		if ( [obj conformsToProtocol:@protocol(BRIndexable)] ) {
			[deletedIndexableIds addObject:[obj indexIdentifier]];
		}
	}
	[self.searchService bulkUpdateIndex:^(id<BRIndexUpdateContext> updateContext) {
		for ( NSString *identifier in deletedIndexableIds ) {
			[self.searchService removeObjectFromIndex:kBRSimpleIndexableSearchObjectType withIdentifier:identifier context:updateContext];
		}
		for ( NSManagedObject *obj in updatedIndexables ) {
			NSManagedObject<BRIndexable> *localObj = (NSManagedObject<BRIndexable> *)[obj MR_inThreadContext];
			[self.searchService addObjectToIndex:localObj context:updateContext];
		}
	} queue:NULL finished:NULL];
}

@end
