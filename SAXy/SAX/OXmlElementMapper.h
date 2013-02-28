//
//  OXmlElementMapper.h
//  SAXy OX - Object-to-XML mapping library
//
//  Extends OXComplexMapper with XML-ish properties and builder pattern.
//
//  Created by Richard Easterling on 1/29/13.
//

#import <Foundation/Foundation.h>
#import "OXComplexMapper.h"
#import "OXPathMapper.h"
#import "OXmlXPathMapper.h"
#import "OXPathLite.h"
@class OXmlMapper;

@interface OXmlElementMapper : OXComplexMapper

#pragma mark - properties
@property(strong,nonatomic,readonly)NSArray *orderedAttributePropertyKeys;  //properties mapped to attribute values in declaration order
@property(strong,nonatomic,readonly)NSArray *orderedElementPropertyKeys;    //properties mapped to element values in declaration order
@property(strong,nonatomic,readonly)OXmlXPathMapper *bodyMapper;            //if present, maps body value (i.e. text()) in elements with attributes
@property(strong,nonatomic,readonly)OXPathLite *xpath;                      //parsed xpath
@property(strong,nonatomic,readwrite)OXmlElementMapper *next;               //sorted linked-list of mappers with identical leaf nodes 
@property(strong,nonatomic,readwrite)NSString *nsURI;                       //if not specified, defaults to parent nsURI
@property(strong,nonatomic,readwrite)NSString *nsPrefix;                    //if not specified, lookup using nsURI
@property(weak,nonatomic,readonly)OXmlMapper *parentMapper;

#pragma mark - constructors
+ (id)root;
+ (id)rootXPath:(NSString *)xpath nsURI:(NSString *)nsURI;
+ (id)rootXPath:(NSString *)xpath type:(Class)toType;
+ (id)rootXPath:(NSString *)xpath type:(Class)toType nsURI:(NSString *)nsURI;
+ (id)rootXPath:(NSString *)xpath toMany:(Class)toType;
+ (id)rootXPath:(NSString *)xpath toMany:(Class)toType nsURI:(NSString *)nsURI;
+ (id)elementClass:(Class)type;
+ (id)elementClass:(Class)type nsURI:(NSString *)nsURI;
+ (id)element:(NSString *)elementName toClass:(Class)objectClass;

#pragma mark - builder pattern
- (OXmlElementMapper *)xpathMapper:(OXmlXPathMapper *)xpathMapper;
- (OXmlElementMapper *)switchToNamespaceURI:(NSString *)nsURI;
- (OXmlElementMapper *)tag:(NSString *)tag;
- (OXmlElementMapper *)tags:(NSArray *)tags;
- (OXmlElementMapper *)tagMap:(NSDictionary *)tagToPropertyMap;
- (OXmlElementMapper *)tag:(NSString *)tag scalarType:(char const *)encodedType;
- (OXmlElementMapper *)tag:(NSString *)tag type:(Class)propertyClass;
- (OXmlElementMapper *)ignoreTags:(NSArray *)tags;
- (OXmlElementMapper *)xpath:(NSString *)xpath;
- (OXmlElementMapper *)xpath:(NSString *)xpath property:(NSString*)property;
- (OXmlElementMapper *)xpath:(NSString *)xpath property:(NSString*)property type:(Class)propertyClass;
- (OXmlElementMapper *)xpath:(NSString *)xpath property:(NSString*)property scalarType:(char const *)encodedType;
- (OXmlElementMapper *)body:(NSString *)bodyProperty;
- (OXmlElementMapper *)body:(NSString *)bodyProperty scalarType:(char const *)encodedType;
- (OXmlElementMapper *)attribute:(NSString *)tag;
- (OXmlElementMapper *)attributes:(NSArray *)tags;
- (OXmlElementMapper *)attribute:(NSString *)tag property:(NSString*)property;
- (OXmlElementMapper *)attribute:(NSString *)tag property:(NSString*)property type:(Class)propertyClass;
- (OXmlElementMapper *)xpath:(NSString *)xpath toMany:(Class)childType;
- (OXmlElementMapper *)xpath:(NSString *)xpath toMany:(Class)childType property:(NSString*)property;
- (OXmlElementMapper *)xpath:(NSString *)xpath toMany:(Class)childType property:(NSString*)property containerType:(Class)containerType;
- (OXmlElementMapper *)xpath:(NSString *)xpath toMany:(Class)childType property:(NSString*)property dictionaryKey:(NSString *)keyProperty;
- (OXmlElementMapper *)elementFactory:(OXFactoryBlock)factory;
- (OXmlElementMapper *)ignoreProperties:(NSArray *)ignoreProperties;
- (OXmlElementMapper *)lockMapping;

#pragma mark - lookup 
- (OXmlXPathMapper *)matchPathStack:(NSArray *)tagStack forNSPrefix:(NSString *)nsPrefix;
- (OXmlXPathMapper *)elementMapperByTag:(NSString *)tag nsURI:(NSString *)nsURI;
- (OXmlXPathMapper *)attributeMapperByTag:(NSString *)tag nsURI:(NSString *)nsURI;
- (OXmlXPathMapper *)elementMapperByProperty:(NSString *)property;
- (OXmlXPathMapper *)attributeMapperByProperty:(NSString *)property;

#pragma mark - utility
- (BOOL)hasChildElements; //ie has child elements
- (BOOL)noChildElements; //ie no child elements


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
