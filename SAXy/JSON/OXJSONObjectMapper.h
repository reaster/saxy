/**

  OXJSONObjectMapper.h
  SAXy

  OXJSONObjectMapper main purpose is to map domain class properties to JSON data objects.  Each property mapping is encoded in
  a OXJSONPathMapper child instance.  The majority of the builder calls are just convenience methods that build OXJSONPathMapper
  instances.  The last few builder calls are for limiting the object mapping's scope.
 
  Created by Richard Easterling on 3/4/13.

 */
#import "OXComplexMapper.h"
@class OXJSONMapper;
@class OXJSONPathMapper;

@interface OXJSONObjectMapper : OXComplexMapper

#pragma mark - properties
@property(strong,nonatomic,readonly)NSArray *orderedPropertyKeys;           //target properties in declaration order
@property(weak,nonatomic,readonly)OXJSONMapper *parentMapper;               //must be set before calling lookup methods
@property(strong,nonatomic,readwrite)OXJSONObjectMapper *next;              //used when multiple mappers use the same toPathLeaf key - TODO move to OXPathMapper

#pragma mark - constructors
+ (id)root;                                                                 //declare a root mapper with no result path mapper
+ (id)rootClass:(Class)toType;                                              //single-result JSON mapping
+ (id)rootToManyClass:(Class)toType;                                        //list-result JSON mapping (i.e. the result will be a NSArray)
+ (id)objectClass:(Class)toType;                                            //map class properties to JSON object(s)

#pragma mark - builder pattern
- (OXJSONObjectMapper *)path:(NSString *)path;                              //identical to/from paths and NSString JSON type
- (OXJSONObjectMapper *)paths:(NSArray *)paths;                             //array of mappings with identical to/from paths and NSString JSON type
- (OXJSONObjectMapper *)pathMap:(NSDictionary *)pathMap;                    //map to path (key) to from path (value), assume NSString JSON type
- (OXJSONObjectMapper *)path:(NSString *)path scalarType:(char const *)encodedType; //identical to/from paths, NSNumber or scalar property and NSString JSON types
- (OXJSONObjectMapper *)path:(NSString *)path type:(Class)fromType;         //identical to/from paths, with a non-string JSON type (usually NSNumber)
- (OXJSONObjectMapper *)path:(NSString *)path property:(NSString*)property; //unique to/from paths and NSString JSON type
- (OXJSONObjectMapper *)path:(NSString *)path type:(Class)fromType property:(NSString*)property;//unique to/from paths, with a non-string JSON type (usually NSNumber)
- (OXJSONObjectMapper *)path:(NSString *)path type:(Class)fromType property:(NSString*)property propertyType:(Class)toType;//specific paths and types - needed for complex KVC paths
- (OXJSONObjectMapper *)path:(NSString *)path property:(NSString*)property scalarType:(char const *)encodedType;//specific paths, scalar (optional NSNumber) and NSString JSON type
- (OXJSONObjectMapper *)path:(NSString *)path type:(Class)fromType property:(NSString*)property scalarType:(char const *)encodedType;//for scalar properties with NSNumber JSON types
- (OXJSONObjectMapper *)path:(NSString *)path toMany:(Class)childType;      //identical paths with toMany mapping to childType
- (OXJSONObjectMapper *)path:(NSString *)path toMany:(Class)childType property:(NSString*)property;//toMany with unique to/from paths
- (OXJSONObjectMapper *)path:(NSString *)path toMany:(Class)childType property:(NSString*)property containerType:(Class)containerType;  //explicit container type, needed for 'id' property types
- (OXJSONObjectMapper *)path:(NSString *)path toMany:(Class)childType property:(NSString*)property dictionaryKey:(NSString *)keyProperty;   //NSDictionary mapping
- (OXJSONObjectMapper *)pathMapper:(OXJSONPathMapper *)pathMapper;          //allows custom OXJSONPathMapper mappings
- (OXJSONObjectMapper *)objectFactory:(OXFactoryBlock)factory;              //sets the 'factory' block property
- (OXJSONObjectMapper *)ignorePaths:(NSArray *)paths;                       //ignore these JSON paths
- (OXJSONObjectMapper *)ignoreProperties:(NSArray *)ignoreProperties;       //don't map these specific properties
- (OXJSONObjectMapper *)lockMapping;                                        //turn off self-reflective property additions, freezing the mapping specification

#pragma mark - lookup
//- (OXJSONPathMapper *)matchPathStack:(NSArray *)tagStack;
- (OXJSONPathMapper *)objectMapperByPath:(NSString *)path;                  //lookup object mapper using JSON path
- (OXJSONPathMapper *)objectMapperByProperty:(NSString *)property;          //lookup object mapper using KVC path (i.e. property name(s))

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
