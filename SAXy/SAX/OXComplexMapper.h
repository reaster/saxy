//
//  OXComplexMapper.h
//  SAXy OX - Object-to-XML mapping library
//
//  This class extends OXPathMapper to support complex types with properties.  It also supports various means
//  of limiting what is mapped (ignoreProperties and lock).
//
//  Created by Richard Easterling on 2/10/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import "OXPathMapper.h"
#import "OXBlockDef.h"
@protocol OXContext;

@interface OXComplexMapper : OXPathMapper

@property(strong,nonatomic,readonly)NSArray *pathMappers;               //ordered list of mapped properties
@property(strong,nonatomic,readwrite)NSSet *ignoreProperties;           //names of properties to ignore
@property(assign,nonatomic,readwrite)BOOL lock;                         //lock prevents self reflective addition of properties

- (OXComplexMapper *)addPathMapper:(OXPathMapper *)pathMapper;          //adds pathMapper to ordered list and sets parent
- (void)addMissingProperties:(OXContext *)context;                      //uses self reflection to complete mapping, excluding ignoreProperties
- (void)forEachPathMapper:(OXForEachPathMapperBlock)block;              //executes block function for each OXPathMapper in pathMappers collection
- (NSArray *)collectForEachPathMapper:(OXForEachPathMapperBlock)block;  //executes block function for each OXPathMapper returning collecting of results
- (id)findFirstMatch:(OXForEachPathMapperBlock)block;                   //executes block function for each OXPathMapper returning first non-nil result

@end
