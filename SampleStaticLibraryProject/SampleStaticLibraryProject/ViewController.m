//
//  ViewController.m
//  SampleStaticLibraryProject
//
//  Created by Matt on 7/5/13.
//  Copyright (c) 2013 Blue Rocket. All rights reserved.
//

#import "ViewController.h"

#import "AppDelegate.h"

@implementation ViewController {
	id observer;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.indexProgressView.progress = 0;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ( observer == nil ) {
		observer = 
		[[NSNotificationCenter defaultCenter] addObserverForName:kIndexProgressNotification
														  object:nil
														   queue:[NSOperationQueue mainQueue]
													  usingBlock:^(NSNotification *notification) {
														  NSNumber *num = notification.object;
														  self.indexProgressView.progress = [num floatValue];
														  if ( self.indexProgressView.progress - 100.0 < 0.01 ) {
															  [UIView animateWithDuration:0.2 animations:^{
																  self.indexProgressView.alpha = 0;
															  }];
														  }
													  }];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.searchBar becomeFirstResponder];
}

#pragma mark - UITableView support

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}

@end
