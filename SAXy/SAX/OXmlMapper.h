//
//  OXmlMapper.h
//  SAXy OX - Object-to-XML mapping library
//
//  Manages a set of OXmlElementMapper with namespace support.
//
//  Created by Richard Easterling on 1/30/13.
//

#import "OXPathMapper.h"
//#import "OXPathMatcher.h"
#import "OXmlElementMapper.h"
#import "OXmlContext.h"

#define OX_DEFAULT_NAMESPACE @"_xmlns_"

@interface OXmlMapper : NSObject //<OXPathMatcher>

@property(strong,nonatomic,readonly)OXmlElementMapper *rootMapper;  //holds root mapper instance
@property(strong,nonatomic,readonly)NSDictionary *nsByURI;          //lookup table of current nsPrefixes key by nsURIs
@property(strong,nonatomic,readonly)NSDictionary *nsByPrefix;       //lookup table of current nsURIs key by nsPrefixes
@property(strong,nonatomic,readonly)NSString *nsPrefix;             //root or default namespace prefix
@property(strong,nonatomic,readonly)NSString *nsURI;                //root or default namespace URI
@property(assign,nonatomic,readonly)BOOL namespaceAware;            //set internally when namespace processing is active
@property(assign,nonatomic,readonly)BOOL isConfigured;              //flag to track configuration state - triggered lazily

#pragma mark - constructor
+ (id)mapper;
+ (id)mapperWithDefaultNamespace:(NSString *)nsURI;
+ (id)mapperWithRootNamespace:(NSString *)nsURI recommendedPrefix:(NSString *)nsPrefix;

#pragma mark - builder
- (OXmlMapper *)elements:(NSArray *)elements;
- (OXmlMapper *)defaultPrefix:(NSString *)nsPrefix forNamespaceURI:(NSString *)nsURI;

#pragma mark - lookup
- (OXmlElementMapper *)elementMapperForPath:(NSString *)xpath;
- (OXmlElementMapper *)elementMapperForClass:(Class)type;
- (OXmlElementMapper *)matchElement:(OXContext *)context nsPrefix:(NSString *)nsPrefix;

#pragma mark - configure
- (NSArray *)configure:(OXContext *)context;
- (void)overridePrefix:(NSString *)nsPrefix forNamespaceURI:(NSString *)nsURI;

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
