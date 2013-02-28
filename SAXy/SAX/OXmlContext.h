//
//  OXmlContext.h
//  SAXy OX - Object-to-XML mapping library
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

@property(strong,readwrite,nonatomic) NSMutableDictionary *namespaces;     //indexed by prefix
@property(copy,readwrite,nonatomic) OXmlAttributeFilterBlock attributeFilterBlock;
@property(copy,readwrite,nonatomic) OXmlElementFilterBlock elementFilterBlock;
@property(assign,readwrite,nonatomic) BOOL logReaderStack;
@property(assign,readwrite,nonatomic) BOOL logReaderInput;

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
