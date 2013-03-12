/**

  NSMutableArray+OXStack.h
  SAXy OX - Object-to-XML mapping library

  Extends NSMutableArray to behave like a stack.
  Note the indexes for peekAtIndex method are the revere of objectAtIndex method's indexes.

  Created by Richard Easterling on 1/28/13.

 */
#import <Foundation/Foundation.h>

@interface NSArray (OXStack)

- (id)peek;
- (id)peekAtIndex:(NSInteger)index;     //index is reverse that of objectAtIndex method: arrayIndex = [array count] - (index + 1)
- (BOOL)isEmpty;

@end

@interface NSMutableArray (OXStack)

- (void)push:(id)object;
- (id)pop;
- (void)clear;

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
