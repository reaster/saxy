//
//  OXmlContext.h
//  SAXy OX - Object-to-XML mapping library
//
//  The context provides runtime state to readers and writers in form of various stacks and access
//  to the transform instance.  Specificly, it provides:
//
//  1) instanceStack        - target instances created by the mapper starting with the 'root' object
//  2) mapperStack          - OXmlElementMapper mappers used to instantiate the objects in the instance stack
//  3) pathStack            - tag path from root ('/') to leaf element - xpath queries run against pathStack
//  4) transform            - OXTransform with registered formatters and default block functions
//  5) result               - holds the result ('root' object) of the mapping operation
//  6) userData             - for custom mappers that need to pass data between operations at run time
//  7) debug tools          - logReaderStack and logReaderInput allow tracing of mapping process
//  8) global filtering     - attributeFilterBlock and elementFilterBlock can filter input by returning nil
//  9) OXSAXActionEnum stack - used internally to track mapping modes

//
//  Created by Richard Easterling on 1/15/13.
//

#import <Foundation/Foundation.h>
#import "OXTransform.h"
#import "OXContext.h"
@class OXmlContext;


typedef enum {
    OX_SAX_UNDEFINED_ACTION,    //undefined, helps catch uninitilized values
    OX_SAX_VALUE_ACTION,        //leaf node - simple element with text body
    OX_SAX_OBJECT_ACTION,       //complex node - complex element with child elements
    OX_SAX_SKIP_ACTION          //skip this element and it's attributes, process it's children
} OXSAXActionEnum;

typedef NSString* (^OXmlAttributeFilterBlock)(NSString *attrName, NSString *attrValue);
typedef NSString* (^OXmlElementFilterBlock)(NSString *elementName, NSString *elementValue);

@interface OXmlContext : OXContext

//@property(strong,readwrite,nonatomic) NSMutableDictionary *namespaces;            //indexed by prefix
@property(copy,readwrite,nonatomic) OXmlAttributeFilterBlock attributeFilterBlock;  //enables global filtering of attributes
@property(copy,readwrite,nonatomic) OXmlElementFilterBlock elementFilterBlock;      //enables global filtering of elements

#pragma mark - OXSAXActionEnum stack
- (void)pushMappingType:(OXSAXActionEnum)mappingType;
- (OXSAXActionEnum)popMappingType;
- (OXSAXActionEnum)peekMappingType;
- (OXSAXActionEnum)peekMappingTypeAtIndex:(NSInteger)index;

#pragma mark - element body text 
- (NSString *)text;
- (void)clearText;
- (void)appendText:(NSString *)text;

#pragma mark - debug
- (NSString *)tagPath;
+ (id)contextWithPathStack:(NSArray *)tagStack;

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
