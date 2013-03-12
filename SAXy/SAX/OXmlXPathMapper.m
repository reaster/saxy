//
//  OXmlXPathMapper.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/29/13.
//

#import "OXmlXPathMapper.h"
#import "OXUtil.h"
#import "OXmlElementMapper.h"

@implementation OXmlXPathMapper
{
    NSString *_nsURI;
}

#pragma mark - constructors

- (id)initXpath:(NSString *)xpath type:(Class)type property:(NSString *)property
{
    if (self = [super initMapperToClass:type toPath:property fromClass:[NSString class] fromPath:xpath]) {
        if ([OXUtil isXPathString:xpath]) {         //only allocate for multi-element or wildcard paths
            if ([OXUtil  firstIndexOfChar:'@' inString:xpath] >= 0 || [xpath hasSuffix:OX_TEXT_NODE]) {
                NSAssert1(NO, @"ERROR: unsupported xpath: '%@' - mixing leaf nodes (attributes or text) with element nodes currently not supported", xpath);
            }
            _xpath = [OXPathLite xpath:xpath];
        }
        _xmlType = [[self class] xmlTypeFromPath:xpath];
        if (property == nil) {
            property = _xpath ? _xpath.pathLeaf : xpath;
            self.toPath = [[self class] xpathToKVCPath:property];
        }
        if (_xmlType == OX_XML_ATTRIBUTE && [xpath hasPrefix:OX_ATTRIBUTE_PREFIX]) {
            self.fromPath = [xpath substringWithRange:NSMakeRange(1,[xpath length]-1)];
        }
    }
    return self;
}

- (id)initXpath:(NSString *)xpath scalar:(const char *)encodedType property:(NSString *)property
{
    if (self = [super initMapperToScalar:encodedType toPath:property fromClass:[NSString class] fromPath:xpath]) {
        _xmlType = [[self class] xmlTypeFromPath:xpath];
        if (property == nil) {
            property = _xpath ? _xpath.pathLeaf : xpath;
            self.toPath = [[self class] xpathToKVCPath:property];
        }
        if (_xmlType == OX_XML_ATTRIBUTE && [xpath hasPrefix:OX_ATTRIBUTE_PREFIX]) {
            self.fromPath = [xpath substringWithRange:NSMakeRange(1,[xpath length]-1)];
        }
    }
    return self;
}

+ (id)xpath:(NSString *)xpath
{
    return [[OXmlXPathMapper alloc] initXpath:xpath type:nil property:nil];
}

+ (id)xpath:(NSString *)xpath type:(Class)type
{
    return [[OXmlXPathMapper alloc] initXpath:xpath type:type property:nil];
}

+ (id)xpath:(NSString *)xpath type:(Class)type property:(NSString *)property
{
    return [[OXmlXPathMapper alloc] initXpath:xpath type:type property:property];
}

+ (id)xpath:(NSString *)xpath scalar:(const char *)encodedType property:(NSString *)property
{
    return [[OXmlXPathMapper alloc] initXpath:xpath scalar:encodedType property:property];
}

#pragma mark - builder

- (OXmlXPathMapper *)factory:(OXFactoryBlock)factory
{
    self.factory = factory;
    return self;
}

- (OXmlXPathMapper *)setter:(OXSetterBlock)setter
{
    self.setter = setter;
    return self;
}

- (OXmlXPathMapper *)getter:(OXGetterBlock)getter
{
    self.getter = getter;
    return self;
}

- (OXmlXPathMapper *)toTransform:(OXTransformBlock)toTransform
{
    self.toTransform = toTransform;
    return self;
}

- (OXmlXPathMapper *)fromTransform:(OXTransformBlock)fromTransform
{
    self.fromTransform = fromTransform;
    return self;
}

- (OXmlXPathMapper *)enumerator:(OXEnumerationBlock)enumerator
{
    self.enumerator = enumerator;
    return self;
}

- (OXmlXPathMapper *)appender:(OXSetterBlock)appender
{
    self.appender = appender;
    return self;
}

- (OXmlXPathMapper *)nsURI:(NSString *)nsURI
{
    self.nsURI = nsURI;
    return self;
}

- (OXmlXPathMapper *)proxyClass:(Class)proxyClass
{
    _proxyType = [OXType cachedType:proxyClass];
    return self;
}

- (OXmlXPathMapper *)isVirtualProperty
{
    self.virtualProperty = YES;
    return self;
}

- (OXmlXPathMapper *)formatter:(NSString *)formatterName
{
    [self setValue:formatterName forKey:@"formatterName"];
    return self;
}


#pragma mark - properties

@dynamic nsURI;
- (NSString *)nsURI
{
    if (_nsURI) {
        return _nsURI;
    } else {
        OXmlElementMapper *parentElementMapper = (OXmlElementMapper *)self.parent;
        NSAssert1(parentElementMapper != nil, @"OXmlXPathMapper 'nsURI' property can't be accessed if parent is not set in %@", self);
        return parentElementMapper.nsURI;
    }
}
- (void)setNsURI:(NSString *)nsURI
{
    _nsURI = nsURI;
}

@dynamic fromPathRoot;
- (NSString *)fromPathRoot
{
    return _xpath ? _xpath.pathRoot : self.fromPath;                    //lazy use of xpath
}

@dynamic fromPathLeaf;
- (NSString *)fromPathLeaf
{
    return _xpath ? _xpath.pathLeaf : self.fromPath;                    //lazy use of xpath
}

#pragma mark - utility


+ (OXmlTypeEnum)xmlTypeFromPath:(NSString *)xpath
{
    NSArray *segments = [xpath componentsSeparatedByString:OX_ROOT_PATH];
    NSString *tag = [segments lastObject];
    if ([tag hasPrefix:OX_ATTRIBUTE_PREFIX]) {
        return OX_XML_ATTRIBUTE;
    } else if ([tag isEqualToString:OX_TEXT_NODE]) {
        return OX_XML_BODY;
    } else {
        return OX_XML_ELEMENT;
    }
}

+ (NSString *)xpathToKVCPath:(NSString *)xpath
{
    NSString *result = [xpath stringByReplacingOccurrencesOfString:OX_ROOT_PATH withString:@"."];
    result = [result stringByReplacingOccurrencesOfString:OX_ATTRIBUTE_PREFIX withString:@""];
    result = [result stringByReplacingOccurrencesOfString:@".text()" withString:@""];   //handle case: elem/text()
    result = [result stringByReplacingOccurrencesOfString:OX_TEXT_NODE withString:@""];
    return result;
}

+ (NSString *)xpathToAttribute:(NSString *)xpath
{
    if ([OXUtil lastIndexOfChar:'@' inString:xpath] < 0) {
        int lastIndex = [OXUtil lastIndexOfChar:'/' inString:xpath];
        if (lastIndex < 0) {
            return [NSString stringWithFormat:@"%@%@", OX_ATTRIBUTE_PREFIX, xpath];
        } else {
            int len = [xpath length];
            return [NSString stringWithFormat:@"%@%@%@", [xpath substringWithRange:NSMakeRange(0,lastIndex)], OX_ATTRIBUTE_PREFIX, [xpath substringWithRange:NSMakeRange(lastIndex,len)]];
        }
    } else {
        return xpath;
    }
}

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
