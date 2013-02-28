//
//  OXmlMapper.h
//  SAXy OX - Object-to-XML mapping library
//
//  Manages a set of OXmlElementMapper with namespace support.
//
//  Created by Richard Easterling on 1/30/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import "OXPathMapper.h"
//#import "OXPathMatcher.h"
#import "OXmlElementMapper.h"
#import "OXmlContext.h"

#define OX_DEFAULT_NAMESPACE @"_xmlns_"

@interface OXmlMapper : NSObject //<OXPathMatcher>

@property(strong,nonatomic,readonly)OXmlElementMapper *rootMapper;
@property(strong,nonatomic,readonly)NSDictionary *nsByURI;
@property(strong,nonatomic,readonly)NSDictionary *nsByPrefix;
@property(strong,nonatomic,readonly)NSString *nsPrefix;
@property(strong,nonatomic,readonly)NSString *nsURI;
@property(assign,nonatomic,readonly)BOOL namespaceAware;
@property(strong,nonatomic,readonly)OXmlContext *context;
@property(assign,nonatomic,readonly)BOOL isConfigured;

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
