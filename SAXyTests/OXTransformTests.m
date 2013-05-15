/**
 
  OXTransformTests.m
  SAXy OX - Object-to-XML mapping library

  Tests type conversion handling in OXTransform class.
 
  Created by Richard Easterling on 1/11/13.

*/
#import <SenTestingKit/SenTestingKit.h>
#import "OXUtil.h"
#import "OXType.h"
#import "OXmlContext.h"
#import "OXmlXPathMapper.h"
#import "OXProperty.h"
#import "OXTransform.h"


////////////////////////////////////////////////////////////////////////////////////////
// test classes
////////////////////////////////////////////////////////////////////////////////////////

@interface OXTransTestObj : NSObject
@property(nonatomic) BOOL isHtmlBody;
//@property(nonatomic) const char *charString; ??
@property(nonatomic) char ch;
@property(nonatomic) unsigned char uch;
@property(nonatomic) unichar unich;
@property(nonatomic) NSInteger integer;
@property(nonatomic) NSUInteger uinteger;
@property(nonatomic) NSTimeInterval interval;
@property(nonatomic) NSURL *url;
@property(nonatomic) NSString *note;
@property(nonatomic) NSNumber *num1;
@property(nonatomic) NSNumber *num2;
@property(nonatomic) NSNumber *num3;

@end

@implementation OXTransTestObj @end

////////////////////////////////////////////////////////////////////////////////////////
// tests
////////////////////////////////////////////////////////////////////////////////////////


@interface OXTransformTests : SenTestCase

@end

@implementation OXTransformTests
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
    OXType *emailMeta = [OXType cachedType:[OXTransTestObj class]];  //gathers property metadata on OXTransTestObj class
    OXProperty *boolyProp = [emailMeta.properties objectForKey:@"isHtmlBody"];
    STAssertNotNil(boolyProp, @"boolyProp");
    STAssertTrue(strcmp("Tc,N,V_isHtmlBody", boolyProp.type.scalarEncoding) == 0, @"property encodedType");
    
    OXTransformBlock toBOOL2 = [_transform transformerFrom:[NSString class] toScalar:boolyProp.type.scalarEncoding];
    STAssertNotNil(toBOOL2, @"toBOOL");
    STAssertEquals(YES, [toBOOL2(@"true", _ctx) boolValue], @"test string-to-BOOL block");
    
    OXTransformBlock fromBOOL2 = [_transform transformerScalar:OX_ENCODED_BOOL to:[NSString class]];
    STAssertNotNil(fromBOOL2, @"fromBOOL");
    STAssertEqualObjects(@"true", fromBOOL2([NSNumber numberWithBool:YES], _ctx), @"test BOOL-to-string transform block");
    
    //[OXUtil propertyInspectionForClass:[OXTransTestObj class] withBlock:^(NSString *propertyName, Class propertyClass, const char *attributes) {
    //    NSLog(@"%@:%@ [%s]", propertyName, NSStringFromClass(propertyClass), attributes);
    //}];
}

- (void)testTimezoneTransforms
{
    //test OX_ENCODED_BOOL
    OXTransformBlock toTimeZone = [_transform transformerFrom:[NSString class] to:[NSTimeZone class]];
    STAssertNotNil(toTimeZone, @"toBOOL");
    STAssertEqualObjects([NSTimeZone timeZoneWithAbbreviation:@"GMT"], toTimeZone(@"GMT", _ctx), @"test string-to-TimeZone block");
    
    OXTransformBlock fromTimeZone = [_transform transformerFrom:[NSTimeZone class] to:[NSString class]];
    STAssertNotNil(fromTimeZone, @"fromTimeZone");
    STAssertEqualObjects(@"GMT", fromTimeZone([NSTimeZone timeZoneWithAbbreviation:@"GMT"], _ctx), @"test TimeZone-to-string transform block");
}

- (void)testString_NSNumberTransforms_whyYouShouldMapYourScalars
{
    OXTransformBlock toNumber = [_transform transformerFrom:[NSString class] to:[NSNumber class]];
    STAssertNotNil(toNumber, @"toNumber");
    //BOOL
    STAssertEquals(YES, [toNumber(@"true", nil) boolValue], @"test string-to-NSNumber:BOOL block");
    STAssertEquals(YES, [toNumber(@"t", nil) boolValue], @"test string-to-NSNumber:BOOL block");
    STAssertEquals(YES, [toNumber(@"y", nil) boolValue], @"test string-to-NSNumber:BOOL block");
    STAssertEquals(YES, [toNumber(@"yes", nil) boolValue], @"test string-to-NSNumber:BOOL block");
    STAssertEquals(NO, [toNumber(@"x", nil) boolValue], @"test string-to-NSNumber:BOOL using anything besides: true, t, yes and y");
    //double
    STAssertEquals(1.1, [toNumber(@"1.1", nil) doubleValue], @"test string-to-NSNumber:double");
    //long long
    STAssertEquals((long long)1, [toNumber(@"1", nil) longLongValue], @"test string-to-NSNumber:long long");
    STAssertEquals((long long)0, [toNumber(@"0", nil) longLongValue], @"test string-to-NSNumber:long long");
    //nil
    STAssertNil(toNumber(nil, nil), @"test nil in, nil out");
    
    OXTransformBlock fromNumber = [_transform transformerFrom:[NSNumber class] to:[NSString class]];
    STAssertNotNil(fromNumber, @"fromNumber");
    //double
    NSNumber *doubleNum = [NSNumber numberWithDouble:33.3];
    NSString *doubleStr = fromNumber(doubleNum, nil);
    STAssertEqualObjects(@"33.3", doubleStr, @"NSNumber:double to string");
    //char
    NSNumber *charNum = [NSNumber numberWithChar:'?'];
    NSString *charStr = fromNumber(charNum, nil);
    STAssertEqualObjects(@"63", charStr, @"NSNumber:char to string - char-ness is not preserved");
    //BOOL
    NSNumber *boolNum = [NSNumber numberWithBool:YES];
    NSString *boolStr = fromNumber(boolNum, nil);
    STAssertEqualObjects(@"1", boolStr, @"NSNumber:BOOO to string - BOOL-ness is not preserved");
}

- (void)testBase64Transform
{
    OXTransformBlock toBase64 = [_transform transformerFrom:[NSData class] to:[NSString class]];
    STAssertNotNil(toBase64, @"toBase64");
    OXTransformBlock fromBase64 = [_transform transformerFrom:[NSString class] to:[NSData class]];
    STAssertNotNil(fromBase64, @"fromBase64");
    
    NSString *string = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 -=`[]\\;',./{}|:<>?\n\t\r~!@#$%^&A*()_+";
    NSData *data = [NSData dataWithBytes:[string UTF8String] length:[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];

    NSString *base64 = toBase64(data, nil);
    NSData *data2 = fromBase64(base64, nil);
    NSString *string2 = [NSString stringWithUTF8String:[data2 bytes]];
    STAssertEqualObjects(string, string2, @"string-base64 round-trip");
}

- (void)testKeyForEncodedTypeMethod
{
    STAssertEqualObjects(@"^c", [OXTransform keyForEncodedType:"T^c,N,V_charPtr"], @"test keyForEncodedType on encoded property");
    STAssertEqualObjects(@"^c", [OXTransform keyForEncodedType:"N,V_charPtr,T^c"], @"test keyForEncodedType on encoded property");
    STAssertEqualObjects(@"?B", [OXTransform keyForEncodedType:OX_ENCODED_BOOL], @"test keyForEncodedType on OX_ENCODED_BOOL const");
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


//- (void)testURLEncoding
//{
//    //OXTransformBlock toNumber = [_transform transformerFrom:[NSString class] to:[NSNumber class]];
//    NSURL *url1 = [NSURL URLWithString:@"http://web.com/x?id=1084&amp;acc=36399"];
//    STAssertEqualObjects([url1 absoluteString], @"http://web.com/x?id=1084&acc=36399", @"url encoding");
//    NSURL *url2 = [NSURL URLWithString:@"http://web.com/x?id=1084&acc=36399"];
//    STAssertNotNil(url2, @"url not nil");
//    STAssertEqualObjects([url2 absoluteString], @"http://web.com/x?id=1084&acc=36399", @"url encoding");
//    NSString *text2 = [url2 absoluteString];
//    STAssertNotNil(text2, @"url not nil");
//}


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
