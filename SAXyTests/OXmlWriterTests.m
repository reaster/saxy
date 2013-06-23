/**
  OXmlWriterTests.m
  SAXy

  half-baked

  Created by Richard on 3/27/13.
  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.

*/
#import <SenTestingKit/SenTestingKit.h>

#import "OXmlReader.h"
#import "OXmlWriter.h"
#import "OXmlMapper.h"
#import "OXmlElementMapper.h"
#import "OXmlXPathMapper.h"

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


@interface ToonCharacter : NSObject
@property(nonatomic)NSString *firstName;
@property(nonatomic)NSString *lastName;
//@property(nonatomic)ToonCharacter *child;
@end

@implementation ToonCharacter
@end


///////////////////////////////////////////////////////////////////////////////////
#pragma mark - tests
///////////////////////////////////////////////////////////////////////////////////

@interface OXmlWriterTests : SenTestCase  @end

@implementation OXmlWriterTests

- (void)testNestedTags
{
    //STAssertEqualObjects(@"BOOL", [OXUtil scalarString:OX_ENCODED_BOOL], @"BOOL special encoding");
}


- (void)testDuplicateNestedAttributes
{
    NSString *xml = @"<tunes><tune><firstName>Daffy</firstName><lastName>Duck</lastName><child><firstName>Huey</firstName></child></tune></tunes>";
    
    //map 'tune' element to CartoonCharacter class:
    OXmlMapper *mapper = [[OXmlMapper mapper]
                          elements:@[
                          [OXmlElementMapper rootXPath:@"/tunes/tune" toMany:[ToonCharacter class]]
                          ,
                          [[[[OXmlElementMapper elementClass:[ToonCharacter class]]
                            xpath:@"firstName" property:@"firstName"]
                           xpath:@"lastName" property:@"lastName"]
                          xpathMapper:[[[OXmlXPathMapper xpath:@"child/firstName" type:[NSString class]]
                                         setter:^(NSString *path, id name, id target, OXContext *ctx) {
                                         }]
                                        getter:^(NSString *path, id source, OXContext *ctx) {
                                            return (NSString *)nil;
                                        }]
                          ]

                          ]];
    
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];                      //creates a reader based on the mapper
    reader.context.logReaderStack = YES;                                             //'YES' -> log mapping process
    
    NSMutableArray *tunes = [reader readXmlText:xml];                               //reads xml
    ToonCharacter *duck = tunes[0];
    STAssertEqualObjects(@"Daffy", duck.firstName,  @"mapped 'firstName' element to 'firstName' property");
}
@end
