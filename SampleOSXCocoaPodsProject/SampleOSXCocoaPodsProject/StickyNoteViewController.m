//
//  StickyNoteViewController.m
//  SampleOSXCocoaPodsProject
//
//  Created by Matt on 18/05/16.
//  Copyright © 2016 Blue Rocket, Inc. All rights reserved.
//

#import "StickyNoteViewController.h"

#import <MagicalRecord/CoreData+MagicalRecord.h>
#import "StickyNote.h"

@interface StickyNoteViewController ()
@property (strong) IBOutlet NSTextView *textView;
@property (strong) IBOutlet NSButton *deleteButton;

@end

@implementation StickyNoteViewController

- (void)viewWillAppear {
	[super viewWillAppear];
	NSString *text = self.note.text;
	if ( text.length > 0 ) {
		self.textView.string = text;
	}
	self.deleteButton.hidden = (self.note == nil);
}

- (IBAction)cancel:(id)sender {
	[self dismissViewController:self];
}

- (IBAction)deleteNote:(id)sender {
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
		[[self.note MR_inContext:localContext] MR_deleteInContext:localContext];
	}];
	[self dismissViewController:self];
}

- (IBAction)saveNote:(id)sender {
	StickyNote *note = self.note;
	NSString *text = self.textView.string;
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
		StickyNote *n;
		if ( !note ) {
			n = [StickyNote MR_createInContext:localContext];
			n.created = [StickyNote createdDateForCurrentSystemTime];
		} else {
			n = [note MR_inContext:localContext];
		}
		n.text = text;
	}];
	[self dismissViewController:self];
}

@end
