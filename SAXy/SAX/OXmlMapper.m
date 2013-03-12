//
//  OXmlMapper.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/30/13.
//

#import "OXmlMapper.h"
#import "NSMutableArray+OXStack.h"
#import "OXContext.h"


@implementation OXmlMapper
{
    NSMutableDictionary *_mappersIndexedByClass;
    NSMutableDictionary *_elementMappersByNSURI;
    NSMutableDictionary *_nsByURI;
    NSMutableDictionary *_nsByPrefix;
    OXmlContext *_context;
}


#pragma mark - constructor

- (id)initWithRootNamespace:(NSString *)nsURI recommendedPrefix:(NSString *)nsPrefix
{
    if (self = [super init]) {
        _nsURI = nsURI;
        _nsPrefix = nsPrefix;
        [self defaultPrefix:nsPrefix forNamespaceURI:nsURI];
    }
    return self;
}

+ (id)mapper
{
    return [[OXmlMapper alloc] initWithRootNamespace:OX_DEFAULT_NAMESPACE recommendedPrefix:OX_DEFAULT_NAMESPACE];
}

+ (id)mapperWithDefaultNamespace:(NSString *)nsURI
{
    return [[OXmlMapper alloc] initWithRootNamespace:nsURI recommendedPrefix:OX_DEFAULT_NAMESPACE];
}

+ (id)mapperWithRootNamespace:(NSString *)nsURI recommendedPrefix:(NSString *)nsPrefix
{
    return [[OXmlMapper alloc] initWithRootNamespace:nsURI recommendedPrefix:nsPrefix];
}

#pragma mark - utility

- (void)setNSPrefix:(NSString *)nsPrefix forNamespaceURI:(NSString *)nsURI override:(BOOL)overridePrefix
{
    if (_nsByPrefix == nil) {
        _nsByPrefix = [NSMutableDictionary dictionaryWithCapacity:7];
        _nsByURI = [NSMutableDictionary dictionaryWithCapacity:7];
    }
    NSString *existingPrefix = [_nsByURI objectForKey:nsURI];
    if (existingPrefix) {
        if ( ! overridePrefix )
            return;
        [_nsByPrefix removeObjectForKey:existingPrefix];
    }
    NSInteger colonIndex = [nsPrefix rangeOfString:@":"].location;
    NSString *prefix = (colonIndex == NSNotFound) ? nsPrefix : [nsPrefix substringFromIndex:colonIndex+1];  //strip off xmlns:
    if (colonIndex == NSNotFound && [@"xmlns" isEqualToString:prefix]) {
        prefix = OX_DEFAULT_NAMESPACE;      //handle default namespace case
    }
    [_nsByPrefix setObject:nsURI forKey:prefix];
    [_nsByURI setObject:prefix forKey:nsURI];
}


#pragma mark - builder pattern

- (OXmlMapper *)defaultPrefix:(NSString *)nsPrefix forNamespaceURI:(NSString *)nsURI
{
    [self setNSPrefix:nsPrefix forNamespaceURI:nsURI override:NO];
    return self;
}

- (void)addElementMapper:(OXmlElementMapper *)mapper
{
    //setting parent allows ElementMapper to inherit mapper's nsURI, if one is not set explicitly 
    [mapper setValue:self forKey:@"parentMapper"];  //end-run around readonly property: mapper.parentMapper = self;
    if (_elementMappersByNSURI == nil) {
        _elementMappersByNSURI = [NSMutableDictionary dictionaryWithCapacity:9];
    }
    NSMutableDictionary *nsMap = [_elementMappersByNSURI objectForKey:mapper.nsURI];
    if (nsMap == nil) {
        nsMap = [NSMutableDictionary dictionaryWithCapacity:11];
        [_elementMappersByNSURI setObject:nsMap forKey:mapper.nsURI];
    }
    //sanity checks:
    NSString *keyTag = mapper.fromPathLeaf;
    if (keyTag == nil)
        NSAssert(NO, @"%@ -> %@ has no fromPath", NSStringFromClass(mapper.fromType.type), NSStringFromClass(mapper.toType.type));
    if ([mapper.xpath hasLeafWildcard]) {
        OXmlElementMapper *lastWildcard = [nsMap objectForKey:@"*"];
        mapper.next = lastWildcard;
        [nsMap setObject:mapper forKey:@"*"];
    } else {
        OXmlElementMapper *existingMapper = [nsMap objectForKey:keyTag];
        if (existingMapper)
            mapper.next = existingMapper;   //link mappers pointing to the same tag
        [nsMap setObject:mapper forKey:keyTag];
    }
    if ([ OX_ROOT_PATH isEqualToString:mapper.fromPathRoot]) {
        _rootMapper = mapper;
    }
    [_mappersIndexedByClass setObject:mapper forKey:NSStringFromClass(mapper.toType.type)]; //reverse mappings
}

- (OXmlMapper *)elements:(NSArray *)elements
{
    _elementMappersByNSURI = [NSMutableDictionary dictionaryWithCapacity:[elements count]];
    _mappersIndexedByClass = [NSMutableDictionary dictionaryWithCapacity:[elements count]];
    for(OXmlElementMapper *mapper in elements) {
        [self addElementMapper:mapper];
    }
    //append wildcard matches to linked list
    for(NSMutableDictionary *nsMap in [_elementMappersByNSURI allValues]) {
        for(OXmlElementMapper *mapper in [nsMap allValues]) {
            OXmlElementMapper *last = mapper;
            while ((last.next)) {
                last = last.next;
            }
            last.next = [nsMap objectForKey:@"*"];  //append wildcard mappers to end of the chain
        }
    }
    return self;
}


#pragma mark - lookup utility

- (OXmlElementMapper *)mapperFromPathStack:(NSArray *)stack nsPrefix:(NSString *)nsPrefix
{
    NSDictionary *singleMapper = nsPrefix ? [_elementMappersByNSURI objectForKey:nsPrefix] : nil;
    NSArray *nsList = (singleMapper == nil) ? [_elementMappersByNSURI allValues] : ( singleMapper ? @[ singleMapper ] : @[]);
    NSString *tag = [stack peek];
    for(NSDictionary *mapperNS in nsList) {
        OXmlElementMapper *mapper = [mapperNS objectForKey:tag];
        while (mapper) {
            if ([mapper.xpath matches:stack])
                return mapper;
            mapper = mapper.next;
        }
    }
    return nil;
}

#pragma mark - lookup

- (OXmlElementMapper *)matchElement:(OXContext *)context nsPrefix:(NSString *)nsPrefix
{
    return [self mapperFromPathStack:context.pathStack nsPrefix:nsPrefix];
}
- (OXmlElementMapper *)elementMapperForPath:(NSString *)xpath
{
    OXPathLite *xPathLite = [OXPathLite xpath:xpath];
    return [self mapperFromPathStack:xPathLite.tagStack nsPrefix:nil];
}

- (OXmlElementMapper *)elementMapperForClass:(Class)type
{
    NSString *className = NSStringFromClass(type);
    OXmlElementMapper *mapper = [_mappersIndexedByClass objectForKey:className];
    if (mapper == nil) { // && ! [className hasPrefix:@"NS"]
        //build a mapper on-the-fly
        mapper = [OXmlElementMapper elementClass:type];
        if (mapper != nil) {
            [self addElementMapper:mapper];
        }
    }
    if ( ! mapper.isConfigured && _context) {
        [mapper configure:_context];
    }
    return mapper;
}


#pragma mark - configure

- (NSArray *)configure:(OXContext *)context
{
    _context = (OXmlContext *)context;
    NSArray *errors = nil;
    for(NSDictionary *mapperNS in [_elementMappersByNSURI allValues]) {
        for(OXPathMapper *mapper in [mapperNS allValues]) {
            NSArray *subErrors = [mapper configure:context];
            errors = subErrors == nil ? errors : (errors ? [subErrors arrayByAddingObjectsFromArray:errors] : subErrors);
        }
    }
    return errors;
}

- (void)overridePrefix:(NSString *)nsPrefix forNamespaceURI:(NSString *)nsURI
{
    [self setNSPrefix:nsPrefix forNamespaceURI:nsURI override:YES];
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
