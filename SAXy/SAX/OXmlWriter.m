//
//  OXmlWriter.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/20/13.
//

#import "OXmlWriter.h"
//#import "OXmlelementMapper.h"
#import "OXUtil.h"


#define XML_SCHEMA_INSTANCE_NS_PREFIX @"xmlns:xsi"
#define XML_SCHEMA_INSTANCE_NS_URL @"http://www.w3.org/2001/XMLSchema-instance"
#define XML_SCHEMA_LOCATION_NS_PREFIX @"xsi:schemaLocation"

@implementation OXmlWriter
{
    BOOL _isRoot;
    NSString *_currentNsURI;
}

#pragma mark - constructors

- (id)initWriterWithMapper:(OXmlMapper *)mapper context:(OXContext *)context
{
    if (self = [super init]) {
        _xmlHeader = OC_DEFAULT_XML_HEADER;
        _mapper = mapper;
        _context = context ? context : [[OXmlContext alloc] init];
        _currentNsURI = OX_DEFAULT_NAMESPACE;
        _printer = [[OXmlPrinter alloc] init];
    }
    return self;
}

+ (id)writerWithMapper:(OXmlMapper *)mapper
{
    return [[OXmlWriter alloc] initWriterWithMapper:mapper context:nil];
}

+ (id)writerWithMapper:(OXmlMapper *)mapper context:(OXContext *)context
{
    return [[OXmlWriter alloc] initWriterWithMapper:mapper context:context];
}

#pragma mark - builder

- (OXmlWriter *)rootAttributes:(NSDictionary *)attributes
{
    _rootNodeAttributes = attributes;
    return self;
}


#pragma mark - utilities

//- (OXmlElementMapper *)rootMapperMatchingObject:(id)object
//{
//    return [_mapper rootElementMapperForClass:[object class]];
//}

- (NSArray *)attributesFromObject:(id)object mapping:(OXmlElementMapper *)elementMapper includeRootAttributes:(BOOL)isRoot
{
    NSMutableArray *attrList = nil;
    if (elementMapper) {
        for(NSString *key in [elementMapper orderedAttributePropertyKeys]) {
            OXmlXPathMapper *propertyMapper = [elementMapper attributeMapperByProperty:key];
            _context.currentMapper = propertyMapper;
            NSString *value = propertyMapper ? propertyMapper.getter(propertyMapper.toPath, object, _context) : nil;
            if (value) {
                if (!attrList) attrList = [NSMutableArray array];
                NSString *nsPrefix = nil;
                NSString *nsURI = propertyMapper.nsURI;
                if ( ! [nsURI isEqualToString:OX_DEFAULT_NAMESPACE] && ! [nsURI isEqualToString:_currentNsURI] ) {
                    nsPrefix = [_mapper.nsByURI objectForKey:nsURI];
                }
                NSString *tag = propertyMapper.fromPathLeaf;
                NSString *name = nsPrefix ? [NSString stringWithFormat:@"%@:%@", nsPrefix, tag] : tag;
                [attrList addObject:name];
                [attrList addObject:value];
            }
        }
    }
    if (isRoot) {
        //list _rootNodeAttributes first
        if (_rootNodeAttributes) {
            for(NSString *key in [_rootNodeAttributes keyEnumerator]) {
                if (!attrList) attrList = [NSMutableArray array];
                [attrList addObject:key];
                NSString *value = [_rootNodeAttributes valueForKey:key];    //TODO toString transformer
                [attrList addObject:value];
            }
        }
        //then, if present, list default namespace
        if ([_mapper.nsByPrefix objectForKey:OX_DEFAULT_NAMESPACE] && ! [OX_DEFAULT_NAMESPACE isEqualToString:[_mapper.nsByPrefix objectForKey:OX_DEFAULT_NAMESPACE]]) {
            if (!attrList) attrList = [NSMutableArray array];
            [attrList addObject:@"xmlns"];
            [attrList addObject:[_mapper.nsByPrefix objectForKey:OX_DEFAULT_NAMESPACE]];
        }
        //list other namespaces next
        for (NSString *nsPrefixKey in [_mapper.nsByPrefix allKeys]) {
            if (!attrList) attrList = [NSMutableArray array];
            NSString *namespaceURI = [_mapper.nsByPrefix objectForKey:nsPrefixKey];
            if ( ! [nsPrefixKey isEqualToString:OX_DEFAULT_NAMESPACE] && ! [OX_DEFAULT_NAMESPACE isEqualToString:namespaceURI] ) { //don't emitt an uspecified namespace
                NSString *nsPrefix = [NSString stringWithFormat:@"xmlns:%@", nsPrefixKey];
                [attrList addObject:nsPrefix];
                [attrList addObject:namespaceURI];
            }
        }
        if (_schemaLocation) {
            if (!attrList) attrList = [NSMutableArray array];
            [attrList addObject:XML_SCHEMA_LOCATION_NS_PREFIX];
            [attrList addObject:_schemaLocation];
            //if _schemaLocation specified, must also include schema instance namespace (xsi:)
            if ([_mapper.nsByURI objectForKey:XML_SCHEMA_INSTANCE_NS_URL] == nil) {
                [attrList addObject:XML_SCHEMA_INSTANCE_NS_PREFIX];
                [attrList addObject:XML_SCHEMA_INSTANCE_NS_URL];
            }
        }
        _isRoot = NO;
    }
    return attrList;
}


#pragma mark - public

- (void)writeElement:(NSString *)elementName fromObject:(id)object elementMapper:(OXmlElementMapper *)elementMapper
{
    //if no mapper passed in, then get the mapper for the class of the passed in object:
    if (elementMapper == nil) {
        elementMapper = [_mapper elementMapperForClass:[object class]];
    }
    NSAssert2(elementMapper != nil, @"ERROR in writeElement: No elementMapper registered for %@ class for object: %@", NSStringFromClass([object class]), object);

    //only change NS if the element is not a default (non-prefixed) NS and it's not the same as the current NS:
    if ( ! [elementMapper.nsURI isEqualToString:OX_DEFAULT_NAMESPACE] && ! [elementMapper.nsURI isEqualToString:_currentNsURI] ) {
        _currentNsURI = [elementMapper.nsURI isEqualToString:OX_DEFAULT_NAMESPACE ] ? _currentNsURI : elementMapper.nsURI;
        _printer.nsPrefix = [_currentNsURI isEqualToString:OX_DEFAULT_NAMESPACE ] ? nil : [_mapper.nsByURI objectForKey:_currentNsURI];
    }
    
    //build tag array, handling the case where multiple-tag xpath is mapped the the current object and ignoring the root '/' tag:
    NSArray *tags = nil;
    if (elementName == nil) {
        elementName = elementMapper.fromPathLeaf;
        tags = elementMapper.xpath.tagStack;
    } else {
        int sepIndex = [OXUtil firstIndexOfChar:'/' inString:elementName];
        tags = sepIndex < 0 ? @[elementName] : [[OXPathLite xpath:elementName] tagStack];
        if ([tags count] > 1) {
            elementName = [tags lastObject];    //set elementName to leaf
        }
    }
    BOOL rootElementSkip = [OX_ROOT_PATH isEqualToString:elementName];
    
    //pre-gather data to avoid emitting empty tags
    NSArray *attributes = [self attributesFromObject:object mapping:elementMapper includeRootAttributes:NO];
    OXmlXPathMapper *bodyMapper = elementMapper.bodyMapper;
    _context.currentMapper = bodyMapper;
    NSString *bodyText = bodyMapper ? bodyMapper.getter(bodyMapper.toPath, object, _context) : nil;
    NSArray *elementPropertyKeys = [elementMapper orderedElementPropertyKeys];
    BOOL isEmptyTag = (attributes == nil && bodyText == nil && elementPropertyKeys == nil);
    
    //print tag stack - have to juggle peramutations of root and element attributes across 1 or more tags
    if (!isEmptyTag || bodyMapper) {
        for (NSString *tag in tags) {
            BOOL isLeaf = [tag isEqualToString:elementName];
            if ([OX_ROOT_PATH isEqualToString:tag]) {
                _isRoot = YES;                   //set flag and skip root element
            } else {
                //_printer.nsPrefix = elementMapper.nsPrefix;
                attributes = [self attributesFromObject:object mapping:(isLeaf ? elementMapper : nil) includeRootAttributes:_isRoot];
                [_printer startTag:tag attributes:attributes close:!isLeaf];
                if (!isLeaf) {                  //indent empty tags
                    [_printer newLine];
                    _printer.indent += 1;
                }
                _isRoot = NO;
            }
        }
    }
    
    //special case: tags that have nil text body are printed as empty tags to distingious nil from empty strings: <tag />
    if (isEmptyTag && bodyMapper) {
        [_printer closeEmptyTag];
        [_printer newLine];
    } else {
        
        //handle tags with content, but no nested elements:
        if ([elementMapper noChildElements]) {
            [_printer elementBody:elementName bodyText:bodyText];
        } else {
            
            //handle tags with child elements:
            if (!rootElementSkip) {
                [_printer closeTag];
                [_printer newLine];
                _printer.indent += 1;
            }
            NSString *saveNsPrefix = _printer.nsPrefix;
            for(NSString *elementKey in elementPropertyKeys) {
                OXmlXPathMapper *pathMapper = [elementMapper elementMapperByProperty:elementKey];
                NSString *childTag = [@"*" isEqualToString:pathMapper.fromPath] ? nil : pathMapper.fromPath;    //TODO wildcard/polymorphic support is half-baked
                _context.currentMapper = pathMapper;
                id childData = pathMapper.getter(pathMapper.toPath, object, _context);
                if (childData) {
                    NSString *mapperNS = pathMapper.nsURI;
                    //BOOL isDefaultNS = mapperNS == nil || [mapperNS isEqualToString:OX_DEFAULT_NAMESPACE];
                    BOOL namespaceChange = ![mapperNS isEqualToString:_currentNsURI];
                    if ( namespaceChange ) {
                        _currentNsURI = pathMapper.nsURI;
                        _printer.nsPrefix = [_currentNsURI isEqualToString:OX_DEFAULT_NAMESPACE ] ? nil : [_mapper.nsByURI objectForKey:_currentNsURI];
//                        _currentNsURI = [pathMapper.nsURI isEqualToString:OX_DEFAULT_NAMESPACE ] ? _currentNsURI : pathMapper.nsURI;
//                        _printer.nsPrefix = [_currentNsURI isEqualToString:OX_DEFAULT_NAMESPACE ] ? nil : [_mapper.nsByURI objectForKey:_currentNsURI];
                    }
                    switch (pathMapper.toType.typeEnum) {
                        case OX_CONTAINER: {  // handle list of child elements:
                            id<NSFastEnumeration> enumeration = pathMapper.enumerator(childData, _context);
                            for(id itemData in enumeration) {
                                switch (pathMapper.toType.containerChildType.typeEnum) {
                                    case OX_COMPLEX: {
                                        [self writeElement:childTag fromObject:itemData elementMapper:nil];
                                        break;
                                    }
                                    case OX_SCALAR:
                                    case OX_ATOMIC: {
                                        NSString *childValue = [itemData isKindOfClass:[NSString class]] ? (NSString *)itemData : [itemData stringValue];
                                        [_printer element:childTag value:childValue];
                                        break;
                                    }
                                    case OX_POLYMORPHIC:
                                    default: {
                                        NSAssert2(NO, @"OXmlWriter does not yet support child typeEnum:%d in container mapper: %@", pathMapper.toType.containerChildType.typeEnum, pathMapper);
                                        break;
                                    }
                                }
                            }
                            break;
                        }
                        case OX_COMPLEX: {  // handle single child element:
                            [self writeElement:pathMapper.fromPath fromObject:childData elementMapper:nil];
                            break;
                        }
                        case OX_SCALAR:     // handle single-value (automic) element:
                        case OX_ATOMIC: {
                            NSString *childValue = [childData isKindOfClass:[NSString class]] ? (NSString *)childData : [childData stringValue];
                            [_printer element:childTag value:childValue];
                            break;
                        }
                        case OX_POLYMORPHIC:
                        default: {
                            NSAssert2(NO, @"OXmlWriter does not yet support typeEnum:%d in mapper: %@", pathMapper.toType.typeEnum, pathMapper);
                            break;
                        }
                    }
                }
            } //for
            _printer.nsPrefix = saveNsPrefix;
            if (!rootElementSkip) {
                _printer.indent -= 1;
                [_printer endTag:elementName indent:YES];
            }
        }
    }
    
    //print one or more close tags:
    if (!isEmptyTag || bodyMapper) {
        for (NSString *tag in [tags reverseObjectEnumerator]) {
            if ( ! [OX_ROOT_PATH isEqualToString:tag] && ! [elementName isEqualToString:tag]) {
                _printer.indent -= 1;
                [_printer endTag:tag indent:YES];
            }
        }
    }
}

- (NSString *)writeXml:(id)object elementMapper:(OXmlElementMapper *)elementMapper prettyPrint:(BOOL)prettyPrint
{
    [_printer reset];
    if (!prettyPrint) {
        _printer.crString = nil;
        _printer.indentString = nil;
    }
    if (_xmlHeader) {
        [_printer appendUnencodedText:_xmlHeader];
        [_printer newLine];
    }
    _isRoot = YES;;
    //set initial namespace URI and prefix:
    _currentNsURI = elementMapper.nsURI;
    _printer.nsPrefix = [_currentNsURI isEqualToString:OX_DEFAULT_NAMESPACE ] ? nil : [_mapper.nsByURI objectForKey:_currentNsURI];
    [self writeElement:nil fromObject:object elementMapper:elementMapper];
    return [_printer.output copy];
}

- (NSString *)writeXml:(id)object prettyPrint:(BOOL)prettyPrint
{
    if (_mapper.rootMapper) {
        OXmlXPathMapper *resultMapper = [_mapper.rootMapper elementMapperByProperty:@"result"];
        NSAssert1(resultMapper != nil, @"ERROR: result property mapping not found in root mapper: %@", _mapper.rootMapper);
        Class expectedRootType = resultMapper.toType.type;
        NSAssert3( [object isKindOfClass:expectedRootType], @"ERROR: writeXml expecting type: %@, not: %@, in root mapper: %@", NSStringFromClass(expectedRootType), NSStringFromClass([object class]), _mapper.rootMapper);
        _context.currentMapper = resultMapper;
        resultMapper.setter(resultMapper.toPath, object, _context, _context);
        return [self writeXml:_context elementMapper:_mapper.rootMapper prettyPrint:prettyPrint];
    } else {
        return [self writeXml:object elementMapper:nil prettyPrint:prettyPrint];
    }
}

- (NSString *)writeXml:(id)object
{
    return [self writeXml:object prettyPrint:YES];
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
