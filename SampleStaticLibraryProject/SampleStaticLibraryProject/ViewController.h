//
//  ViewController.h
//  SampleStaticLibraryProject
//
//  Created by Matt on 7/5/13.
//  Copyright (c) 2013 Blue Rocket. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) IBOutlet UIProgressView *indexProgressView;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;

@end
