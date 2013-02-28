//
//  OXProperty.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 2/10/13.
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
