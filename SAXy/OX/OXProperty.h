/**
 
  OXProperty.h
  SAXy OX - Object-to-XML mapping library

  Metadata to describe a property to the mapping sytem, which is simply a (meta) type and a name.

  Created by Richard Easterling on 2/10/13.

 */
#import <Foundation/Foundation.h>
#import "OXType.h"


@interface OXProperty : NSObject

@property(strong,nonatomic,readwrite)NSString *name;
@property(strong,nonatomic,readwrite)OXType *type;

#pragma mark - constructor
+ (id)property:(NSString *)name type:(OXType *)type;

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
