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

@end

@implementation StickyNoteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	NSString *text = self.note.text;
	if ( text.length > 0 ) {
		self.textView.string = text;
	}
}

- (IBAction)saveNote:(id)sender {
	StickyNote *note = self.note;
	NSString *text = self.textView.string;
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
		StickyNote *n;
		if ( !note ) {
			n = [StickyNote MR_createInContext:localContext];
			n.created = [NSDate new];
		} else {
			n = [note MR_inContext:localContext];
		}
		n.text = text;
	}];
	[self dismissViewController:self];
}

@end
