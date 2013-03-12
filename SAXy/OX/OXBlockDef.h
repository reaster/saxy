/**

  OXBlockDef.h
  SAXy OX - Object-to-XML mapping library

  Common OX block funciton typedefs.  Most of these are used in the OXPathMapper class.

  Created by Richard Easterling on 1/28/13.

 */
#import <Foundation/Foundation.h>
@class OXContext;
@class OXPathMapper;


typedef id (^OXFactoryBlock)(NSString *path, OXContext *ctx);

typedef void (^OXSetterBlock)(NSString *path, id value, id target, OXContext *ctx);
typedef id (^OXGetterBlock)(NSString *path, id source, OXContext *ctx);

typedef id<NSFastEnumeration> (^OXEnumerationBlock)(id container, OXContext *ctx);

typedef id (^OXTransformBlock)(id source, OXContext *ctx);

typedef id (^OXForEachPathMapperBlock)(OXPathMapper *mapper);

typedef void (^OCPropertyMetadataBlock)(NSString *propertyName, Class propertyClass, const char *attributes);

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

