//
//  ViewController.m
//  SampleStaticLibraryProject
//
//  Created by Matt on 7/5/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#import "ViewController.h"

#import "AppDelegate.h"
#import <BRFullTextSearch/BRFullTextSearch.h>

@implementation ViewController {
	id observer;
	id<BRSearchResults> results;
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
															  } completion:^(BOOL finished) {
																  [self.searchBar becomeFirstResponder];
															  }];
														  }
													  }];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

#pragma mark - UITableView support

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (tableView == self.searchDisplayController.searchResultsTableView ? [results count] : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellId = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
	if ( cell == nil ) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
	}
	id<BRSearchResult> result = [results resultAtIndex:indexPath.row];
	cell.textLabel.text = [result valueForField:kBRSearchFieldNameValue];
	cell.detailTextLabel.text = [result valueForField:kBRSearchFieldNameTitle];
	return cell;
}

#pragma mark - UISearchDisplayController support

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    NSLog(@"search: %@", searchString);
	BOOL search = ([searchString rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location != NSNotFound
				   || [searchString length] > 2);
	if ( search ) {
		results = [[(AppDelegate *)[UIApplication sharedApplication].delegate searchService]
				   search:controller.searchBar.text];
	}
	return search;
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
	NSLog(@"Searching for %@", self.searchBar.text);
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
	NSLog(@"Search ended for %@", self.searchBar.text);
}

@end
