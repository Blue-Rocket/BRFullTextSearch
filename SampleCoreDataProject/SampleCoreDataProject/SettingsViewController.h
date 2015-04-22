//
//  SettingsViewController.h
//  SampleCoreDataProject
//
//  Created by Matt on 4/22/15.
//  Copyright (c) 2015 Blue Rocket, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kStemmingDisabledKey;
extern NSString * const kStemmingPrefixSupportEnabledKey;

/**
 Provide a UI for changing system settings. Add settings are stored in @c NSUserDefaults.
 */
@interface SettingsViewController : UIViewController

@end
