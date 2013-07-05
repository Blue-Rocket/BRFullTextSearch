//
//  AppDelegate.h
//  SampleStaticLibraryProject
//
//  Created by Matt on 7/5/13.
//  Copyright (c) 2013 Blue Rocket. All rights reserved.
//

#import <UIKit/UIKit.h>

// notification sent with a NSNumber 0-1 object representing the progress of indexing
extern NSString * const kIndexProgressNotification;

@protocol BRSearchService;
@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *viewController;

@property (readonly, nonatomic) id<BRSearchService> searchService;

@end
