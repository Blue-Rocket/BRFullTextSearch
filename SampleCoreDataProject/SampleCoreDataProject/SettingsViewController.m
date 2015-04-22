//
//  SettingsViewController.m
//  SampleCoreDataProject
//
//  Created by Matt on 4/22/15.
//  Copyright (c) 2015 Blue Rocket, Inc. All rights reserved.
//

#import "SettingsViewController.h"

NSString * const kStemmingDisabledKey = @"StemmingDisabled";
NSString * const kStemmingPrefixSupportEnabledKey = @"StemmingPrefixSupportEnabled";

@interface SettingsViewController ()
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topMarginConstraint;
@property (strong, nonatomic) IBOutlet UISwitch *stemmingSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *stemmingPrefixSwitch;
@end

@implementation SettingsViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self updateUIFromModel];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	self.topMarginConstraint.constant = (self.topLayoutGuide.length + 20);
}

- (void)updateUIFromModel {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.stemmingSwitch.on = ([defaults boolForKey:kStemmingDisabledKey] != YES);
	self.stemmingPrefixSwitch.enabled = self.stemmingSwitch.on;
	self.stemmingPrefixSwitch.on = [defaults boolForKey:kStemmingPrefixSupportEnabledKey];
}

- (IBAction)switchDidChange:(UISwitch *)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ( sender == self.stemmingSwitch ) {
		[defaults setBool:!sender.on forKey:kStemmingDisabledKey];
		[self updateUIFromModel];
	} else if ( sender == self.stemmingPrefixSwitch ) {
		[defaults setBool:sender.on forKey:kStemmingPrefixSupportEnabledKey];
	}
}

@end
