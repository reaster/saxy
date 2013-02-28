//
//  OXContext.h
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/24/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import "OXContext.h"

@implementation OXContext

- (id)init
{
    if ((self = [super init])) {
        _pathStack = [[NSMutableArray alloc] init];
        _instanceStack = [[NSMutableArray alloc] init];
        _mapperStack = [[NSMutableArray alloc] init];
        _transform = [[OXTransform alloc] init];
        _userData = [NSMutableDictionary dictionary];
    }
    return self;
}

@end
