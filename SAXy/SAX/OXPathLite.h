//
//  OXPathLite.h
//  SAXy OX - Object-to-XML mapping library
//
//  Implements a subset of xpath language restricted to the stack-based nature of a SAX parser.
//  Supported path elements:
//
//    / - document root
//    * - any element
//    // or ** - zero or more elements
//    @ - attribute tag prefix
//    text() - text node
//
//  Created by Richard Easterling on 1/25/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    OXUnknownType,
    OXRootPathType,
    OXElementPathType,
    OXAnyPathType,
    OXAttributePathType,
    OXTextPathType,
    OXAnyAnyPathType
//    OXParentPathType,
//    OXCurrentPathType
} OXPathType;

@interface OXPathLite : NSObject

@property(strong,nonatomic,readonly)NSArray *tagStack;
@property(strong,nonatomic,readonly)NSArray *tagTypeStack;
@property(strong,nonatomic,readonly)NSString *pathRoot;
@property(strong,nonatomic,readonly)NSString *pathLeaf;

- (BOOL)hasRootTag;
- (BOOL)matches:(NSArray *)tagStack;
- (BOOL)hasLeafWildcard;
+ (id)xpath:(NSString *)xpath;

@end
