//
//  OXmlElementMapper.h
//  SAXy OX - Object-to-XML mapping library
//
//  OXmlElementMapper is one of SAXy's most important classes, extending OXComplexMapper with XML-ish properties.
//
//  OXmlElementMapper is usuly used in one of two ways:
//
//    1) as instance factory, triggered when a matching xpath is encountered
//    2) as a class property mapper, matching attribute, element and text nodes to their target properties
//
//  The root mapper (an instance factory) is usualy the first OXmlElementMapper you'll declare.  Its xpath must start 
//  with the root symbol ('/') and it kicks off the mapping process by instantiating and pushing your root object on
//  the stack.  The root mapper also determines weather the result is a single object or if the 'toMany' parameter is used,
//  a collection of objects.
//
//  Your root object's class property mapper is then loading becomeing the basis for how subequent XML tags are mapped to
//  the class properties.
//
//  Builder methods are provided for mapping common XML node types or collections of nodes.  SAXy's self-reflection
//  can do most of the mapping for you. In practice, this means you should only need to map:
//
//    1) properties mapped to XML attributes - properties map to elements by default
//    2) xml tags with names that don't match their property names. (i.e. 'some_element' -> 'someProperty')
//    3) scalar types wrapped in NSNumber properties - does '99' map to char, short, int, long or float?
//    4) container child types
//    5) the root class of the hiearchy - root element declarations are a minimal requirnment
//    6) the tag has it's own XML namespace
//
//  For cases where none of the these conditions apply, you don't need declare a mapping at all!  SAXy will
//  discover your class (via property declarations) and map it automaticly.
//
//  Situations that require a complete mapping are:
//
//    1) element output order is required - elemnts are written in the order in which they are mapped
//    2) mapping is restricted to a property subset - this applies when self-reflection is turned off via lockMapping
//    3) the mapping should not change with class changes - another case where lockMapping is used
//
//  OXmlElementMapper instances live in OXmlMapper objects, accessed through the parentMapper property.
//
//  Optionaly a XML namespace can be set. If not set, the namespace returned will be the parent's (OXmlMapper) namespace.
//
//  Although this class inherits OXPathMapper's block properties, the only block used in practice is the
//  factory block, which can be set using the 'elementFactory' builder method.
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
@property(weak,nonatomic,readonly)OXmlMapper *parentMapper;                 //must be set before calling lookup methods

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
- (OXmlElementMapper *)xpathMapper:(OXmlXPathMapper *)xpathMapper;      //
- (OXmlElementMapper *)switchToNamespaceURI:(NSString *)nsURI;          //changes namespace to subsequent mappings. set to nil to return to default NS
- (OXmlElementMapper *)elementFactory:(OXFactoryBlock)factory;          //sets the 'factory' block property
- (OXmlElementMapper *)ignoreProperties:(NSArray *)ignoreProperties;    //don't map these specific properties
- (OXmlElementMapper *)lockMapping;                                     //turn off self-reflectoin

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
