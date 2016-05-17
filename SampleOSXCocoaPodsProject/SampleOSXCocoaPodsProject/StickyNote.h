//
//  StickyNote.h
//  SampleCoreDataProject
//
//  Created by Matt on 8/26/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <BRFullTextSearch/BRIndexable.h>

extern const BRSearchObjectType kStickyNoteSearchObjectType;

@interface StickyNote : NSManagedObject <BRIndexable>

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSString * text;

/**
 Get a date suitable for using as a @c created property value, based on the current time.
 
 @return The date.
 */
+ (NSDate *)createdDateForCurrentSystemTime;

@end
