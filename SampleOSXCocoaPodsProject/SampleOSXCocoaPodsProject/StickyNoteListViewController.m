//
//  ViewController.m
//  SampleOSXCocoaPodsProject
//
//  Created by Matt on 2/05/16.
//  Copyright © 2016 Blue Rocket, Inc. All rights reserved.
//

#import "StickyNoteListViewController.h"

#import <BRFullTextSearch/NSDate+BRFullTextSearchAdditions.h>
#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "AppDelegate.h"
#import "Notifications.h"
#import "StickyNote.h"
#import "StickyNoteViewController.h"

static NSString * const kDateCellIdentifier = @"DateCell";
static NSString * const kTextCellIdentifier = @"TextCell";

@interface StickyNoteListViewController () <NSTableViewDataSource, NSTableViewDelegate>
@property (strong) IBOutlet NSTableView *tableView;

@end

@implementation StickyNoteListViewController {
	NSArrayController *notesController;
	StickyNote *editNote;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataDidChange:) name:NSManagedObjectContextDidSaveNotification object:[NSManagedObjectContext MR_rootSavingContext]];
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
}

- (IBAction)newDocument:(id)sender {
	NSLog(@"New!");
	[self performSegueWithIdentifier:@"NewNote" sender:sender];
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

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [notesController.arrangedObjects count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	static NSDateFormatter *dateFormatter;
	if ( dateFormatter == nil ) {
		dateFormatter = [[NSDateFormatter alloc] init];
		NSString *formatString = [NSDateFormatter dateFormatFromTemplate:@"h:m a MMMMddyyyy" options:0 locale:[NSLocale currentLocale]];
		[dateFormatter setDateFormat:formatString];
	}

	StickyNote *stickyNote = [notesController.arrangedObjects objectAtIndex:row];
	NSString *cellIdentifier;
	NSString *cellValue = nil;
	if ( tableColumn == tableView.tableColumns[0] ) {
		cellIdentifier = kDateCellIdentifier;
		cellValue = [dateFormatter stringFromDate:stickyNote.created];
	} else {
		cellIdentifier = kTextCellIdentifier;
		cellValue = stickyNote.text;
	}
	NSTableCellView *cell = [tableView makeViewWithIdentifier:cellIdentifier owner:nil];
	cell.textField.stringValue = cellValue;
	return cell;
}

@end
