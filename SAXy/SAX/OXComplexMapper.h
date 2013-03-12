/**

  OXComplexMapper.h
  SAXy OX - Object-to-XML mapping library

  This class extends OXPathMapper to support complex types with properties.  It also supports various means
  of limiting what is mapped (ignoreProperties and lock).

  Created by Richard Easterling on 2/10/13.

 */
#import "OXPathMapper.h"
#import "OXBlockDef.h"
@protocol OXContext;

#define OX_ANONYMOUS_XPATH @"_NO_PATH_"    //only map class properties, xpath is done by owning property


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
