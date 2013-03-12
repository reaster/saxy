/**

  OXJSONMapper.h
  SAXy

  Contains the complete mapping specification for mapping JSON objects to a domain object hierarchy. Each mapper should
  have a single root mapping and zero or more class mapping descriptions.
 
  Created by Richard Easterling on 3/4/13.

*/
#import <Foundation/Foundation.h>
@class OXJSONObjectMapper;
@class OXContext;


@interface OXJSONMapper : NSObject

@property(strong,nonatomic,readonly)OXJSONObjectMapper *rootMapper; //holds root mapper instance
@property(assign,nonatomic,readonly)BOOL isConfigured;              //flag to track configuration state - i.e. when configure: has been called

#pragma mark - constructor
+ (id)mapper;

#pragma mark - builder
- (OXJSONMapper *)objects:(NSArray *)objects;                       //set object mappers

#pragma mark - lookup
- (OXJSONObjectMapper *)objectMapperForPath:(NSString *)path;       //lookup object mapper from JSON path
- (OXJSONObjectMapper *)objectMapperForClass:(Class)type;           //lookup object mapper from it's type
//- (OXJSONObjectMapper *)matchObject:(OXContext *)context;

#pragma mark - configure
- (NSArray *)configure:(OXContext *)context;


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
