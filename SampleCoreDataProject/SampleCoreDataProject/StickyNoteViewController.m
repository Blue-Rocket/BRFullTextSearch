//
//  StickyNoteViewController.m
//  SampleCoreDataProject
//
//  Created by Matt on 8/26/13.
//  Copyright (c) 2013 Blue Rocket, Inc. All rights reserved.
//

#import "StickyNoteViewController.h"

#import "StickyNote.h"

@implementation StickyNoteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ( (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) ) {
        self.navigationItem.title = @"Edit Note";
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing:)];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.textView.text = self.stickyNote.text;
	[self.textView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.textView resignFirstResponder];
}

- (IBAction)doneEditing:(id)sender {
	if ( self.stickyNote == nil ) {
		if ( [self.textView.text length] > 0 ) {
			self.stickyNote = [StickyNote MR_createEntity];
			self.stickyNote.created = [NSDate new];
		}
	}
	if ( self.stickyNote != nil ) {
		[MagicalRecord saveUsingCurrentThreadContextWithBlockAndWait:^(NSManagedObjectContext *localContext) {
			self.stickyNote.text = self.textView.text;
		}];
	}
	[self.navigationController popViewControllerAnimated:YES];
}

@end
