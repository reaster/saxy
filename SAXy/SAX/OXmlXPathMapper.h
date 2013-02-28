//
//  OXmlXPathMapper.h
//  SAXy OX - Object-to-XML mapping library
//
//  Extends OXPathMapper with XML-ish properties (xpath, namespace and xmlType) and constructors. 
//
//  Created by Richard Easterling on 1/29/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import "OXPathMapper.h"
#import "OXPathLite.h"


typedef enum {
    OX_XML_ATTRIBUTE,
    OX_XML_ELEMENT,
    OX_XML_BODY
} OXmlTypeEnum;

#define OX_TEXT_NODE @"text()"
#define OX_ATTRIBUTE_PREFIX @"@"

@interface OXmlXPathMapper : OXPathMapper

#pragma mark - properties
@property(strong,nonatomic,readonly)OXPathLite *xpath;                 //only created if for complex element paths
@property(strong,nonatomic,readonly)OXType *proxyType;                //used instead of declared class, must be a toTransfrom
@property(strong,nonatomic,readonly)NSString *nsURI;                  //if not specified, defaults to parent nsURI
@property(assign,nonatomic,readonly)OXmlTypeEnum xmlType;
@property(strong,nonatomic,readonly)OXmlXPathMapper *next;            //can be multiple mappers matching rootPath


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
