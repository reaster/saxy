/**
  OXUtilTests.m
  SAXy

  Created by Richard on 3/4/13.
  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.

*/
#import <SenTestingKit/SenTestingKit.h>
#import "OXUtil.h"
#import "OXType.h"


@interface OXUtilTests : SenTestCase  @end

@implementation OXUtilTests

- (void)testScalarString
{
    STAssertEqualObjects(@"BOOL", [OXUtil scalarString:OX_ENCODED_BOOL], @"BOOL special encoding");
}

- (void)testKnownSimpleType
{
    STAssertTrue([OXUtil knownSimpleType:[NSDecimalNumber class]], @"knownSimpleType: NSDecimalNumber");
    STAssertTrue([OXUtil knownSimpleType:[NSMutableString class]], @"knownSimpleType: NSMutableString");
}

@end
