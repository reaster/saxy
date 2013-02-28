//
//  NSMutableArray+OXStack.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/28/13.
//

#import "NSMutableArray+OXStack.h"

@implementation NSArray (OXStack)

- (id)peek
{
    return [self lastObject];
}

- (id)peekAtIndex:(NSInteger)index
{   // len:2: revIdx:1 -> idx:0
    NSInteger reverseIndex = [self count] - (index + 1);
    return reverseIndex < 0 ? nil : [self objectAtIndex:reverseIndex];
}

- (BOOL)isEmpty
{
    return [self count] == 0;
}

@end


@implementation NSMutableArray (OXStack)

- (void)push:(id)object
{
    [self addObject:object];
}

- (id)pop
{
    id object = [self lastObject];
    [self removeLastObject];
    return object;
}

- (void)clear
{
    [self removeAllObjects];
}

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
