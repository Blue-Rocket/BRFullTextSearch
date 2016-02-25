//
//  BRSimpleSortDescriptor.h
//  BRFullTextSearch
//
//  Created by Matt on 25/02/16.
//  Copyright © 2016 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRSortDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A basic implementation of the \c BRSortDescriptor API.
 */
@interface BRSimpleSortDescriptor : NSObject <BRSortDescriptor>

/**
 Initialize with settings.
 
 @param fieldName The field name to sort by.
 @param type      The type of sort to apply.
 @param ascending YES for ascending, NO for descending order.
 
 @return The initialized instance.
 */
- (instancetype)initWithFieldName:(NSString *)fieldName
							 type:(BRSearchSortType)type
						ascending:(BOOL)ascending NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
