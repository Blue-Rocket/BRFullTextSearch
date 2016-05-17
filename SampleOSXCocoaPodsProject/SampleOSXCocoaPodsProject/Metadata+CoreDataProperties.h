//
//  Metadata+CoreDataProperties.h
//  SampleOSXCocoaPodsProject
//
//  Created by Matt on 18/05/16.
//  Copyright © 2016 Blue Rocket, Inc. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Metadata.h"

NS_ASSUME_NONNULL_BEGIN

@interface Metadata (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *created;

@end

NS_ASSUME_NONNULL_END
