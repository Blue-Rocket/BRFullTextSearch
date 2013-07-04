//
//  SearchFields.h
//  BRFullTextSearch
//
//  Created by Matt on 6/7/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#ifdef __cplusplus
extern "C" {
#endif

extern NSString * const kBRSearchFieldNameIdentifier;
extern NSString * const kBRSearchFieldNameObjectType;
extern NSString * const kBRSearchFieldNameTitle;
extern NSString * const kBRSearchFieldNameValue;
extern NSString * const kBRSearchFieldNameTimestamp;

typedef char BRSearchObjectType;

extern NSString * StringForBRSearchObjectType(BRSearchObjectType type);
extern BRSearchObjectType BRSearchObjectTypeForString(NSString * string);

#ifdef __cplusplus
}
#endif
