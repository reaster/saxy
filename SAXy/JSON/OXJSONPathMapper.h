/**

  OXJSONPathMapper.h
  SAXy

  OXJSONPathMapper puts a JSON face on OXPathMapper with JSON-specific constructors and builders.  This class's purpose is to
  map a single Objective-C property to a JSON data element via a KVC toPath and a KVC fromPath respectively.
 
  OXJSONPathMapper instances are normally constructed and have their block functions set automatically by SAXy.  Use
  this API when you need to set property-specific block functions for custom functionality.
 
  Created by Richard Easterling on 3/4/13.

 */
#import "OXPathMapper.h"

@interface OXJSONPathMapper : OXPathMapper

@property(strong,nonatomic,readwrite)OXJSONPathMapper *next;              //used when multiple mappers use the same toPathLeaf key  - TODO move to OXPathMapper

#pragma mark - constructors
+ (id)path:(NSString *)path;
+ (id)path:(NSString *)path type:(Class)type;
+ (id)path:(NSString *)path property:(NSString *)property;
+ (id)path:(NSString *)path type:(Class)type property:(NSString *)property propertyType:(Class)propertyType;
+ (id)path:(NSString *)path scalar:(const char *)encodedType property:(NSString *)property fromType:(Class)fromType;

#pragma mark - builder
- (OXJSONPathMapper *)factory:(OXFactoryBlock)factory;
- (OXJSONPathMapper *)setter:(OXSetterBlock)setter;
- (OXJSONPathMapper *)getter:(OXGetterBlock)getter;
- (OXJSONPathMapper *)toTransform:(OXTransformBlock)toTransform;
- (OXJSONPathMapper *)fromTransform:(OXTransformBlock)fromTransform;
- (OXJSONPathMapper *)enumerator:(OXEnumerationBlock)enumerator;
- (OXJSONPathMapper *)appender:(OXSetterBlock)appender;
- (OXJSONPathMapper *)isVirtualProperty;
- (OXJSONPathMapper *)formatter:(NSString *)formatterName;

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
