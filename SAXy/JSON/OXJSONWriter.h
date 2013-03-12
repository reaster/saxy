/**

  OXJSONWriter.h
  SAXy

  Given a mapping and a context reads JSON data into domain objects.
 
  Known limitations:
  1) can't write arrays of raw JSON numbers or booleans (works fine if values have quotes)
  2) can't write arrays directly nested in arrays (i.e. [[],[]])
 
  Created by Richard Easterling on 3/8/13.

 */
#import <Foundation/Foundation.h>
#import "OXmlMapper.h"
#import "OXmlContext.h"
@class OXJSONMapper;
@class OXJSONObjectMapper;

@interface OXJSONWriter : NSObject

@property(strong,nonatomic,readonly)OXContext *context;
@property(strong,nonatomic,readonly)OXJSONMapper *mapper;
@property(strong,nonatomic,readonly) NSArray *errors;

#pragma mark - constructors
+ (id)writerWithMapper:(OXJSONMapper *)mapper;
+ (id)writerWithMapper:(OXJSONMapper *)mapper context:(OXContext *)context;

#pragma mark - builder
- (OXJSONWriter *)writingOptions:(NSJSONWritingOptions)writingOptions;

#pragma mark - writer
- (NSString *)writeAsText:(id)object;
- (id)write:(id)object objectMapper:(OXJSONObjectMapper *)objMapper;

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
