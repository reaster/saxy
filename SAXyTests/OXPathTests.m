//
//  OXPathTests.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/25/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "OXPathLite.h"


@interface OXPathTests : SenTestCase
@end

@implementation OXPathTests

//OXRootPathType,
//OXElementPathType,
//OXAnyPathType,
//OXAttributePathType,
//OXTextPathType
//OXAnyAnyPathType,

- (void)testTokenizerAndMatcher
{
    NSArray *roota = @[@"/", @"a"];
    NSArray *ab = @[@"a", @"b"];
    NSArray *ad = @[@"a", @"d"];
    NSArray *abcd = @[@"a", @"b", @"c", @"d"];
    NSArray *rootab = @[@"/", @"a", @"b"];
    NSArray *rootad = @[@"/", @"a", @"d"];
    NSArray *rootabcd = @[@"/", @"a", @"b", @"c", @"d"];
    NSArray *abtext = @[@"a", @"b", @"text()"];
    
    OXPathLite *wildcard = [OXPathLite xpath:@"*"];
    STAssertEquals(OXAnyPathType, [[wildcard.tagTypeStack objectAtIndex:0] integerValue], @"OXAnyPathType");
    STAssertEqualObjects(@"*", [wildcard.tagStack objectAtIndex:0], @"wildcard");
    NSAssert([wildcard matches:[NSMutableArray arrayWithArray:@[@"anything"]]], @"wildcard");
    
    OXPathLite *attribute = [OXPathLite xpath:@"@attribute"]; // note the '@'
    STAssertEquals(OXAttributePathType, [[attribute.tagTypeStack objectAtIndex:0] integerValue], @"OXAttributePathType");
    STAssertEqualObjects(@"attribute", [attribute.tagStack objectAtIndex:0], @"attribute");
    NSAssert([attribute matches:[NSMutableArray arrayWithArray:@[@"attribute"]]], @"attribute");
    
    OXPathLite *text = [OXPathLite xpath:@"text()"];
    STAssertEquals(OXTextPathType, [[text.tagTypeStack objectAtIndex:0] integerValue], @"OXTextPathType");
    STAssertEqualObjects(@".", [text.tagStack objectAtIndex:0], @"text");
    NSAssert([text matches:[NSMutableArray arrayWithArray:@[@"element"]]], @"text");
    
    OXPathLite *element2 = [OXPathLite xpath:@"a/b"];
    int abCount = [element2.tagStack count];
    STAssertEquals(2, abCount, @"count == 2");
    STAssertEquals(OXElementPathType, [[element2.tagTypeStack objectAtIndex:1] integerValue], @"OXElementPathType");
    STAssertEqualObjects(@"b", [element2.tagStack objectAtIndex:1], @"element");
    NSAssert([element2 matches:ab], @"a/b");
    NSAssert([element2 matches:rootab], @"a/b");
    
    OXPathLite *element1 = [OXPathLite xpath:@"/a"];
    STAssertEquals(OXElementPathType, [[element1.tagTypeStack objectAtIndex:1] integerValue], @"OXElementPathType");
    STAssertEqualObjects(@"a", [element1.tagStack objectAtIndex:1], @"element");
    NSAssert([element1 matches:roota], @"/a");
    
    OXPathLite *element = [OXPathLite xpath:@"element"];
    STAssertEquals(OXElementPathType, [[element.tagTypeStack objectAtIndex:0] integerValue], @"OXElementPathType");
    STAssertEqualObjects(@"element", [element.tagStack objectAtIndex:0], @"element");
    NSAssert([element matches:@[@"element"]], @"element");
    
    OXPathLite *root = [OXPathLite xpath:@"/"];
    STAssertEquals(OXRootPathType, [[root.tagTypeStack objectAtIndex:0] integerValue], @"OXRootPathType");
    STAssertEqualObjects(@"/", [root.tagStack objectAtIndex:0], @"/");
    NSAssert([root matches:@[@"/"]], @"root");
    
    OXPathLite *dwildcard = [OXPathLite xpath:@"**"];
    STAssertEquals(OXAnyAnyPathType, [[dwildcard.tagTypeStack objectAtIndex:0] integerValue], @"OXAttributePathType **");
    STAssertEqualObjects(@"**", [dwildcard.tagStack objectAtIndex:0], @"dwildcard");
    NSAssert([dwildcard matches:@[@"dwildcard"]], @"dwildcard");
    
    OXPathLite *dwildcard6 = [OXPathLite xpath:@"/a/**/d"];
    STAssertTrue([dwildcard6 matches:rootabcd], @"/a/b/c/d");
    STAssertTrue([dwildcard6 matches:rootad], @"/a/d");
    STAssertTrue([dwildcard6 matches:abcd], @"a/b/c/d");
    STAssertTrue([dwildcard6 matches:ad], @"a/d");
    
    OXPathLite *dwildcard5 = [OXPathLite xpath:@"a/**/d"];
    STAssertTrue([dwildcard5 matches:abcd], @"a/b/c/d");
    STAssertTrue([dwildcard5 matches:ad], @"a/d");
    STAssertTrue([dwildcard5 matches:rootabcd], @"/a/b/c/d");
    STAssertTrue([dwildcard5 matches:rootad], @"/a/d");
    
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
    STAssertEquals(OXAnyAnyPathType, [[dwildcard2.tagTypeStack objectAtIndex:0] integerValue], @"OXAnyAnyPathType //");
    STAssertEqualObjects(@"**", [dwildcard2.tagStack objectAtIndex:0], @"//");
    NSAssert([dwildcard2 matches:@[@"a"]], @"//");
    NSAssert([dwildcard2 matches:ab], @"//");
    NSAssert([dwildcard2 matches:abtext], @"//");
    

}

@end
