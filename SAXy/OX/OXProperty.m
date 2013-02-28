//
//  OXProperty.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 2/10/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import "OXProperty.h"


@implementation OXProperty

- (id)initProperty:(NSString *)name type:(OXType *)type
{
    if (self = [super init]) {
        _name = name;
        _type = type;
    }
    return self;
}

+ (id)property:(NSString *)name type:(OXType *)type
{
    return [[OXProperty alloc] initProperty:name type:type];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"@property %@ %@;", _type, _name];
}

@end
