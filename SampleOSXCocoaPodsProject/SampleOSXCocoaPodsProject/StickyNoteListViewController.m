//
//  ViewController.m
//  SampleOSXCocoaPodsProject
//
//  Created by Matt on 2/05/16.
//  Copyright © 2016 Blue Rocket, Inc. All rights reserved.
//

#import "StickyNoteListViewController.h"

@interface StickyNoteListViewController () <NSTableViewDataSource, NSTableViewDelegate>
@property (strong) IBOutlet NSTableView *tableView;

@end

@implementation StickyNoteListViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	// Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.
}

@end
