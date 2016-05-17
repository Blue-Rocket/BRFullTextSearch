//
//  AppDelegate.m
//  SampleOSXCocoaPodsProject
//
//  Created by Matt on 2/05/16.
//  Copyright © 2016 Blue Rocket, Inc. All rights reserved.
//

#import "AppDelegate.h"

#import <BRFullTextSearch/BRFullTextSearch.h>
#import <BRFullTextSearch/CLuceneSearchService.h>
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "CoreDataManager.h"
#import "Metadata.h"
#import "StickyNote.h"

@interface AppDelegate ()

- (IBAction)saveAction:(id)sender;

@end

@implementation AppDelegate {
	CoreDataManager *coreDataManager;
	CLuceneSearchService *searchService;
}

@synthesize searchService;

+ (void)initialize {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[MagicalRecord setupCoreDataStack];
	});
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	// set up search, core data
	searchService = [CLuceneSearchService new];
	coreDataManager = [CoreDataManager new];
	coreDataManager.searchService = searchService;
	
	NSUInteger count = [Metadata MR_countOfEntities];
	if ( count < 1 ) {
		// populate initial dataset
		NSString *sampleDir = [[[NSBundle mainBundle] pathForResource:@"sample-1" ofType:@"json" inDirectory:@"Sample Data"] stringByDeletingLastPathComponent];
		NSError *error = nil;
		NSArray<NSString *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sampleDir error:&error];
		if ( error ) {
			NSLog(@"Error listing sample data files directory %@: %@", sampleDir, [error localizedDescription]);
			return;
		}
		[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
			NSError *error = nil;
			for ( NSString *fileName in files ) {
				NSString *filePath = [sampleDir stringByAppendingPathComponent:fileName];
				NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:&error];
				if ( !data ) {
					NSLog(@"Error reading sample data file %@: %@", sampleDir, [error localizedDescription]);
					error = nil;
					continue;
				}
				NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
				if ( !json ) {
					NSLog(@"Error reading sample data file %@: %@", sampleDir, [error localizedDescription]);
					error = nil;
					continue;
				}
				StickyNote *note = [StickyNote MR_createInContext:localContext];
				note.text = json[@"text"];
				note.created = [StickyNote createdDateForCurrentSystemTime];
				if ( [fileName isEqualToString:[files lastObject]] == NO ) {
					[NSThread sleepForTimeInterval:1]; // note primary key based on timestamp, so make sure each is unique
				}
			}
			Metadata *m = [Metadata MR_createInContext:localContext];
			m.created = [NSDate new];
		}];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (NSManagedObjectContext *)managedObjectContext {
	return [NSManagedObjectContext MR_contextForCurrentThread];
}

#pragma mark - Core Data Saving and Undo support

- (IBAction)saveAction:(id)sender {
    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    NSError *error = nil;
    if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.
    
    if (![self managedObjectContext]) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertFirstButtonReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
