/**
 
 OXPathTests.m
 SAXy OX - Object-to-XML mapping library
 
 Test SAXy's subset of xpath features.
 
 Created by Richard Easterling on 1/25/13.
 
 */
#import <SenTestingKit/SenTestingKit.h>
#import "OXPathLite.h"


@interface OXPathTests : SenTestCase
@end

@implementation OXPathTests


- (void)testTokenizerAndMatcher
{
    //parsed test data:
    NSArray *roota = @[@"/", @"a"];
    NSArray *rootb = @[@"/", @"b"];
    NSArray *ab = @[@"a", @"b"];
    NSArray *ad = @[@"a", @"d"];
    NSArray *abcd = @[@"a", @"b", @"c", @"d"];
    NSArray *rootab = @[@"/", @"a", @"b"];
    NSArray *rootcb = @[@"/", @"c", @"b"];
    NSArray *rootad = @[@"/", @"a", @"d"];
    NSArray *rootabcd = @[@"/", @"a", @"b", @"c", @"d"];
    NSArray *abtext = @[@"a", @"b", @"text()"];
    NSArray *xyb = @[@"x", @"y", @"b"];
    
    OXPathLite *wildcard = [OXPathLite xpath:@"*"];
    STAssertEquals((NSInteger)OXAnyPathType, [[wildcard.tagTypeStack objectAtIndex:0] integerValue], @"OXAnyPathType");
    STAssertEqualObjects(@"*", [wildcard.tagStack objectAtIndex:0], @"wildcard");
    NSAssert([wildcard matches:[NSMutableArray arrayWithArray:@[@"anything"]]], @"wildcard");
    
    OXPathLite *attribute = [OXPathLite xpath:@"@attribute"]; // note the '@'
    STAssertEquals((NSInteger)OXAttributePathType, [[attribute.tagTypeStack objectAtIndex:0] integerValue], @"OXAttributePathType");
    STAssertEqualObjects(@"attribute", [attribute.tagStack objectAtIndex:0], @"attribute");
    NSAssert([attribute matches:[NSMutableArray arrayWithArray:@[@"attribute"]]], @"attribute");
    
    OXPathLite *text = [OXPathLite xpath:@"text()"];
    STAssertEquals((NSInteger)OXTextPathType, [[text.tagTypeStack objectAtIndex:0] integerValue], @"OXTextPathType");
    STAssertEqualObjects(@".", [text.tagStack objectAtIndex:0], @"text");
    NSAssert([text matches:[NSMutableArray arrayWithArray:@[@"element"]]], @"text");
    
    OXPathLite *element2 = [OXPathLite xpath:@"a/b"];
    NSUInteger abCount = [element2.tagStack count];
    STAssertEquals((NSUInteger)2, abCount, @"count == 2");
    STAssertEquals((NSInteger)OXElementPathType, [[element2.tagTypeStack objectAtIndex:1] integerValue], @"OXElementPathType");
    STAssertEqualObjects(@"b", [element2.tagStack objectAtIndex:1], @"element");
    NSAssert([element2 matches:ab], @"a/b");
    NSAssert([element2 matches:rootab], @"a/b");
    
    OXPathLite *element1 = [OXPathLite xpath:@"/a"];
    STAssertEquals((NSInteger)OXElementPathType, [[element1.tagTypeStack objectAtIndex:1] integerValue], @"OXElementPathType");
    STAssertEqualObjects(@"a", [element1.tagStack objectAtIndex:1], @"element");
    NSAssert([element1 matches:roota], @"/a");
    
    OXPathLite *element = [OXPathLite xpath:@"element"];
    STAssertEquals((NSInteger)OXElementPathType, [[element.tagTypeStack objectAtIndex:0] integerValue], @"OXElementPathType");
    STAssertEqualObjects(@"element", [element.tagStack objectAtIndex:0], @"element");
    NSAssert([element matches:@[@"element"]], @"element");
    
    OXPathLite *root = [OXPathLite xpath:@"/"];
    STAssertEquals((NSInteger)OXRootPathType, [[root.tagTypeStack objectAtIndex:0] integerValue], @"OXRootPathType");
    STAssertEqualObjects(@"/", [root.tagStack objectAtIndex:0], @"/");
    NSAssert([root matches:@[@"/"]], @"root");
    
    OXPathLite *dwildcard = [OXPathLite xpath:@"**"];
    STAssertEquals((NSInteger)OXAnyAnyPathType, [[dwildcard.tagTypeStack objectAtIndex:0] integerValue], @"OXAttributePathType **");
    STAssertEqualObjects(@"**", [dwildcard.tagStack objectAtIndex:0], @"dwildcard");
    NSAssert([dwildcard matches:@[@"dwildcard"]], @"dwildcard");
    
    OXPathLite *dwildcard7 = [OXPathLite xpath:@"*/b"];
    STAssertTrue([dwildcard7 matches:ab], @"a/b - match anything first element");
    STAssertFalse([dwildcard7 matches:rootb], @"/b - must be a first element");
    
    OXPathLite *dwildcard6 = [OXPathLite xpath:@"/a/**/d"];
    STAssertTrue([dwildcard6 matches:rootabcd], @"/a/b/c/d - match anything between a and d");
    STAssertTrue([dwildcard6 matches:rootad], @"/a/d - match nothing (zero or more) between a and d");
    STAssertFalse([dwildcard6 matches:abcd], @"a/b/c/d - no root");
    STAssertFalse([dwildcard6 matches:ad], @"a/d - no root");
    
    OXPathLite *dwildcard5 = [OXPathLite xpath:@"a/**/d"];
    STAssertTrue([dwildcard5 matches:abcd], @"a/b/c/d");
    STAssertTrue([dwildcard5 matches:ad], @"a/d");
    STAssertTrue([dwildcard5 matches:rootabcd], @"/a/b/c/d");
    STAssertTrue([dwildcard5 matches:rootad], @"/a/d");
    
    OXPathLite *swildcard4 = [OXPathLite xpath:@"/*/b"];
    STAssertFalse([swildcard4 matches:ab], @"a/b - no root");
    STAssertFalse([swildcard4 matches:xyb], @"x/y/b - no root");
    STAssertFalse([swildcard4 matches:rootad], @"/a/d - fails on leaf node");
    STAssertTrue([swildcard4 matches:rootab], @"/a/b - matches single wildcard");
    STAssertTrue([swildcard4 matches:rootcb], @"/c/b - matches single wildcard");
    
    OXPathLite *dwildcard4 = [OXPathLite xpath:@"a/b/*/d"];
    STAssertFalse([dwildcard4 matches:ab], @"a/b");
    STAssertTrue([dwildcard4 matches:abcd], @"a/b/c/d");
    STAssertTrue([dwildcard4 matches:rootabcd], @"/a/b/c/d");
    STAssertFalse([dwildcard4 matches:rootad], @"/a/d");
    
    OXPathLite *dwildcard3 = [OXPathLite xpath:@"a/b/**"];
    STAssertFalse([dwildcard3 matches:@[@"a"]], @"//");
    NSAssert([dwildcard3 matches:ab], @"//");
    NSAssert([dwildcard3 matches:abtext], @"//");
    
    OXPathLite *dwildcard2 = [OXPathLite xpath:@"//"];
    STAssertEquals((NSInteger)OXAnyAnyPathType, [[dwildcard2.tagTypeStack objectAtIndex:0] integerValue], @"OXAnyAnyPathType //");
    STAssertEqualObjects(@"**", [dwildcard2.tagStack objectAtIndex:0], @"//");
    NSAssert([dwildcard2 matches:@[@"a"]], @"//");
    NSAssert([dwildcard2 matches:ab], @"//");
    NSAssert([dwildcard2 matches:abtext], @"//");
    
    
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
