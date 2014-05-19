//
//  StickyNoteViewController.h
//  SampleCoreDataProject
//
//  Created by Matt on 8/26/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#import <UIKit/UIKit.h>

@class StickyNote;

@interface StickyNoteViewController : UIViewController

@property (nonatomic, strong) IBOutlet UITextView *textView;

@property (nonatomic, strong) StickyNote *stickyNote;

@end
