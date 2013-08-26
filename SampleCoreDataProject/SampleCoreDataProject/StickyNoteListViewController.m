//
//  StickyNoteListViewController.m
//  SampleCoreDataProject
//
//  Created by Matt on 8/26/13.
//  Copyright (c) 2013 Blue Rocket, Inc. All rights reserved.
//

#import "StickyNoteListViewController.h"

#import <BRFullTextSearch/NSDate+BRFullTextSearchAdditions.h>
#import "StickyNote.h"
#import "StickyNoteViewController.h"

@interface StickyNoteListViewController () <NSFetchedResultsControllerDelegate>
@end

@implementation StickyNoteListViewController {
	NSFetchedResultsController *stickyNotesModel;
	id<BRSearchResults> searchResults;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ( (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) ) {
		self.navigationItem.title = @"Sticky Notes";
		self.navigationItem.leftBarButtonItem = self.editButtonItem;
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																							   target:self
																							   action:@selector(addStickyNote:)];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ( stickyNotesModel == nil ) {
		stickyNotesModel = [StickyNote MR_fetchAllGroupedBy:nil withPredicate:nil sortedBy:@"created" ascending:NO delegate:self];
		[self.tableView reloadData];
	}
}

- (IBAction)addStickyNote:(id)sender {
	StickyNoteViewController *editor = [[StickyNoteViewController alloc] initWithNibName:@"StickyNoteViewController" bundle:nil];
	[self.navigationController pushViewController:editor animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[self.tableView setEditing:editing animated:animated];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch ( type ) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
						  withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
						  withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {
	
    UITableView *tableView = self.tableView;
	
    switch ( type ) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeUpdate:
			[self configureTableView:tableView cell:[tableView cellForRowAtIndexPath:indexPath]
						 atIndexPath:indexPath];
            break;
			
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
							 withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - UITableView support

- (void)configureTableView:(UITableView *)tableView cell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	static NSDateFormatter *dateFormatter;
	if ( dateFormatter == nil ) {
		dateFormatter = [[NSDateFormatter alloc] init];
		NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"h:m a MMMMddyyyy" options:0 locale:[NSLocale currentLocale]];
		[dateFormatter setDateFormat:formatString];
	}
    
	if ( tableView == self.tableView ) {
		StickyNote *stickyNote = [stickyNotesModel objectAtIndexPath:indexPath];
		cell.textLabel.text = stickyNote.text;
		cell.detailTextLabel.text = [dateFormatter stringFromDate:stickyNote.created];
	} else {
		// seach results
		id<BRSearchResult> result = [searchResults resultAtIndex:indexPath.row];
		cell.textLabel.text = [result valueForField:kBRSearchFieldNameValue];
		cell.detailTextLabel.text = [dateFormatter stringFromDate:
									 [NSDate dateWithIndexTimestampString:[result valueForField:kBRSearchFieldNameTimestamp]]];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if ( tableView == self.tableView ) {
		return [StickyNote MR_countOfEntities];
	}
	
	// search results table view here
	NSString *query = self.searchBar.text;
	searchResults = nil;
	if ( [query length] > 1 ) {
		searchResults = [self.searchService search:query];
	}
    return [searchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
	[self configureTableView:tableView cell:cell atIndexPath:indexPath];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	StickyNoteViewController *editor = [[StickyNoteViewController alloc] initWithNibName:@"StickyNoteViewController" bundle:nil];
	if ( tableView == self.tableView ) {
		editor.stickyNote = [stickyNotesModel objectAtIndexPath:indexPath];
	} else {
		// get StickyNote entity for search result
		id<BRSearchResult> result = [searchResults resultAtIndex:indexPath.row];
		NSDate *date = [NSDate dateWithIndexTimestampString:[result valueForField:kBRSearchFieldNameTimestamp]];
		editor.stickyNote = [StickyNote MR_findFirstByAttribute:@"created" withValue:date];
	}
	[self.navigationController pushViewController:editor animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if ( editingStyle == UITableViewCellEditingStyleDelete ) {
		StickyNote *stickyNote = [stickyNotesModel objectAtIndexPath:indexPath];
		[MagicalRecord saveUsingCurrentThreadContextWithBlockAndWait:^(NSManagedObjectContext *localContext) {
			[[stickyNote managedObjectContext] deleteObject:stickyNote];
		}];
	}
}


@end
