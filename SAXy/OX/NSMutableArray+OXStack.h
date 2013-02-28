//
//  NSMutableArray+OXStack.h
//  SAXy OX - Object-to-XML mapping library
//
//  Extends NSMutableArray to behave like a stack.
//  Note the indexes for peekAtIndex method are the revere of objectAtIndex method's indexes.
//
//  Created by Richard Easterling on 1/28/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

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
