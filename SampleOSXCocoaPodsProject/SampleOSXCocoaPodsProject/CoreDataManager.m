//
//  CoreDataManager.m
//  SampleCoreDataProject
//
//  Created by Matt on 8/26/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#import "CoreDataManager.h"

#import <BRFullTextSearch/BRFullTextSearch.h>
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "Notifications.h"

@implementation CoreDataManager

- (id)init {
	if ( (self = [super init]) ) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(maintainSearchIndexFromManagedObjectDidSave:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:[NSManagedObjectContext MR_rootSavingContext]];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)maintainSearchIndexFromManagedObjectDidSave:(NSNotification *)notification {
	// for inserted or updated objects, collect into array so we can add them to index in batch on background thread
	NSMutableSet *changed = [NSMutableSet new];
	[changed addObjectsFromArray:[[notification.userInfo objectForKey:NSUpdatedObjectsKey] allObjects]];
	[changed addObjectsFromArray:[[notification.userInfo objectForKey:NSInsertedObjectsKey] allObjects]];
	NSMutableArray *updatedIndexables = [[NSMutableArray alloc] initWithCapacity:[changed count]];
	for ( id obj in changed ) {
		if ( [obj conformsToProtocol:@protocol(BRIndexable)] ) {
			[updatedIndexables addObject:obj];
		}
	}
	
	// for deleted objects, create dictionary of object type -> identifier, so we can delete them in batch
	NSSet *deleted = [notification.userInfo objectForKey:NSDeletedObjectsKey];
	NSMutableDictionary *deletedIndexableIds = [[NSMutableDictionary alloc] initWithCapacity:[deleted count]];
	for ( id obj in deleted ) {
		if ( [obj conformsToProtocol:@protocol(BRIndexable)] ) {
			NSString *objectType = StringForBRSearchObjectType([obj indexObjectType]);
			NSMutableArray *ids = [deletedIndexableIds objectForKey:objectType];
			if ( ids == nil ) {
				ids = [[NSMutableArray alloc] initWithCapacity:[deleted count]];
				[deletedIndexableIds setObject:ids forKey:objectType];
			}
			[ids addObject:[obj indexIdentifier]];
		}
	}
	
	// perform the index update batch operation on a background thread
	[self.searchService bulkUpdateIndex:^(id<BRIndexUpdateContext> updateContext) {
		[NSManagedObjectContext MR_resetContextForCurrentThread]; // make sure we pull in latest data
		for ( NSString *objectType in deletedIndexableIds ) {
			BRSearchObjectType type = BRSearchObjectTypeForString(objectType);
			for ( NSString *identifier in [deletedIndexableIds objectForKey:objectType] ) {
				[self.searchService removeObjectFromIndex:type withIdentifier:identifier context:updateContext];
			}
		}
		for ( NSManagedObject *obj in updatedIndexables ) {
			NSManagedObject<BRIndexable> *localObj = (NSManagedObject<BRIndexable> *)[obj MR_inThreadContext];
			[self.searchService addObjectToIndex:localObj context:updateContext];
		}
	} queue:dispatch_get_main_queue() finished:^(int updateCount, NSError *error) {
		[[NSNotificationCenter defaultCenter] postNotificationName:SearchIndexDidChange object:nil];
	}];
}

@end
