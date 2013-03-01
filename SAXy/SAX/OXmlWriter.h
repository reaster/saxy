//
//  OXmlWriter.h
//  SAXy OX - Object-to-XML mapping library
//
//  Object-to-XML writer/marshalling class.
//
//  TODO reduce memory footprint by supporting streams
//
//  Created by Richard Easterling on 1/20/13.
//

#import <Foundation/Foundation.h>
#import "OXmlPrinter.h"
#import "OXmlMapper.h"
#import "OXmlContext.h"


#define OC_DEFAULT_XML_HEADER @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"

@interface OXmlWriter : NSObject

@property(strong,nonatomic,readonly)OXContext *context;
@property(strong,nonatomic,readonly)OXmlMapper *mapper;
@property(strong,nonatomic,readwrite)OXmlPrinter *printer;
@property(strong,nonatomic,readwrite)NSString *xmlHeader;
@property(strong,nonatomic,readwrite)NSString *schemaLocation;
@property(strong,nonatomic,readwrite)NSDictionary *rootNodeAttributes;

#pragma mark - writer
- (NSString *)writeXml:(id)object;
- (NSString *)writeXml:(id)object prettyPrint:(BOOL)prettyPrint;
- (NSString *)writeXml:(id)object elementMapper:(OXmlElementMapper *)elementMapper prettyPrint:(BOOL)prettyPrint;
- (void)writeElement:(NSString *)elementName fromObject:(id)object elementMapper:(OXmlElementMapper *)elementMapper;

#pragma mark - constructors
+ (id)writerWithMapper:(OXmlMapper *)mapper;
+ (id)writerWithMapper:(OXmlMapper *)mapper context:(OXContext *)context;


#pragma mark - builder
- (OXmlWriter *)rootAttributes:(NSDictionary *)attributes;

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
