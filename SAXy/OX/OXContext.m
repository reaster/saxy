//
//  OXContext.h
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/24/13.
//

#import "OXContext.h"

@implementation OXContext

- (id)init
{
    if ((self = [super init])) {
        _transform = [[OXTransform alloc] init];
        _userData = [NSMutableDictionary dictionary];
        _pathStack = [[NSMutableArray alloc] init];
        _instanceStack = [[NSMutableArray alloc] init];
        _mapperStack = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)resetUserData
{
    
    [_userData removeAllObjects];
}

- (void)reset
{
    [_pathStack clear];
    [_instanceStack clear];
    [_mapperStack clear];
    _currentMapper = nil;
    _result = nil;
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
