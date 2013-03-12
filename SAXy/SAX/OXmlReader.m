//
//  OXmlReader.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/14/13.
//

#import "OXmlReader.h"
#import "OXmlElementMapper.h"
#import "NSMutableArray+OXStack.h"
#import "OXUtil.h"
#if (TARGET_OS_IPHONE)
#import <objc/runtime.h>
#import <objc/message.h>
#endif

@implementation OXmlReader
{
    NSArray *_mappers;
    NSMutableDictionary *_mappersByPrefix;
    NSMutableDictionary *_mappersByNamespace;
    BOOL _logStack;
    BOOL _namespaceAware;
}

#pragma mark - constructor

- (id)initWithMapper:(OXmlMapper *)mapper context:(OXmlContext *)context
{
    if ((self = [super init])) {
        _context = context ? context : [[OXmlContext alloc] init];
        _errors = nil;
        _namespaceAware = NO;   //ignores (strips prefixes) XML namespaces
        _mapper = mapper;
        
    }
    return self;
}

+ (id)readerWithMapper:(OXmlMapper *)xmlMapper context:(OXmlContext *)context;
{
    return [[OXmlReader alloc] initWithMapper:xmlMapper context:context];
}

+ (id)readerWithMapper:(OXmlMapper *)xmlMapper
{
    return [OXmlReader readerWithMapper:xmlMapper context:nil];
}


#pragma mark - utility

- (NSArray *)addError:(NSError *)error
{
    _errors = (_errors == nil) ? [NSArray arrayWithObject:error] : [_errors arrayByAddingObject:error];
    return _errors;
}

- (NSArray *)addErrorMessage:(NSString *)errorMessage
{
    NSError *error = [NSError errorWithDomain:@"com.outsourcecafe.ox" code:99 userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
    return [self addError:error];
}


#pragma mark - XML methods


- (NSString *)removeTagPrefix:(NSString *)qName
{
//    if (_namespaceAware) {
//        return qName;
//    } else {
        int nsIndex = [OXUtil firstIndexOfChar:':' inString:qName];
        return (nsIndex < 0) ? qName : [qName substringFromIndex:nsIndex+1];
//    }
}

- (NSString *)namespacePrefix:(NSString *)qName
{
    if (_namespaceAware) {
        //int nsIndex = [OXUtil firstIndexOfChar:':' inString:qName];
        NSRange range = [qName rangeOfString:@":"];
        return (range.location == NSNotFound) ? nil : [qName substringToIndex:range.location];
    } else {
        return nil;
    }
}

- (void)registerNamespaces:(NSDictionary *)attributes
{
    for (NSString *name in [attributes keyEnumerator]) {
        if ([name hasPrefix:@"xmlns"]) {
            [self.mapper overridePrefix:name forNamespaceURI:[attributes objectForKey:name]];
            _namespaceAware = YES;
        }
    }
}

- (NSString *)startTagAsString:(NSString *)tag attributes:(NSDictionary *)attributes
{
    NSMutableString *xml = [NSMutableString stringWithFormat:@"<%@ ",tag];
    for(id key in [attributes keyEnumerator]) {
        NSString *value = (NSString *)[attributes objectForKey:key];
        [xml appendFormat:@"%@='%@' ",key, value];
    }
    [xml appendString:@">"];
    return xml;
}

- (OXPathMapper *)bestMatchMapper:(NSString *)elementName nsPrefix:(NSString *)nsPrefix
{
    //give priority to mapped properties of elementMappers on the stack:
    OXmlElementMapper *elementMapper = [_context.mapperStack isEmpty] ? nil : [_context.mapperStack peek];
    OXmlXPathMapper *xpathMapper = elementMapper ? [elementMapper matchPathStack:_context.pathStack forNSPrefix:nsPrefix] : nil;
    if (xpathMapper) {
        if (xpathMapper.toType.typeEnum == OX_COMPLEX) {
            Class targetClass = xpathMapper.proxyType ? xpathMapper.proxyType.type : xpathMapper.toType.type;    //proxy support ? swap in proxy mapping
            OXmlElementMapper *elementMapperForClass = [_mapper elementMapperForClass:targetClass];
            if (elementMapperForClass) {
                return elementMapperForClass;
            }
        } else if (xpathMapper.toType.typeEnum == OX_CONTAINER && xpathMapper.toType.containerChildType.typeEnum == OX_COMPLEX) {
            Class targetClass = xpathMapper.proxyType ? xpathMapper.proxyType.type : xpathMapper.toType.containerChildType.type;//proxy support ? swap in proxy mapping
            OXmlElementMapper *elementMapperForClass = [_mapper elementMapperForClass:targetClass];
            if (elementMapperForClass) {
                return elementMapperForClass;
            }
        }
        // TODO fix me: if (xpathMapper != elementMapper.wildcardMapper)
        return xpathMapper;
    }
    //not a property of parent object, find a mapper with matching xpath:
    elementMapper = [_mapper matchElement:_context nsPrefix:nsPrefix];  //iterates through 'next' links to find best match
    return elementMapper;
}

#pragma mark - NSXMLParserDelegate

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    _logStack = _context.logReaderStack;    //set logging flag
    [_context.pathStack push:OX_ROOT_PATH ];
    OXmlElementMapper *mapper = [_mapper matchElement:_context nsPrefix:nil];
    if (mapper && mapper.mapperEnum == OX_COMPLEX_MAPPER) {
        NSObject *targetObj = mapper.factory(OX_ROOT_PATH, _context);// [[objectClass alloc] init];
        [_context.instanceStack push:targetObj];
        [_context.mapperStack push:mapper];
        [_context pushMappingType:OX_SAX_OBJECT_ACTION];
        if (_logStack) NSLog(@"start: %@ - construct/push: %@", [_context tagPath], targetObj);
    } else {
        if (_logStack) NSLog(@"start: %@ - skipping", [_context tagPath]);
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    NSString *docTag = [_context.pathStack peek];
    NSAssert1([OX_ROOT_PATH isEqualToString:docTag], @"ERROR in parserDidEndDocument: bottom of context.pathStack should contain '/', not %@", docTag);
    if (_logStack) NSLog(@"  end: %@ - skipping", [_context tagPath]);
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)tag namespaceURI:(NSString *)nsURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributes
{
    @autoreleasepool {
        @try {
            //reset body text
            [_context clearText];
            if (attributes) {
                [self registerNamespaces:attributes];
            }
            NSRange colon = [tag rangeOfString:@":"];
            NSString *elementName = colon.location == NSNotFound ? tag : [self removeTagPrefix:tag];
            NSString *nsPrefix = colon.location == NSNotFound ? OX_DEFAULT_NAMESPACE : [self namespacePrefix:tag];
            NSString *nsURI = nsPrefix ? [_mapper.nsByPrefix objectForKey:nsPrefix] : nil;
            if (nsURI == nil)
                nsURI = OX_DEFAULT_NAMESPACE;
            //put tag on the stack
            [_context.pathStack push:elementName];
            OXmlElementMapper *parentMapper = [_context.mapperStack peek];
            BOOL skipElement = parentMapper ? [parentMapper.ignoreProperties containsObject:elementName] : NO;
            OXPathMapper *mapper = nil;
            if (!skipElement) {
                mapper = [self bestMatchMapper:elementName nsPrefix:nsPrefix];
                skipElement = (mapper == nil);
            }
            if (skipElement) {
                [_context pushMappingType:OX_SAX_SKIP_ACTION];
                if (_logStack) NSLog(@"start: %@ - skipping", [_context tagPath]);
            } else {
                _context.currentMapper = mapper;    //needed by blocks
                //get parrent object
                NSObject *targetObj = [_context.instanceStack peek];
                if (mapper.mapperEnum == OX_COMPLEX_MAPPER) {
                    //create new instance and push on the stack
                    if ( ! mapper.factory)
                        NSAssert1(NO, @"factory block should never be nil, assignDefaultBlocks:context not being called for tag: %@", elementName);
                    targetObj = mapper.factory(elementName, _context);// [[objectClass alloc] init];
                    [_context.instanceStack push:targetObj];
                    [_context.mapperStack push:mapper];
                    [_context pushMappingType:OX_SAX_OBJECT_ACTION];
                    if (_logStack) NSLog(@"start: %@ - construct/push: %@", [_context tagPath], targetObj);
                    //process attributes
                    for(NSString *attrName in [attributes keyEnumerator]) {
                        if (![attrName hasPrefix:@"xmlns"] ) {
                            colon = [attrName rangeOfString:@":"];
                            NSString *key = colon.location == NSNotFound ? attrName : [self removeTagPrefix:attrName];
                            NSString *value = _context.attributeFilterBlock(key, (NSString *)[attributes objectForKey:attrName]);
                            if (value) {
                                if (mapper) {
                                    NSString *attrNSURI = colon.location == NSNotFound ? nsURI : [_mapper.nsByPrefix objectForKey:[self namespacePrefix:attrName]];
                                    OXmlXPathMapper *attributeMapping = [(OXmlElementMapper *)mapper attributeMapperByTag:key nsURI:attrNSURI];
                                    if (attributeMapping) {
                                        if (_logStack) NSLog(@"start: %@/@%@ - %@.%@ = '%@'", [_context tagPath], key, targetObj, attributeMapping.toPath, value);
                                        _context.currentMapper = attributeMapping;    //needed by blocks
                                        attributeMapping.setter(attributeMapping.toPath, value, targetObj, _context);
                                    } else {
                                        if (_logStack) NSLog(@"start: %@/@%@ ?= '%@' - no mapper found, skipping attribute", [_context tagPath], key, value);
                                    }
                                } else {
                                    if (_logStack) NSLog(@"start: %@/@%@ = '%@' - skipping attribute", [_context tagPath], key, value);
                                    //[self setValueOn:targetObj key:key value:value];
                                }
                            } else {
                                if (_logStack) NSLog(@"start: %@/@%@ = nil - filtered attribute", [_context tagPath], key);
                            }
                        }
                    }
                } else { //mapper.mapperEnum == OX_PATH_MAPPER
                    //assume this is a property value mapping
                    [_context pushMappingType:OX_SAX_VALUE_ACTION];
                    if (_logStack) NSLog(@"start: %@ - property of %@", [_context tagPath], targetObj);                    
                }
            }
        } @catch (NSException *e) {
            NSLog(@"ERROR: %@ XML parser error on tag: %@",NSStringFromClass([self class]), [self startTagAsString:tag attributes:attributes]);
            @throw e;
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)text;
{
    [_context appendText:text];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)tag namespaceURI:(NSString *)nsURI qualifiedName:(NSString *)qName;
{
    @autoreleasepool {
        OXSAXActionEnum mappingType = [_context peekMappingType];
        OXSAXActionEnum parentMappingType = [_context peekMappingTypeAtIndex:1];
        if (mappingType == OX_SAX_SKIP_ACTION) {
            if (_logStack) NSLog(@"  end: %@ - skipping", [_context tagPath]);
        } else if (parentMappingType == OX_SAX_SKIP_ACTION && [_context.instanceStack count] < 2) {
            if (_logStack) NSLog(@"  end: %@ - skipping", [_context tagPath]);
        } else {
            NSRange colon = [tag rangeOfString:@":"];
            NSString *elementName = colon.location == NSNotFound ? tag : [self removeTagPrefix:tag];
            NSString *nsPrefix = colon.location == NSNotFound ? OX_DEFAULT_NAMESPACE : [self namespacePrefix:tag];
            //get object off the top of stack and process according to mapping type
            NSObject *targetObj = [_context.instanceStack peek];
            OXmlElementMapper *elementMapper = [_context.mapperStack peek];
            NSString *parentElement = [_context.pathStack peekAtIndex:1];
            if (elementMapper == nil)
                NSAssert1(elementMapper != nil, @"no OXmlElementMapper found for %@", parentElement);
            if (mappingType == OX_SAX_OBJECT_ACTION) {
                OXmlElementMapper *parentMapper = [_context.mapperStack peekAtIndex:1];
                NSObject *child = targetObj;
                NSObject *parent = [_context.instanceStack peekAtIndex:1];
                //possible text node value
                NSString *bodyText = _context.elementFilterBlock(nil, [_context text]);
                if (bodyText) {
                    OXmlXPathMapper *bodyMapper = [elementMapper bodyMapper];
                    if (bodyMapper) {
                        _context.currentMapper = bodyMapper;
                        bodyMapper.setter(bodyMapper.toPath, bodyText, child, _context);
                        if (_logStack) NSLog(@"  end: %@/text() - %@.%@='%@'", [_context tagPath], child, bodyMapper.toPath, bodyText);
                    } else {
                        if (_logStack) NSLog(@"WARNING: complex element '%@' has text value ('%@') but no body property is defined", elementName, bodyText);
                    }
                }
                OXmlXPathMapper *xpathMapper = parentMapper ? (OXmlXPathMapper *)[parentMapper matchPathStack:_context.pathStack forNSPrefix:nsPrefix] : nil;
                if (xpathMapper) {
                    _context.currentMapper = xpathMapper;
                    if (xpathMapper.toType.typeEnum == OX_CONTAINER) {
                        if (_logStack) NSLog(@"  end: %@ - %@.%@ += '%@'", [_context tagPath], parent, xpathMapper.toPath, child);
                        NSAssert1(xpathMapper.appender != nil, @"appender not set for property: %@", xpathMapper);//TODO remove me!!
                        xpathMapper.appender(xpathMapper.toPath, child, parent, _context);
                    } else {
                        if (_logStack) NSLog(@"  end: %@ - %@.%@='%@'", [_context tagPath], parent, xpathMapper.toPath, child);
                        NSAssert1(xpathMapper.setter != nil, @"setter not set for property: %@", xpathMapper);//TODO remove me!!
                        xpathMapper.setter(xpathMapper.toPath, child, parent, _context);
                    }
                } else {
                    NSAssert4(NO, @"ERROR: no registered OXmlXPathMapper: %@ - %@.%@ =' %@'", [_context tagPath], parent, @"?", child);
                }
                [_context.instanceStack pop];
                [_context.mapperStack pop];
            } else if (mappingType == OX_SAX_VALUE_ACTION) {
                //text node value
                NSString *elementText = _context.elementFilterBlock(elementName, [_context text]);
                OXmlXPathMapper *xpathMapper = elementMapper ? (OXmlXPathMapper *)[elementMapper matchPathStack:_context.pathStack forNSPrefix:nsPrefix] : nil;
                if (elementText) {
                    if (xpathMapper) {
                        if (_logStack) NSLog(@"  end: %@ - %@.%@ = '%@'", [_context tagPath], targetObj, xpathMapper.toPath, elementText);
                        _context.currentMapper = xpathMapper;
                        xpathMapper.setter(xpathMapper.toPath, elementText, targetObj, _context);
                    } else {
                        NSAssert4(NO, @"ERROR: no registered OXmlXPathMapper: %@ - %@.%@ =' %@'", [_context tagPath], targetObj, elementName, elementText);
                    }
                }
            }
        }
        [_context clearText]; //reset body string
        [_context popMappingType];
        [_context.pathStack pop];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSString *errMsg = [NSString stringWithFormat:@"XML Parsing Error on %@, Error %i, Description: %@, Line: %i, Column: %i",
                        [self.url absoluteString],
                        [parseError code],
                        [[parser parserError] localizedDescription],
                        [parser lineNumber],
                        [parser columnNumber]];
    [self addErrorMessage:errMsg];
}


#pragma mark - parser

- (id)readXml:(NSXMLParser *)parser
{
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:NO];
    _errors = [self.mapper configure:_context]; //use reflections to create type-specific function blocks
    if (_errors) {
        if (_logStack) {
            for(NSError *error in _errors) {
                NSLog(@"ERROR: %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
            }
        }
        return nil;
    } else {
        _namespaceAware = self.mapper.namespaceAware;
        return [parser parse] ? _context.result : nil;  //if not successful, delegate is informed of error
    }
}

- (id)readXmlData:(NSData *)xmlData fromURL:(NSURL *)aUrl
{
    _url = aUrl;
    if (!xmlData || [xmlData length] == 0)
        return nil;
    if (_context.logReaderInput) NSLog(@"xml: %@", [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding]);
    return [self readXml:[[NSXMLParser alloc] initWithData:xmlData]];
}

- (id)readXmlText:(NSString *)xml
{
    return [self readXmlData:[xml dataUsingEncoding:NSUTF8StringEncoding] fromURL:nil];
}

- (id)readXmlURL:(NSURL *)aUrl
{
    _url = [aUrl isKindOfClass:[NSString class]] ? [NSURL URLWithString: (NSString*)aUrl] : aUrl;
    if (_logStack) NSLog(@"parse URL: %@", [_url absoluteString]);
    return [self readXml:[[NSXMLParser alloc] initWithContentsOfURL:self.url]];
}

- (id)readXmlFile:(NSString *)fileName
{
    NSString *resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
    NSString *filePath = [resourcePath stringByAppendingPathComponent:fileName];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    return [self readXmlData:data fromURL:[NSURL fileURLWithPath:filePath]];
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
