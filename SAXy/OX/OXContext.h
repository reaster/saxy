//
//  OXContext.h
//  SAXy OX - Object-to-XML mapping library
//
//  The context provides runtime state to the mapping system in form of various stacks.
//  It also allows access to a common transform objecct for block assignment, type
//  conversion and formatting.  By default, the 'result' property will hold the result of the mapping
//  transformation. And lastly, users can store orbitrary data in the userData property.
//
//  Created by Richard Easterling on 1/24/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

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

@end
