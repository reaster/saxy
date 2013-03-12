/**
 
  OXContext.h
  SAXy OX - Object-to-XML mapping library

  The context provides runtime state to the mapping system in form of various stacks and access
  to the transform instance.  Specificly, it provides:

  1) instanceStack    - target instances created by the mapper starting with the 'root' object
  2) mapperStack      - OXComplexMapper mappers used to instantiate the objects in the instance stack
  3) pathStack        - path to the current instace starting from the 'root'
  4) transform        - OXTransform with registered formatters and default block functions
  5) result           - holds the result ('root' object) of the mapping operation
  6) userData         - for custom mappers that need to pass data between operations at run time

  Paths are abstract at this level and take specific meaning in concreate mapper frameworks (KVC path,
  xpath, etc.). Paths refer to the current position in the object tree your mapping and always have a
  root node (bottom of the stack) and a leaf node (top of the stack).

  It also allows access to a common transform objecct for block assignment, type
  conversion and formatting.  By default, the 'result' property will hold the result of the mapping
  transformation. And lastly, users can store orbitrary data in the userData property.

  Created by Richard Easterling on 1/24/13.

 */
#import "NSMutableArray+OXStack.h"
#import "OXTransform.h"
#import "OXPathMapper.h"


@interface OXContext : NSObject

@property(strong,nonatomic,readonly)NSMutableArray *pathStack;
@property(strong,nonatomic,readonly)NSMutableArray *instanceStack;
@property(strong,nonatomic,readonly)NSMutableArray *mapperStack;
@property(strong,nonatomic,readwrite)OXPathMapper *currentMapper;
@property(strong,nonatomic,readonly)NSMutableDictionary *userData;
@property(strong,nonatomic,readonly)OXTransform *transform;
@property(strong,nonatomic,readonly)NSObject *result;

@property(assign,readwrite,nonatomic) BOOL logReaderStack;              //log tag mapping - helpful debugging tool
@property(assign,readwrite,nonatomic) BOOL logReaderInput;              //log input data - usefull for remote data debugging

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
