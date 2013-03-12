//
//  OXmlElementMapper.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/29/13.
//

#import "OXmlElementMapper.h"
#import "OXmlContext.h"
#import "OXComplexMapper.h"
#import "OXProperty.h"
#import "OXmlMapper.h"
#import "OXUtil.h"


////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - internal class
////////////////////////////////////////////////////////////////////////////////////////

@interface OXmlNamespace : NSObject
@property(strong,nonatomic,readonly)NSString *nsURI;
@property(strong,nonatomic,readonly)NSMutableDictionary *attributeMap;
@property(strong,nonatomic,readonly)NSMutableDictionary *elementMap;
@property(weak,nonatomic,readwrite)OXmlNamespace *next;

+ (id)namespaceURI:(NSString *)nsURI;
@end

@implementation OXmlNamespace

@synthesize nsURI = _nsURI;

- (id)initNamespaceURI:(NSString *)nsURI
{
    if (self = [super init]) {
        _nsURI = nsURI;
        _attributeMap = [NSMutableDictionary dictionary];
        _elementMap = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (id)namespaceURI:(NSString *)nsURI
{
    return [[OXmlNamespace alloc] initNamespaceURI:nsURI];
}
@end

////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - public class
////////////////////////////////////////////////////////////////////////////////////////

@interface OXmlElementMapper ()
- (void)categorizePropertiesByTag;
@end

@implementation OXmlElementMapper
{
    NSMutableDictionary *_namespaceMap;
    NSDictionary *_attributeMapByTag;
    NSDictionary *_elementMapByTag;
    OXmlXPathMapper *_bodyMapper;
    OXmlXPathMapper *_wildcardMapper;
    NSString *_pathRoot;
    NSString *_pathLeaf;
    OXPathLite *_xpath;
    NSDictionary *_elementMapByProperty;
    NSDictionary *_attributeMapByProperty;
    NSString *_nsURI;
    NSString *_nsPrefix;
    NSString *_tempBuilderNSURI;            //only used by builder, not used at runtime
}


#pragma mark - constructors


- (id)initElement:(NSString *)xpath toClass:(Class)type nsURI:(NSString *)nsURI
{
    if (self = [super initMapperToClass:type toPath:nil fromClass:nil fromPath:xpath]) {
        if (xpath) {
            _xpath = [OXPathLite xpath:xpath];
        }
        _namespaceMap = [NSMutableDictionary dictionary];
        _nsURI = nsURI;
    }
    return self;
}

+ (id)elementClass:(Class)type
{
    return [[OXmlElementMapper alloc] initElement:OX_ANONYMOUS_XPATH toClass:type nsURI:nil];
}

+ (id)elementClass:(Class)type nsURI:(NSString *)nsURI
{
    return [[OXmlElementMapper alloc] initElement:OX_ANONYMOUS_XPATH toClass:type nsURI:nsURI];
}

+ (id)element:(NSString *)xpath toClass:(Class)type;
{
    return [[OXmlElementMapper alloc] initElement:xpath toClass:type nsURI:nil];
}

+ (id)root
{
    return [[OXmlElementMapper alloc] initElement:OX_ROOT_PATH toClass:[OXmlContext class] nsURI:nil];
}

+ (id)rootXPath:(NSString *)xpath nsURI:(NSString *)nsURI
{
    OXmlElementMapper *rootMapper = [[OXmlElementMapper alloc] initElement:xpath toClass:[OXmlContext class] nsURI:nsURI];
    NSAssert1([xpath hasPrefix:OX_ROOT_PATH], @"root element xpath must start with root node (/): %@", xpath);
    return rootMapper;
}

+ (id)rootXPath:(NSString *)xpath type:(Class)toType nsURI:(NSString *)nsURI
{
    OXPathLite *path = [OXPathLite xpath:xpath];  //split root path into root and leaf segments:
    NSString *leafPath = path.pathLeaf;
    NSString *rootPath = [xpath substringToIndex:[xpath length] - [leafPath length]];
    return [[OXmlElementMapper rootXPath:rootPath nsURI:nsURI]
            xpath:leafPath property:@"result" type:toType];
}

+ (id)rootXPath:(NSString *)xpath type:(Class)toType
{
    return [OXmlElementMapper rootXPath:xpath type:toType nsURI:nil];
}

+ (id)rootXPath:(NSString *)xpath toMany:(Class)toType nsURI:(NSString *)nsURI
{
    OXPathLite *path = [OXPathLite xpath:xpath];  //split root path into root and leaf segments:
    NSString *leafPath = path.pathLeaf;
    NSString *rootPath = [xpath substringToIndex:[xpath length] - [leafPath length]];
    return [[OXmlElementMapper rootXPath:rootPath nsURI:nsURI]
            xpath:leafPath toMany:toType property:@"result"];
}

+ (id)rootXPath:(NSString *)xpath toMany:(Class)toType
{
    return [OXmlElementMapper rootXPath:xpath toMany:toType nsURI:nil];
}

#pragma mark - utilities

- (BOOL)isRootElement
{
    return [self.toType.type isSubclassOfClass:[OXContext class]];
}

#pragma mark - properties


@dynamic nsPrefix;
- (NSString *)nsPrefix          //if not specified, lookup using nsURI
{
    if (_nsPrefix == nil) {
        NSString *nsURI = self.nsURI;
        OXmlMapper *mapper = _parentMapper;
        _nsPrefix = [mapper.nsByURI objectForKey:nsURI];
    }
    return _nsPrefix;
}
- (void)setNsPrefix:(NSString *)nsPrefix
{
    _nsPrefix = nsPrefix;
}

@dynamic nsURI;
- (NSString *)nsURI //if not specified, lookup OXmlMapper nsURI. if still nil, set to OX_DEFAULT_NAMESPACE
{
    if (_nsURI == nil) {
        if (_parentMapper == nil)
            NSAssert1(NO, @"OXmlElementMapper 'nsURI' property can't be accessed if parentMapper is not set in %@", self);
        _nsURI = _parentMapper.nsURI;
//        if (_nsURI == nil) {
//            //_nsURI = OX_DEFAULT_NAMESPACE;
//            NSLog(@"no namespace");
//        }
    }
    return _nsURI;
}
- (void)setNsURI:(NSString *)nsURI
{
    _nsURI = nsURI;
}

@dynamic xpath;
- (OXPathLite *)xpath
{
    if (_xpath == nil) {
        _xpath = [OXPathLite xpath:self.fromPath];
    }
    return _xpath;
}

@dynamic fromPathLeaf; //override to apply to xpath
- (NSString *)fromPathLeaf
{
    if (_pathLeaf == nil) {
        _pathLeaf = _xpath.pathLeaf;
    }
    return _pathLeaf;}

@dynamic fromPathRoot; //override to apply to xpath
- (NSString *)fromPathRoot
{
    if (_pathRoot == nil) {
        _pathRoot = _xpath.pathRoot;
    }
    return _pathRoot;
}

//@dynamic attributeMap;
//- (NSDictionary *)attributeMap
//{
//    if (_attributeMapByTag == nil) {
//        [self categorizePropertiesByTag];
//    }
//    return _attributeMapByTag;
//}
//
//@dynamic elementMap;
//- (NSDictionary *)elementMap
//{
//    if (_elementMapByTag == nil) {
//        [self categorizePropertiesByTag];
//    }
//    return _elementMapByTag;
//}

@dynamic orderedElementPropertyKeys;
- (NSArray *)orderedElementPropertyKeys
{
    if (_elementMapByProperty == nil) {
        [self categorizePropertiesByTag];
    }
    const int count = [_elementMapByProperty count];
    if (count > 0) {
        NSMutableArray *keys = [NSMutableArray arrayWithCapacity:count];
        for(OXmlXPathMapper *prop in self.pathMappers) {
            if (prop.xmlType == OX_XML_ELEMENT) {
                [keys addObject:prop.toPathLeaf];
            }
        }
        return keys;
    } else {
        return nil;
    }
}

@dynamic orderedAttributePropertyKeys;
- (NSArray *)orderedAttributePropertyKeys
{
    if (_attributeMapByProperty == nil) {
        [self categorizePropertiesByTag];
    }
    const int count = [_attributeMapByProperty count];
    if (count > 0) {
        NSMutableArray *keys = [NSMutableArray arrayWithCapacity:count];
        for(OXmlXPathMapper *prop in self.pathMappers) {
            if (prop.xmlType == OX_XML_ATTRIBUTE) {
                [keys addObject:prop.toPathLeaf];
            }
        }
        return keys;
    } else {
        return nil;
    }
}

@dynamic bodyMapper;
- (OXmlXPathMapper *)bodyMapper
{
    if (_elementMapByTag == nil) {
        [self categorizePropertiesByTag];
    }
    return _bodyMapper;
}

- (void)categorizePropertiesByTag
{
    NSMutableDictionary *elementsByProperty = [NSMutableDictionary dictionaryWithCapacity:[self.pathMappers count]];
    NSMutableDictionary *attributesByProperty = [NSMutableDictionary dictionaryWithCapacity:[self.pathMappers count]];
    for(OXmlXPathMapper *prop in self.pathMappers) {
        NSString *nsURI = prop.nsURI ;
        if (nsURI == nil) {
            nsURI = self.nsURI;
            [prop setValue:nsURI forKey:@"nsURI"];
        }
        OXmlNamespace *ns = [_namespaceMap objectForKey:prop.nsURI];
        if (ns == nil) {
            ns = [OXmlNamespace namespaceURI:nsURI];
            [_namespaceMap setObject:ns forKey:nsURI];
        }
        switch (prop.xmlType) {
            case OX_XML_ATTRIBUTE: {
                if (prop.fromPath == nil)
                    NSAssert1(NO, @"ERROR: nil fromPath for %@", prop);
                [ns.attributeMap setObject:prop forKey:prop.fromPath];
                [attributesByProperty setObject:prop forKey:prop.toPathLeaf];
                break;
            }
            case OX_XML_BODY: {
                _bodyMapper = prop;
                break;
            }
            default: {
                if (prop.fromPath == nil)
                    NSAssert1(NO, @"ERROR: nil fromPath for %@", prop);
                NSString *leaf = prop.fromPathLeaf;
                if ([@"*" isEqualToString:leaf]) {
                    NSAssert2([ns.elementMap objectForKey:@"*"] == nil, @"ERROR: two wildcard element mappings are ambiguous: %@ and %@", NSStringFromClass(_wildcardMapper.toType.type), NSStringFromClass(prop.toType.type));
                    [ns.elementMap setObject:prop forKey:@"*"];
                    [elementsByProperty setObject:prop forKey:prop.toPathLeaf];
                } else {
                    OXmlXPathMapper *existing = [ns.elementMap objectForKey:leaf];
                    [prop setValue:existing forKey:@"next"];    //chain multiple matches, bypass readonly
                    [ns.elementMap setObject:prop forKey:prop.fromPathLeaf];
                    [elementsByProperty setObject:prop forKey:prop.toPathLeaf];
                }
                break;
            }
        }
    }
    NSArray *nsList = [_namespaceMap allValues];
    OXmlNamespace *ns = [nsList lastObject];
    for (OXmlNamespace *nsNext in nsList) {
        ns.next = nsNext;
        ns = nsNext;
    }
    _elementMapByProperty = [elementsByProperty copy];
    _attributeMapByProperty = [attributesByProperty copy];
}

- (void)resetPropertyCategorization
{
    _elementMapByProperty = nil;
    _attributeMapByProperty = nil;
    _bodyMapper = nil;
    [_namespaceMap removeAllObjects];
}

#pragma mark - configure

- (void)configureRootElement:(OXContext *)context       //TODO move to OXComplexMapper?
{
    self.factory = ^(NSString *path, OXContext *ctx){ return context; }; //just return existing context instance
    self.lock = YES;                                                        //don't map other context properties
    NSArray *propertyKeys = self.orderedElementPropertyKeys;
    NSInteger keyCount = propertyKeys ? [propertyKeys count] : 0;
    if (keyCount != 1)
        NSAssert2(NO, @"ERROR: root element (%@) must have a single child element specified, not %d elements", self.fromPath, keyCount);
    OXmlXPathMapper *rootProperty = [self elementMapperByProperty:[propertyKeys objectAtIndex:0]];
    rootProperty.toPath = @"result";                                        //fixed property in OXContext
    OXType *rootType = rootProperty.toType;                                 //verify or assign target type
    if (rootType.type == nil) {
        switch (rootType.typeEnum) {
            case OX_ATOMIC:
            case OX_SCALAR:
            case OX_COMPLEX:
                NSAssert1(NO, @"ERROR: root element type must be specified in %@ mapper", rootProperty);
                break;
            case OX_CONTAINER: {
                Class childType = rootProperty.toType.containerChildType.type;
                if (rootProperty.dictionaryKeyName) {
                    rootProperty.toType = [OXType typeContainer:[NSMutableDictionary class] containing:childType];
                } else {
                    rootProperty.toType = [OXType typeContainer:[NSMutableArray class] containing:childType];
                }
                break;
            }
            case OX_POLYMORPHIC:
            default:
                NSAssert1(NO, @"ERROR: polymorphic root element type not supported (yet) in %@ mapper", rootProperty);
                break;
        }
    }
    [rootProperty configure:context];
}

//override, replacing OXPathMapper with OXmlXPathMapper instances
- (void)addMissingProperties:(OXContext *)context
{
    _tempBuilderNSURI = nil; //switch back to parent element namespace in case switchToNamespaceURI was called
    if ([self isRootElement]) {
        [self configureRootElement:context];
    } else if (!self.lock) {
        NSSet *ignoreSet = [NSSet setWithArray:[self collectForEachPathMapper:^(OXPathMapper *mapper) { return mapper.toPathRoot; }]];
        ignoreSet = [ignoreSet setByAddingObjectsFromSet:self.ignoreProperties];
        NSMutableArray *sortedKeys = [NSMutableArray arrayWithArray:[self.toType.properties allKeys]];
        [sortedKeys sortUsingSelector:@selector(compare:)];
        for(NSString *name in sortedKeys) {
            OXProperty *property = [self.toType.properties objectForKey:name];
            if ( ! [ignoreSet containsObject:name] ) {
                OXmlXPathMapper *simpleMapper = nil;
                switch (property.type.typeEnum) {
                    case OX_CONTAINER: {
                        //unknown source type, polymprphic child type (aka NSObject) and guess that tag is singular form of property name:
                        NSString *singularTag = [OXUtil guessSingularNoun:name];
                        simpleMapper = [[OXmlXPathMapper alloc] initMapperToType:property.type toPath:name fromType:nil fromPath:singularTag];
                        break;
                    }
                    case OX_SCALAR: {
                        //assume NSString fromType, OX_XML_ELEMENT typeEnum and xpath == KVC key
                        simpleMapper = [OXmlXPathMapper xpath:name scalar:property.type.scalarEncoding property:name];
                        break;
                    }
                    case OX_ATOMIC: {
                        //assume NSString fromType, OX_XML_ELEMENT typeEnum and xpath == KVC key
                        simpleMapper = [OXmlXPathMapper xpath:name type:property.type.type property:name];
                        break;
                    }
                    case OX_COMPLEX: {
                        //unknown source type and source path:
                        simpleMapper = [[OXmlXPathMapper alloc] initMapperToType:property.type toPath:name fromType:nil fromPath:name];
                        break;
                    }
                    default:
                        break;
                }
                if (simpleMapper) {
                    [simpleMapper setValue:[NSNumber numberWithUnsignedInt:OX_XML_ELEMENT] forKey:@"xmlType"]; //everything maps to elements by default, bypass readonly
//                    simpleMapper.xmlType = OX_XML_ELEMENT;  //everything maps to elements by default
                    [self addSimpleMapping:simpleMapper];
                }
            }
        }
    }
}

#pragma mark - builder pattern

// OXmlXPathMapper constructors:
//- (id)initXpath:(NSString *)xpath type:(Class)type property:(NSString *)property;
//- (id)initXpath:(NSString *)xpath scalar:(const char *)encodedType property:(NSString *)property;

- (OXmlElementMapper *)addSimpleMapping:(OXmlXPathMapper *)propertyMapping
{
    [super addPathMapper:propertyMapping];
    if (_tempBuilderNSURI != nil) {
        [propertyMapping setValue:_tempBuilderNSURI forKey:@"nsURI"];   //apply custom namespace, override readonly
    }
    [self resetPropertyCategorization];
    return self;
}

- (OXmlElementMapper *)xpathMapper:(OXmlXPathMapper *)xpathMapper
{
    return [self addSimpleMapping:xpathMapper];
}

- (OXmlElementMapper *)switchToNamespaceURI:(NSString *)nsURI
{
    _tempBuilderNSURI = nsURI;
    return self;
}

- (OXmlElementMapper *)tag:(NSString *)tag
{
    return [self addSimpleMapping: [OXmlXPathMapper xpath:tag type:nil property:nil]];
}

- (OXmlElementMapper *)tags:(NSArray *)tags
{
    for(NSString *tag in tags) {
        [self tag:tag];
    }
    return self;
}

- (OXmlElementMapper *)tagMap:(NSDictionary *)tagToPropertyMap
{
    for(NSString *tag in [tagToPropertyMap keyEnumerator]) {
        NSString *property = [tagToPropertyMap objectForKey:tag];
        [self xpath:tag property:property];
    }
    return self;
}

- (OXmlElementMapper *)tag:(NSString *)tag scalarType:(char const *)encodedType
{
    return [self addSimpleMapping: [OXmlXPathMapper xpath:tag scalar:encodedType property:nil]];
}

- (OXmlElementMapper *)tag:(NSString *)tag type:(Class)propertyClass
{
    return [self addSimpleMapping: [OXmlXPathMapper xpath:tag type:propertyClass property:nil]];
}

- (OXmlElementMapper *)ignoreTags:(NSArray *)tags
{
    self.ignoreProperties = [NSSet setWithArray:tags];
    return self;
}

- (OXmlElementMapper *)xpath:(NSString *)xpath
{
    return [self addSimpleMapping: [OXmlXPathMapper xpath:xpath type:nil property:nil]];
}

- (OXmlElementMapper *)xpath:(NSString *)xpath property:(NSString*)property
{
    return [self addSimpleMapping: [OXmlXPathMapper xpath:xpath type:nil property:property]];
}

- (OXmlElementMapper *)xpath:(NSString *)xpath property:(NSString*)property type:(Class)propertyClass
{
    return [self addSimpleMapping: [OXmlXPathMapper xpath:xpath type:propertyClass property:property]];
}

- (OXmlElementMapper *)xpath:(NSString *)xpath property:(NSString*)property scalarType:(char const *)encodedType
{
    return [self addSimpleMapping: [OXmlXPathMapper xpath:xpath scalar:encodedType property:property]];
}

- (OXmlElementMapper *)body:(NSString *)bodyProperty
{
    return [self addSimpleMapping: [OXmlXPathMapper xpath:@"text()" type:nil property:bodyProperty]];
}

- (OXmlElementMapper *)body:(NSString *)bodyProperty scalarType:(char const *)encodedType
{
    return [self addSimpleMapping: [OXmlXPathMapper xpath:@"text()" scalar:encodedType property:bodyProperty]];
}

- (OXmlElementMapper *)attribute:(NSString *)tag
{
    NSString *attr = [OXmlXPathMapper xpathToAttribute:tag];
    return [self addSimpleMapping: [OXmlXPathMapper xpath:attr type:nil property:nil]];
}

- (OXmlElementMapper *)attributes:(NSArray *)tags
{
    for(NSString *tag in tags) {
        [self attribute:tag];
    }
    return self;
}

//- (OXmlElementMapper *)attributeMap:(NSDictionary *)tagToPropertyMap
//{
//    for(NSString *tag in [tagToPropertyMap allKeys]) {
//        NSString *property = [tagToPropertyMap valueForKey:tag];
//        NSString *attr = [OXmlXPathMapper xpathToAttribute:tag];
//        return [self addSimpleMapping: [OXmlXPathMapper xpath:attr type:nil property:property]];
//    }
//    return self;
//}

- (OXmlElementMapper *)attribute:(NSString *)tag property:(NSString*)property
{
    NSString *attr = [OXmlXPathMapper xpathToAttribute:tag];
    return [self addSimpleMapping: [OXmlXPathMapper xpath:attr type:nil property:property]];
}

- (OXmlElementMapper *)attribute:(NSString *)tag property:(NSString*)property type:(Class)propertyClass
{
    NSString *attr = [OXmlXPathMapper xpathToAttribute:tag];
    return [self addSimpleMapping: [OXmlXPathMapper xpath:attr type:propertyClass property:property]];
}

- (OXmlElementMapper *)xpath:(NSString *)xpath toMany:(Class)childType property:(NSString*)property containerType:(Class)containerType
{
    OXType *childOXType = [OXType typeContainer:containerType containing:childType];
    OXmlXPathMapper *mapper = [OXmlXPathMapper xpath:xpath type:containerType property:property];
    mapper.toType = childOXType;
    return [self addSimpleMapping:mapper];
}

- (OXmlElementMapper *)xpath:(NSString *)xpath toMany:(Class)childType property:(NSString*)property
{
    return [self xpath:xpath toMany:childType property:property containerType:nil];
}

- (OXmlElementMapper *)xpath:(NSString *)xpath toMany:(Class)childType
{
    OXmlElementMapper *mapper = [self xpath:xpath toMany:childType property:nil containerType:nil];
    mapper.toPath = mapper.fromPathLeaf;    //guess property name from xpath leaf: a/b/c -> c
    return mapper;
}

- (OXmlElementMapper *)xpath:(NSString *)xpath toMany:(Class)childType property:(NSString*)property dictionaryKey:(NSString *)keyProperty
{
    OXType *containerType = [OXType typeContainer:nil containing:childType];
    OXmlXPathMapper *mapper = [OXmlXPathMapper xpath:xpath type:nil property:property];
    mapper.toType = containerType;
    mapper.dictionaryKeyName = keyProperty;
    return [self addSimpleMapping:mapper];
}

- (OXmlElementMapper *)elementFactory:(OXFactoryBlock)factory
{
    self.factory = factory;
    return self;
}

//- (OXmlElementMapper *)proxyClass:(Class)proxyClass
//{
//    _proxyType = [OXType cachedType:proxyClass];
//    return self;
//}

- (OXmlElementMapper *)lockMapping
{
    self.lock = YES;
    return self;
}

- (OXmlElementMapper *)ignoreProperties:(NSArray *)ignoreProperties
{
    self.ignoreProperties = self.ignoreProperties
        ? [self.ignoreProperties setByAddingObjectsFromArray:ignoreProperties]
        : [NSSet setWithArray:ignoreProperties];
    return self;
}


#pragma mark - lookup


//assume only element matching for now - currently not pushing attributes or text() nodes on context.pathStack
//- (OXPathMapper *)matchPath:(OXContext *)context forNSPrefix:(NSString *)nsPrefix
- (OXmlXPathMapper *)matchPathStack:(NSArray *)tagStack forNSPrefix:(NSString *)nsPrefix
{
    NSString *nsURI = nsPrefix ? [_parentMapper.nsByPrefix objectForKey:nsPrefix] : nil;
    NSString *leaf = [tagStack peek];
    OXmlXPathMapper *mapper = [self elementMapperByTag:leaf nsURI:nsURI];
    while (mapper) {
        const OXPathLite *xpath = mapper.xpath;     //may be nil, xpath only created for complex paths
        if ( xpath ? [xpath matches:tagStack] : [leaf isEqualToString:mapper.fromPath] ) {
            break;
        }
        mapper = mapper.next;                       //iterate through other mappers with same leaf or wildcard
    }
    return mapper;
}

- (OXmlXPathMapper *)elementMapperByProperty:(NSString *)property
{
    if (_elementMapByProperty == nil) {
        [self categorizePropertiesByTag];
    }
    return [_elementMapByProperty objectForKey:property];
}

- (OXmlXPathMapper *)attributeMapperByProperty:(NSString *)property
{
    if (_attributeMapByProperty == nil) {
        [self categorizePropertiesByTag];
    }
    return [_attributeMapByProperty objectForKey:property];
}

- (OXmlXPathMapper *)elementMapperByTag:(NSString *)tag nsURI:(NSString *)nsURI;
{
    if (_elementMapByProperty == nil) {
        [self categorizePropertiesByTag];
    }
    if ([tag hasPrefix:OX_ATTRIBUTE_PREFIX]) {
        tag = [tag substringFromIndex:1];   //strip off attribute prefix ('@')
    }
    if (nsURI == nil)
        nsURI = OX_DEFAULT_NAMESPACE;
    OXmlNamespace *ns = [_namespaceMap objectForKey:nsURI];
    if (ns == nil) {
        ns = [_namespaceMap objectForKey:OX_DEFAULT_NAMESPACE]; //default NS can be applied to any namespace
    }
    OXmlXPathMapper *sm = ns ? [ns.elementMap objectForKey:tag] : nil;
    if (ns != nil && sm == nil) {
        sm = [ns.self.elementMap objectForKey:@"*"];
        if (sm == nil) {
            OXmlNamespace *nextNS = ns.next;
            while (sm==nil && nextNS != ns) {
                sm = [nextNS.elementMap objectForKey:tag];
                nextNS = nextNS.next;
                if (sm == nil) {
                    sm = [ns.elementMap objectForKey:@"*"];
                }
            }
        }
    }
    return sm;
}

- (OXmlXPathMapper *)attributeMapperByTag:(NSString *)tag nsURI:(NSString *)nsURI;
{
    if (_elementMapByProperty == nil) {
        [self categorizePropertiesByTag];
    }
    if ([tag hasPrefix:OX_ATTRIBUTE_PREFIX]) {
        tag = [tag substringFromIndex:1];   //strip off attribute prefix ('@')
    }
    if (nsURI == nil)
        nsURI = OX_DEFAULT_NAMESPACE;
    OXmlNamespace *ns = [_namespaceMap objectForKey:nsURI];
    if (ns == nil) {
        ns = [_namespaceMap objectForKey:OX_DEFAULT_NAMESPACE]; //default NS can be applied to any namespace
    }
    OXmlXPathMapper *sm = ns ? [ns.attributeMap objectForKey:tag] : nil;
    if (ns != nil && sm == nil) {
        OXmlNamespace *nextNS = ns.next;
        while (sm==nil && nextNS != ns) {
            sm = [nextNS.attributeMap objectForKey:tag];
            nextNS = nextNS.next;
        }
    }
    return sm;
}

- (BOOL)hasChildElements
{
    return ([self orderedElementPropertyKeys] != nil);
}

- (BOOL)noChildElements
{
    return ([self orderedElementPropertyKeys] == nil);
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
