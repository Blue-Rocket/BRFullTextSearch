//
//  AppDelegate.h
//  SampleOSXCocoaPodsProject
//
//  Created by Matt on 2/05/16.
//  Copyright © 2016 Blue Rocket, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol BRSearchService;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, readonly) id<BRSearchService> searchService;

@end

