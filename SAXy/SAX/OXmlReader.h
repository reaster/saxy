//
//  OXmlReader.h
//  SAXy OX - Object-to-XML mapping library
//
//  XML-to-Object unmarshalling class based on NSXMLParser and NSXMLParserDelegate callbacks.
//
//  TODO reduce memory footprint by supporting a true SAX-basd parser (NSXMLParser reads in the whole XML document)
//
//  Created by Richard Easterling on 1/14/13.
//

#import <Foundation/Foundation.h>
#import "OXmlMapper.h"
#import "OXmlContext.h"


@interface OXmlReader : NSObject <NSXMLParserDelegate>

#pragma mark - properties
@property(weak,nonatomic,readonly) OXmlMapper *mapper;
@property(strong,nonatomic,readwrite) NSURL *url;
@property(strong,nonatomic,readonly) NSArray *errors;
//@property(strong,nonatomic,readonly) NSError *parserError;
@property(strong,nonatomic,readonly) OXmlContext *context;

#pragma mark - constructor
+ (id)readerWithMapper:(OXmlMapper *)xmlMapper;
+ (id)readerWithMapper:(OXmlMapper *)xmlMapper context:(OXmlContext *)context;

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

- (id)readXml:(NSXMLParser *)parser;

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
