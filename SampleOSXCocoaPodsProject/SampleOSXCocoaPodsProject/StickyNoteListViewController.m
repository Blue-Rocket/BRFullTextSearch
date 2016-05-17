//
//  ViewController.m
//  SampleOSXCocoaPodsProject
//
//  Created by Matt on 2/05/16.
//  Copyright © 2016 Blue Rocket, Inc. All rights reserved.
//

#import "StickyNoteListViewController.h"

#import <BRFullTextSearch/BRFullTextSearch.h>
#import <BRFullTextSearch/NSDate+BRFullTextSearchAdditions.h>
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "AppDelegate.h"
#import "Notifications.h"
#import "StickyNote.h"
#import "StickyNoteViewController.h"

static NSString * const kDateCellIdentifier = @"DateCell";
static NSString * const kTextCellIdentifier = @"TextCell";

@interface StickyNoteListViewController () <NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate>
@property (strong) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSSearchField *searchField;
@property (readonly) id<BRSearchService> searchService;
@end

@implementation StickyNoteListViewController {
	NSArrayController *notesController;
	StickyNote *editNote;
	id<BRSearchResults> searchResults;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataDidChange:) name:NSManagedObjectContextDidSaveNotification object:[NSManagedObjectContext MR_rootSavingContext]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexDidChange:) name:SearchIndexDidChange object:nil];
}

- (void)viewWillAppear {
	[super viewWillAppear];
	notesController = [[NSArrayController alloc] init];
	notesController.managedObjectContext = [NSManagedObjectContext MR_defaultContext];
	notesController.entityName = @"StickyNote";
	notesController.automaticallyRearrangesObjects = YES;
	notesController.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"created" ascending:YES]];
	
	NSError *error = nil;
	[notesController fetchWithRequest:nil merge:NO error:&error];
	[self.tableView reloadData];

	NSToolbarItem *item = [self.view.window.toolbar.items firstObject];
	if ( [item.view isKindOfClass:[NSSearchField class]] ) {
		self.searchField = (NSSearchField *)item.view;
		self.searchField.delegate = self;
	}
}

- (void)controlTextDidChange:(NSNotification *)obj {
	id field = obj.object;
	if ( field == self.searchField ) {
		[self executeSearch];
	}
}

- (IBAction)newDocument:(id)sender {
	[self performSegueWithIdentifier:@"NewNote" sender:sender];
}

- (IBAction)doubleClickTable:(NSTableView *)sender {
	NSUInteger row = sender.clickedRow;
	if ( searchResults ) {
		id<BRSearchResult> r = [searchResults resultAtIndex:row];
		NSDate *noteDate = [NSDate dateWithIndexTimestampString:[r valueForField:kBRSearchFieldNameTimestamp]];
		editNote = [StickyNote MR_findFirstByAttribute:@"created" withValue:noteDate];
	} else {
		editNote = [notesController.arrangedObjects objectAtIndex:row];
	}
	if ( editNote ) {
		[self performSegueWithIdentifier:@"EditNote" sender:self];
	}
}

- (id<BRSearchService>)searchService {
	AppDelegate *delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
	return delegate.searchService;
}

- (void)executeSearch {
	NSString *query = [self.searchField stringValue];
	searchResults = nil;
	if ( query.length > 1 ) {
		searchResults = [self.searchService search:query];
		[self.tableView reloadData];
	}
}

- (void)searchFieldDidEndSearching:(NSSearchField *)sender {
	searchResults = nil;
	[self.tableView reloadData];
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
	if ( [segue.identifier isEqualToString:@"EditNote"] ) {
		StickyNoteViewController *dest = segue.destinationController;
		dest.note = editNote;
	}
}

- (void)dataDidChange:(NSNotification *)notification {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSError *error = nil;
		[notesController fetchWithRequest:nil merge:YES error:&error];
		[self.tableView reloadData];
	});
}

- (void)indexDidChange:(NSNotification *)notification {
	if ( searchResults ) {
		// re-refresh search results
		[self executeSearch];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return (searchResults
			? [searchResults count]
			: [notesController.arrangedObjects count]);
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSDate *noteDate = nil;
	NSString *noteText = nil;
	
	if ( searchResults ) {
		id<BRSearchResult> r = [searchResults resultAtIndex:row];
		noteDate = [NSDate dateWithIndexTimestampString:[r valueForField:kBRSearchFieldNameTimestamp]];
		noteText = [r valueForField:kBRSearchFieldNameValue];
	} else {
		StickyNote *stickyNote = [notesController.arrangedObjects objectAtIndex:row];
		noteDate = stickyNote.created;
		noteText = stickyNote.text;
	}
	
	static NSDateFormatter *dateFormatter;
	if ( dateFormatter == nil ) {
		dateFormatter = [[NSDateFormatter alloc] init];
		NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"h:m a MMMMddyyyy" options:0 locale:[NSLocale currentLocale]];
		[dateFormatter setDateFormat:formatString];
	}

	
	NSString *cellIdentifier;
	NSString *cellValue = nil;
	if ( tableColumn == tableView.tableColumns[0] ) {
		cellIdentifier = kDateCellIdentifier;
		cellValue = [dateFormatter stringFromDate:noteDate];
	} else {
		cellIdentifier = kTextCellIdentifier;
		cellValue = noteText;
	}
	NSTableCellView *cell = [tableView makeViewWithIdentifier:cellIdentifier owner:nil];
	cell.textField.stringValue = cellValue;
	return cell;
}

@end
