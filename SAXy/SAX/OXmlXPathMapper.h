//
//  OXmlXPathMapper.h
//  SAXy OX - Object-to-XML mapping library
//
//  OXmlXPathMapper extends OXPathMapper with XML-ish properties (xpath, namespace and xmlType) and constructors.
//
//  In the object-to-XML context the toPath (target) is a KVC property, for example: contact.address.city.
//  Likewise, the fromPath (source) is an xpath expression, for example: /root/element/@attribute.
//
//  Builder methods are provided to set properties making this class (mostly) immutable.
//
//  OXmlXPathMapper instances live in OXmlElementMapper objects, accessed through the parent property.
//
//  Optionaly a XML namespace can be set. If not set, the namespace returned will be the parent's namespace.
//
//  Created by Richard Easterling on 1/29/13.
//

#import "OXPathMapper.h"
#import "OXPathLite.h"


typedef enum {
    OX_XML_ATTRIBUTE,
    OX_XML_ELEMENT,
    OX_XML_BODY
} OXmlTypeEnum;


@interface OXmlXPathMapper : OXPathMapper

#pragma mark - properties
@property(strong,nonatomic,readonly)OXPathLite *xpath;      //parsed version of fromPath expression - only created for complex element paths
@property(strong,nonatomic,readonly)OXType *proxyType;      //if present, will be instantiated instead of declared toType class - TODO move to OXPathMapper
@property(strong,nonatomic,readonly)NSString *nsURI;        //namespace of tag. If not specified, defaults to parent nsURI
@property(assign,nonatomic,readonly)OXmlTypeEnum xmlType;   //what type of XML node this maps to
@property(strong,nonatomic,readonly)OXmlXPathMapper *next;  //allows chaining of mappers with the same lookup key (i.e. the same leafPath) - TODO move to OXPathMapper


#pragma mark - constructors
+ (id)xpath:(NSString *)xpath;
+ (id)xpath:(NSString *)xpath type:(Class)type;
+ (id)xpath:(NSString *)xpath type:(Class)type property:(NSString *)property;
+ (id)xpath:(NSString *)xpath scalar:(const char *)encodedType property:(NSString *)property;

#pragma mark - builder
- (OXmlXPathMapper *)factory:(OXFactoryBlock)factory;
- (OXmlXPathMapper *)setter:(OXSetterBlock)setter;
- (OXmlXPathMapper *)getter:(OXGetterBlock)getter;
- (OXmlXPathMapper *)toTransform:(OXTransformBlock)toTransform;
- (OXmlXPathMapper *)fromTransform:(OXTransformBlock)fromTransform;
- (OXmlXPathMapper *)enumerator:(OXEnumerationBlock)enumerator;
- (OXmlXPathMapper *)appender:(OXSetterBlock)appender;
- (OXmlXPathMapper *)nsURI:(NSString *)nsURI;
- (OXmlXPathMapper *)proxyClass:(Class)proxyClass;
- (OXmlXPathMapper *)isVirtualProperty;
- (OXmlXPathMapper *)formatter:(NSString *)formatterName;

#pragma mark - utility
+ (OXmlTypeEnum)xmlTypeFromPath:(NSString *)xpath;
+ (NSString *)xpathToKVCPath:(NSString *)xpath;
+ (NSString *)xpathToAttribute:(NSString *)xpath;

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
