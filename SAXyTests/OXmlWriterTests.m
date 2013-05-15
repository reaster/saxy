/**
  OXmlWriterTests.m
  SAXy

  half-baked

  Created by Richard on 3/27/13.
  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.

*/
#import <SenTestingKit/SenTestingKit.h>

///////////////////////////////////////////////////////////////////////////////////
#pragma mark - test classes
///////////////////////////////////////////////////////////////////////////////////

@interface OXA : NSObject
@property(strong, readonly, nonatomic) NSString *text;
@end
@implementation OXA @end

@interface OXB : NSObject
@property(strong, readonly, nonatomic) NSString *text;
@end
@implementation OXB @end

@interface OXC : NSObject
@property(strong, readonly, nonatomic) OXA *a;
@property(strong, readonly, nonatomic) OXB *b;
@end
@implementation OXC @end

@interface OXD : NSObject
@property(strong, readonly, nonatomic) OXC *c;
@end
@implementation OXD @end


///////////////////////////////////////////////////////////////////////////////////
#pragma mark - tests
///////////////////////////////////////////////////////////////////////////////////

@interface OXmlWriterTests : SenTestCase  @end

@implementation OXmlWriterTests

- (void)testNestedTags
{
    //STAssertEqualObjects(@"BOOL", [OXUtil scalarString:OX_ENCODED_BOOL], @"BOOL special encoding");
}

@end
