//
//  NSMutableArray+OXStack.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/28/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
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
