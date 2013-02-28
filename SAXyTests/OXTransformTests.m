//
//  OXUtilTests.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 1/11/13.
//

#import <SenTestingKit/SenTestingKit.h>
#import "OXUtil.h"
#import "OXType.h"
#import "OXmlContext.h"
#import "OXmlXPathMapper.h"
#import "OXProperty.h"
#import "OXTransform.h"
#import <CoreLocation/CLLocation.h>


////////////////////////////////////////////////////////////////////////////////////////
// test classes
////////////////////////////////////////////////////////////////////////////////////////

@interface Email : NSObject
@property(nonatomic) BOOL *isHtmlBody;
//@property(nonatomic) const char *charString; ??
@property(nonatomic) char ch;
@property(nonatomic) unsigned char uch;
@property(nonatomic) unichar unich;
@property(nonatomic) NSInteger integer;
@property(nonatomic) NSUInteger uinteger;
@property(nonatomic) NSTimeInterval interval;
@property(nonatomic) NSURL *url;
@property(nonatomic) NSString *note;
@end

@implementation Email @end

////////////////////////////////////////////////////////////////////////////////////////
// tests
////////////////////////////////////////////////////////////////////////////////////////


@interface OXUtilTests : SenTestCase

@end

@implementation OXUtilTests
{
    OXmlContext *_ctx;
    OXTransform *_transform;
}
- (void)setUp
{
    [super setUp];
    _ctx = [[OXmlContext alloc] init];
    _transform = _ctx.transform;
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}


- (void)testLocaleTransforms
{
    //    NSLog(@"NSLocale systemLocale=%@", [[NSLocale systemLocale] localeIdentifier]);
    //    NSLog(@"NSLocale currentLocale=%@", [[NSLocale currentLocale] localeIdentifier]);
    //    NSLog(@"NSLocale autoupdatingCurrentLocale=%@", [[NSLocale autoupdatingCurrentLocale] localeIdentifier]);
    //
    //    NSLog(@"NSLocale availableLocaleIdentifiers=%@", [[NSLocale availableLocaleIdentifiers] componentsJoinedByString:@", "]);
    //    NSLog(@"NSLocale ISOLanguageCodes=%@", [[NSLocale ISOLanguageCodes] componentsJoinedByString:@", "]);
    //    NSLog(@"NSLocale ISOCountryCodes=%@", [[NSLocale ISOCountryCodes] componentsJoinedByString:@", "]);
    //    NSLog(@"NSLocale ISOCurrencyCodes=%@", [[NSLocale ISOCurrencyCodes] componentsJoinedByString:@", "]);
    //    NSLog(@"NSLocale commonISOCurrencyCodes=%@", [[NSLocale commonISOCurrencyCodes] componentsJoinedByString:@", "]);
    //    NSLog(@"NSLocale preferredLanguages=%@", [[NSLocale preferredLanguages] componentsJoinedByString:@", "]);
    
    NSLocale *US = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    STAssertNotNil(US, @"US");
    NSString *USID = [US localeIdentifier];
    NSLog(@"US=%@", USID);
    OXTransformBlock to = [_transform transformerFrom:[NSString class] to:[NSLocale class]];
    STAssertNotNil(to, @"to");
    OXTransformBlock from = [_transform transformerFrom:[NSLocale class] to:[NSString class]];
    STAssertNotNil(from, @"from");
    NSLocale *current = [NSLocale currentLocale];
    NSString *currentID = [current localeIdentifier];
    STAssertEqualObjects([current localeIdentifier], [to(currentID, _ctx) localeIdentifier], @"to test");
    STAssertEqualObjects(currentID, from(current, nil), @"from test");
}

- (void)testDateFormattingAndTransforms
{
    NSString *dateStr1 = @"2013-02-12T11:18:42-08:00";
    OXTransformBlock to = [_transform transformerFrom:[NSString class] to:[NSDate class]];
    STAssertNotNil(to, @"to");
    OXTransformBlock from = [_transform transformerFrom:[NSDate class] to:[NSString class]];
    STAssertNotNil(from, @"from");
    NSDate *date1 = to(dateStr1, _ctx);
    STAssertNotNil(date1, @"to date");
    NSString *dateStr2 = from(date1, _ctx);
    //STAssertEqualObjects(dateStr1, dateStr2, @"fails with different string representation of same time: 2013-02-12T19:18:42+0000");
    NSDate *date2 = to(dateStr2, _ctx);       //convert it back
    STAssertEqualObjects(date1, date2, @"from test");
}

- (void)testBOOLEncodingTransforms
{
    //test OX_ENCODED_BOOL
    OXTransformBlock toBOOL = [_transform transformerFrom:[NSString class] toScalar:OX_ENCODED_BOOL];
    STAssertNotNil(toBOOL, @"toBOOL");
    STAssertEquals(YES, [toBOOL(@"true", _ctx) boolValue], @"test string-to-BOOL block");

    OXTransformBlock fromBOOL = [_transform transformerScalar:OX_ENCODED_BOOL to:[NSString class]];
    STAssertNotNil(fromBOOL, @"fromBOOL");
    STAssertEqualObjects(@"true", fromBOOL([NSNumber numberWithBool:YES], _ctx), @"test BOOL-to-string transform block");
    
    //test property type encoding:
    OXType *emailMeta = [OXType cachedType:[Email class]];  //gathers property metadata on Email class
    OXProperty *boolyProp = [emailMeta.properties objectForKey:@"isHtmlBody"];
    STAssertNotNil(boolyProp, @"boolyProp");
    STAssertTrue(strcmp("T^c,N,V_isHtmlBody", boolyProp.type.scalarEncoding) == 0, @"property encodedType");
    
    OXTransformBlock toBOOL2 = [_transform transformerFrom:[NSString class] toScalar:boolyProp.type.scalarEncoding];
    STAssertNotNil(toBOOL2, @"toBOOL");
    STAssertEquals(YES, [toBOOL2(@"true", _ctx) boolValue], @"test string-to-BOOL block");
    
    OXTransformBlock fromBOOL2 = [_transform transformerScalar:boolyProp.type.scalarEncoding to:[NSString class]];
    STAssertNotNil(fromBOOL2, @"fromBOOL");
    STAssertEqualObjects(@"true", fromBOOL2([NSNumber numberWithBool:YES], _ctx), @"test BOOL-to-string transform block");

    //[OXUtil propertyInspectionForClass:[Email class] withBlock:^(NSString *propertyName, Class propertyClass, const char *attributes) {
    //    NSLog(@"%@:%@ [%s]", propertyName, NSStringFromClass(propertyClass), attributes);
    //}];
}

- (void)testKeyForEncodedTypeMethod
{
    STAssertEqualObjects(@"^c", [OXTransform keyForEncodedType:"T^c,N,V_isHtmlBody"], @"test keyForEncodedType on BOOL property");
    STAssertEqualObjects(@"^c", [OXTransform keyForEncodedType:"N,V_isHtmlBody,T^c"], @"test keyForEncodedType on BOOL property");
    STAssertEqualObjects(@"^c", [OXTransform keyForEncodedType:OX_ENCODED_BOOL], @"test keyForEncodedType on OX_ENCODED_BOOL const");
    STAssertEqualObjects(@"i", [OXTransform keyForEncodedType:@encode(int)], @"test keyForEncodedType on @encode(int)");
    STAssertEqualObjects(@"Q", [OXTransform keyForEncodedType:@encode(unsigned long long)], @"test keyForEncodedType on @encode(unsigned long long)");
    STAssertEqualObjects(@"d", [OXTransform keyForEncodedType:@encode(double)], @"test keyForEncodedType on @encode(double)");
}

- (void)testXmlEncoding
{
    STAssertNil([OXUtil xmlSafeString:nil], @"nil safe");
    STAssertEqualObjects(@"", [OXUtil xmlSafeString:@""], @"empty safe");
    STAssertEqualObjects(@"1&amp;", [OXUtil xmlSafeString:@"1&"], @"2nd safe");
    NSString *s = [OXUtil xmlSafeString:@"original string"];
    STAssertEquals(s, s, @"original safe");
    STAssertEqualObjects(@"&lt;&#39;&quot;psycho&quot;&gt;&amp;", [OXUtil xmlSafeString:@"<'\"psycho\">&"], @"escaped safe");
}


- (void)testScalarEncodingScheme
{
    //NSLog(@"NSInteger:%s, NSUInteger:%s", @encode(NSInteger), @encode(NSUInteger));
    //“c”, “C”, “s”, “S”, “i”, “I”, “l”, “L”, “q”, “Q”, “f”, and “d”
    NSAssert(strcmp(@encode(BOOL), "c") == 0, @"encode BOOL");
    NSAssert(strcmp(@encode(char), "c") == 0, @"encode char");
    NSAssert(strcmp(@encode(unsigned char), "C") == 0, @"encode unsigned char");
    NSAssert(strcmp(@encode(short), "s") == 0, @"encode short");
    NSAssert(strcmp(@encode(unsigned short), "S") == 0, @"encode unsigned short");
    NSAssert(strcmp(@encode(int), "i") == 0, @"encode int");
    NSAssert(strcmp(@encode(unsigned int), "I") == 0, @"encode unsigned int");
    NSAssert(strcmp(@encode(long), "l") == 0, @"encode long");
    NSAssert(strcmp(@encode(unsigned long), "L") == 0, @"encode unsigned long");
    NSAssert(strcmp(@encode(long long), "q") == 0, @"encode long long");
    NSAssert(strcmp(@encode(unsigned long long), "Q") == 0, @"encode unsigned long long");
    NSAssert(strcmp(@encode(float), "f") == 0, @"encode float");
    NSAssert(strcmp(@encode(double), "d") == 0, @"encode double");
#if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
    //typedef long NSInteger;
    //typedef unsigned long NSUInteger;
    NSAssert(strcmp(@encode(NSInteger), @encode(long)) == 0, @"encode NSInteger on OSX, don't need specific type support");
    NSAssert(strcmp(@encode(NSUInteger), @encode(unsigned long)) == 0, @"encode NSUInteger on OSX, don't need specific type support");
#else
    //typedef int NSInteger;
    //typedef unsigned int NSUInteger;
    NSAssert(strcmp(@encode(NSInteger), @encode(int)) == 0, @"encode NSInteger on iOS, don't need specific type support");
    NSAssert(strcmp(@encode(NSUInteger), @encode(unsigned int)) == 0, @"encode NSUInteger on iOS, don't need specific type support");
#endif
    NSAssert(strcmp(@encode(NSTimeInterval), @encode(double)) == 0, @"NSTimeInterval encoded as double, don't need specific type support");
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
