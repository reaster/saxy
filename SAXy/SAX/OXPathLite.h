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
//

#import <Foundation/Foundation.h>

#define OX_TEXT_NODE @"text()"
#define OX_ATTRIBUTE_PREFIX @"@"

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

//
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
