//
//  OXmlReader.h
//  SAXy OX - Object-to-XML mapping library
//
//  XML-to-Object unmarshalling class based on NSXMLParser.
//
//  Created by Richard Easterling on 1/14/13.
//

#import <Foundation/Foundation.h>
#import "OXmlMapper.h"
#import "OXmlContext.h"


@interface OXmlReader : NSObject <NSXMLParserDelegate>

#pragma mark - properties
//@property(weak,nonatomic,readwrite) NSArray *mappers;           //array of OXmlMapper's (optionally mapped to namespaces)
@property(weak,nonatomic,readonly) OXmlMapper *mapper;
@property(strong,nonatomic,readwrite) NSURL *url;
@property(strong,nonatomic,readwrite) NSString *error;
@property(strong,nonatomic,readonly) NSError *parserError;
@property(strong,nonatomic,readonly) OXmlContext *context;

#pragma mark - constructor
//- (id)initWithContext:(OXmlContext *)context mapper:OXmlMapper *mapper;
//+ (id)readerWithContext:(OXmlContext *)context mapper:OXmlMapper *mapper;
+ (id)readerWithContext:(OXmlContext *)context mapper:(OXmlMapper *)xmlMapper;
+ (id)readerWithMapper:(OXmlMapper *)xmlMapper;

#pragma mark - parser
// read XML from NSData
// if succesful returns array of result graph.
// If not, returns nil and XML parse error (if any) is available in the error property.
- (id)readXmlText:(NSString *)xml;

// read XML from NSData
// if succesful returns array of result graph.
// If not, returns nil and XML parse error (if any) is available in the error property.
- (id)readXmlData:(NSData *)xmlData fromURL:(NSURL *)url;

// read XML from URL
// if succesful returns array of result graph.  If not, returns nil and XML parse error (if any) is available in the error property.
- (id)readXmlURL:(NSURL *)url;

// read XML from a resource file
- (id)readXmlFile:(NSString *)fileName;

//// used when elements with the same name map to different classes.
//- (void)overrideMapping:(OCTagMapping *)mapping forElement:(NSString *)elementName;

- (id)readXml:(NSXMLParser *)parser;

//#pragma mark - lookup
//- (OXmlMapper *)mapperForNamespace:(NSString *)nsURI;
//- (OXmlMapper *)mapperForNamespacePrefix:(NSString *)nsPrefix;

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
