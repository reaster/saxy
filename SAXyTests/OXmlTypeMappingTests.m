//
//  XMLTests.m
//  SAXy OX - Object-to-XML mapping library
//
//  Test coverage for types and various mapping configurations supported by SAXy.
//
//  Created by Richard Easterling on 1/14/13.
//
// TODO add support for NSDecimal and test with NSDecimalMaxSize, NSDecimalNoScale
//      add tests with NSIntegerMax, NSIntegerMin, NSUIntegerMax 


#import <SenTestingKit/SenTestingKit.h>

#import "OXType.h"
#import "OXmlReader.h"
#import "OXmlMapper.h"
#import "OXmlElementMapper.h"
#import "OXmlContext.h"
#import "OXmlWriter.h"

///////////////////////////////////////////////////////////////////////////////////
#pragma mark - test objects
///////////////////////////////////////////////////////////////////////////////////

@interface EmailItem : NSObject
@property(copy, readwrite, nonatomic) NSString *title;
@property(copy, readwrite, nonatomic) NSURL *url;
@property(copy, readonly, nonatomic) NSString *type;
@property(copy, readwrite, nonatomic) NSString *note;
@property(copy, readwrite, nonatomic) NSString *address;
- (BOOL)isNotBlank;
- (id)initWithAddress:(NSString *)address;
@end

@implementation EmailItem
- (id)initWithAddress:(NSString *)address
{
    if (self = [super init]) {
        _address = address;
    }
    return self;
}
- (BOOL)isNotBlank { return self.address != nil; }
@end


@interface AddressItem : NSObject
@property(copy, readwrite, nonatomic) NSString *orgunit;
@property(copy, readwrite, nonatomic) NSString *street1;
@property(copy, readwrite, nonatomic) NSString *street2;
@property(copy, readwrite, nonatomic) NSString *boxnumber;
@property(copy, readwrite, nonatomic) NSString *city;
@property(copy, readwrite, nonatomic) NSString *state;
@property(assign, readwrite, nonatomic) int zip;
- (BOOL)isNotBlank;
@end

@implementation AddressItem
- (BOOL)isNotBlank { return (_orgunit || _street1 || _street2 || _boxnumber || _city); }
@end


@interface CommercialItem : NSObject
//common non-scalar types:
@property(copy,readwrite,nonatomic) NSString *name;
@property(strong,readwrite,nonatomic) NSURL *homePage;
@property(strong,readwrite,nonatomic) NSDate *lastUpdated;
@property(strong,readwrite,nonatomic) NSMutableString *notes;
//scalar types:
@property(readwrite,nonatomic) BOOL prospect;
@property(assign,readwrite,nonatomic) char status;
@property(assign,readwrite,nonatomic) short locations;
@property(assign,readwrite,nonatomic) int contactAttemps;
@property(assign,readwrite,nonatomic) long employees;
@property(assign,readwrite,nonatomic) float elevation;
@property(assign,readwrite,nonatomic) double netWorth;
//NSNumber scalar wrapper classes:
@property(strong,readwrite,nonatomic) NSNumber *prospectW;
@property(strong,readwrite,nonatomic) NSNumber *statusW;
@property(strong,readwrite,nonatomic) NSNumber *locationsW;
@property(strong,readwrite,nonatomic) NSNumber *contactAttempsW;
@property(strong,readwrite,nonatomic) NSNumber *employeesW;
@property(strong,readwrite,nonatomic) NSNumber *elevationW;
@property(strong,readwrite,nonatomic) NSNumber *netWorthW;
//TODO add property to test each container type:
//@property(strong,readwrite,nonatomic) NSMutableArray *emails;
//@property(strong,readwrite,nonatomic) NSArray *emails;
//@property(strong,readwrite,nonatomic) NSMutableSet *emails;
//@property(strong,readwrite,nonatomic) NSSet *emails;
@property(strong,readwrite,nonatomic) NSDictionary *emails;
//complex type
@property(strong,readwrite,nonatomic) AddressItem *address;
- (BOOL)isNotBlank;
@end

@implementation CommercialItem
- (BOOL)isNotBlank { return (_name || _emails || _address); }
@end


@interface OXTestContainer : NSObject
@property(strong,readwrite,nonatomic) NSMutableArray *emailMArray;
@property(strong,readwrite,nonatomic) NSArray *emailArray;
@property(strong,readwrite,nonatomic) NSMutableSet *textMSet;
@property(strong,readwrite,nonatomic) NSSet *textSet;
@property(strong,readwrite,nonatomic) NSMutableDictionary *dateMMap;
@property(strong,readwrite,nonatomic) NSDictionary *dateMap;
@end

@implementation OXTestContainer
@end


///////////////////////////////////////////////////////////////////////////////////
#pragma mark - tests
///////////////////////////////////////////////////////////////////////////////////

@interface OXmlReaderTests : SenTestCase  @end

#define NS_URI @"http://OutsourceCafe.com/schema/contacts/1/1"

@implementation OXmlReaderTests
{
    OXmlMapper *_mapper;
    OXmlElementMapper *_root;
    OXmlElementMapper *_email;
    OXmlElementMapper *_orginization;
}

- (void)setUp
{
    [super setUp];

    _root = [OXmlElementMapper rootXPath:@"/contacts/contact/orginization" toMany:[CommercialItem class]];
    
    _email = [[OXmlElementMapper elementClass:[EmailItem class]]
                                tagMap:@{@"text()":@"address", @"@note":@"note", @"@title":@"title", @"@type":@"type", @"@url":@"url"}]
    ;
    _orginization = [[[[[[[[[[[OXmlElementMapper element:@"orginization" toClass:[CommercialItem class]]
                                                tag:@"prospect" scalarType:OX_ENCODED_BOOL]
                                               tag:@"prospectW" scalarType:OX_ENCODED_BOOL]
                                              tag:@"netWorthW" scalarType:@encode(double)]
                                             tag:@"statusW" scalarType:@encode(char)]
                                            tag:@"locationsW" scalarType:@encode(short)]
                                           tag:@"contactAttempsW" scalarType:@encode(int)]
                                          tag:@"employeesW" scalarType:@encode(long)]
                                         tag:@"elevationW" scalarType:@encode(float)]
                                        tag:@"netWorthW" scalarType:@encode(double)]
                                       xpath:@"emails/email" toMany:[EmailItem class] property:@"emails" dictionaryKey:@"type"]
    ;
    _mapper = [[OXmlMapper mapperWithRootNamespace:NS_URI recommendedPrefix:@"c"]
                          elements:@[_root, _orginization, _email]]
    ;
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void)testMappings
{
    OXmlContext *context = [[OXmlContext alloc] init];  //needed for config method
    
    //test CommercialItem mappings:
    OXmlElementMapper *commMap = [_mapper elementMapperForClass:[CommercialItem class]];
    STAssertNotNil(commMap, @"commercial mapping");
    OXPathMapper *emailPropMap = [commMap elementMapperByTag:@"email" nsURI:NS_URI];
    STAssertNotNil(emailPropMap, @"email mapped in commercial element");
    
    //test root mapping
    NSArray *errors = [_root configure:context];
    STAssertNil(errors, @"errors");
    STAssertNotNil(_root.pathMappers, @"mappings");
    OXPathMapper *resultsMapper = [_root elementMapperByTag:@"orginization" nsURI:NS_URI];
    STAssertNotNil(resultsMapper, @"results mapping");
    STAssertEquals(OX_CONTAINER, resultsMapper.toType.typeEnum, @"resultsMapper.toType.typeEnum == OX_CONTAINER");
    STAssertTrue([resultsMapper.toType.type isSubclassOfClass:[NSArray class]], @"defualt container type");
    int rCount = [_root.pathMappers count];
    STAssertEquals(1, rCount, @"locked mapping");
    STAssertEquals(OX_COMPLEX_MAPPER, _root.mapperEnum, @"mapperEnum == OX_COMPLEX_MAPPER");
    
    //test email mapping
    OXmlElementMapper *emailMap = [_mapper elementMapperForClass:[EmailItem class]];
    STAssertNotNil(emailMap, @"email mapping");
    OXmlXPathMapper *bodyMap = [emailMap bodyMapper];
    STAssertNotNil(bodyMap, @"bodyMap mapped in email element");
    OXmlXPathMapper *noteMap = [emailMap attributeMapperByTag:@"note" nsURI:NS_URI];
    STAssertNotNil(noteMap, @"noteMap mapped in email element");
    
    //test orginization mapping
    errors = [_orginization configure:context];
    STAssertNil(errors, @"errors");
    OXmlXPathMapper *nameMapper = [_orginization elementMapperByTag:@"name" nsURI:NS_URI];
    STAssertNotNil(nameMapper, @"name automaticly mapped in orginization element");
    

}


- (void)testOCXmlReader
{    
    //setup reader
    OXmlReader *reader = [OXmlReader readerWithMapper:_mapper];

//    reader.context.attributeFilterBlock = ^(NSString *attrName, NSString *attrValue) {
//        NSString *value = [attrValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//        return (value && [value length] > 0 && ![attrName hasPrefix:@"xmlns"] && ![value hasPrefix:@"?"]) ? value : nil; //ignore nil, empty, xml-namespace and '?' attributes
//    };
//    reader.context.elementFilterBlock = ^(NSString *elementName, NSString *elementValue) {
//        NSString *value = [elementValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//        return (value && [value length] > 0 && ![value hasPrefix:@"?"]) ? value : nil; //ignore nil, empty and '?' attributes
//    };
    
    //marshal XML and test resulting data:
    reader.context.logReaderStack = NO;
    NSArray *array = [reader readXmlFile:@"ContactsTestData.xml"];
    STAssertNotNil(array, @"xml returned array not nil");
    NSAssert([array count] > 0, @"results");
    CommercialItem *comm = [array objectAtIndex:0];
    STAssertEqualObjects(@"Havasupai Tribe", comm.name, @"name from xml");
    STAssertEqualObjects(comm.homePage, [NSURL URLWithString:@"http://home.com/index.html"], @"comm.homePage");
    STAssertNotNil(comm.lastUpdated, @"date parsed and set");
    NSDateFormatter *formatter = (NSDateFormatter *)[reader.context.transform formatterWithName:OX_DEFAULT_DATE_FORMATTER];
    STAssertEqualObjects(comm.lastUpdated, [formatter dateFromString:@"2013-01-22T15:45:30-0000"], @"comm.lastUpdated");
    STAssertEqualObjects(comm.notes,            @"bla bla bla", @"comm.notes");
    STAssertEquals(comm.prospect,               YES, @"comm.prospect");
    STAssertTrue(comm.status ==                 'A', @"comm.status");
    STAssertEquals(comm.locations,              (short)288, @"comm.locations");
    STAssertEquals(comm.contactAttemps,         9, @"comm.contactAttemps");
    STAssertEquals(comm.employees,              99999999l, @"comm.employees");
    STAssertEquals(comm.elevation,              2006.84f, @"comm.elevation");
    STAssertEquals(comm.netWorth,               34567800000.33, @"comm.netWorth");
    STAssertEqualObjects(comm.prospectW,        [NSNumber numberWithBool:YES], @"comm.prospect");
    STAssertEqualObjects(comm.statusW,          [NSNumber numberWithChar:'A'], @"comm.status");
    STAssertEqualObjects(comm.locationsW,       [NSNumber numberWithShort:288], @"comm.locations");
    STAssertEqualObjects(comm.contactAttempsW,  [NSNumber numberWithInt:9], @"comm.contactAttemps");
    STAssertEqualObjects(comm.employeesW,       [NSNumber numberWithLong:99999999l], @"comm.employees");
    STAssertEqualObjects(comm.elevationW,       [NSNumber numberWithFloat:2006.84f], @"comm.elevation");
    STAssertEqualObjects(comm.netWorthW,        [NSNumber numberWithDouble:34567800000.33], @"comm.netWorth");
    STAssertNotNil(comm.address,                @"comm.address from xml");
    STAssertNotNil(comm.address.orgunit,        @"comm.address.orgunit from xml");
    STAssertEquals(comm.address.zip,            86435, @"zip int from xml");
    
}

- (void)testReadSingleResult
{
    //setup mapper with single result:
    OXmlElementMapper *singleResultRoot = [OXmlElementMapper rootXPath:@"/contacts/contact/orginization" type:[CommercialItem class]];
    OXmlMapper *mapper = [[OXmlMapper mapperWithRootNamespace:NS_URI recommendedPrefix:@"c"]
               elements:@[singleResultRoot, _orginization, _email]]
    ;
    
    OXPathMapper *resultMapper = [singleResultRoot elementMapperByTag:@"orginization" nsURI:NS_URI];
    STAssertEquals(OX_COMPLEX, resultMapper.toType.typeEnum, @"resultsMapper.toType.typeEnum == OX_COMPLEX");
    STAssertTrue([resultMapper.toType.type isSubclassOfClass:[CommercialItem class]], @"specific (CommercialItem) result type");

    //setup reader and read xml - we should end up with the last orginization element in the file:
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];
    CommercialItem *commercialResult = [reader readXmlFile:@"ContactsTestData.xml"];
    STAssertNotNil(commercialResult, @"commercialResult");
    STAssertTrue([commercialResult isKindOfClass:[CommercialItem class]], @"[commercialResult isSubclassOfClass:[CommercialItem class]");
}

- (void)testWriter
{
    //use reader to create test object:
    OXmlReader *reader = [OXmlReader readerWithMapper:_mapper];
    //read xml into object graph:
    CommercialItem *result = [reader readXmlFile:@"ContactsTestData.xml"];
    STAssertNotNil(result, @"result");
    
    //setup writer:
    OXmlWriter *writer = [OXmlWriter writerWithMapper:_mapper];
    writer.schemaLocation = @"http://OutsourceCafe.com/schema/contacts/1/1 ../contacts.xsd";
    writer.rootNodeAttributes = @{@"creator":@"http://OutsourceCafe.com", @"version":@"1.1"};
    
    //tests
    NSString *xml = [writer writeXml:result];
    STAssertNotNil(xml, @"xml not nil");
    //NSLog(@"xml = \n%@", xml);
    
}

- (void)testRawXPathTagBuilder
{
    //raw tags are text 'text()' and attribute '@myattribute' nodes that are usually hidden behind builder methods
    OXmlElementMapper *elementMapper = [[[[[OXmlElementMapper elementClass:[CommercialItem class]]
                                           tag:@"name"]                               //element
                                          tag:@"@homePage"]                           //raw attribute node
                                         xpath:@"text()" property:@"lastUpdated"]     //raw text node
                                        lockMapping];                                 //ignore other properties
    //configure mapper:
    [[OXmlMapper mapper] elements:@[elementMapper]];
    OXmlContext *ctx = [[OXmlContext alloc] init];
    NSArray *errors = [elementMapper configure:ctx];
    STAssertNil(errors, @"no errors");
    
    //test OXmlElementMapper
    int count = [elementMapper.pathMappers count];
    STAssertEquals(3, count, @"3 property mappings");
    count = [elementMapper.orderedElementPropertyKeys count];
    STAssertEquals(1, count, @"1 element mappings");
    count = [elementMapper.orderedAttributePropertyKeys count];
    STAssertEquals(1, count, @"1 attribute mappings");
    STAssertNotNil(elementMapper.bodyMapper, @"text()/body mapping");
    
    //test 'name' element property
    OXPathMapper *nameMapper = [elementMapper elementMapperByProperty:@"name"];
    STAssertNotNil(nameMapper, @"name property mapping");
    STAssertEqualObjects(nameMapper, [elementMapper elementMapperByTag:@"name" nsURI:nil], @"property and tag lookup");
    STAssertEquals(OX_ATOMIC, nameMapper.toType.typeEnum, @"nameMapper.toType.typeEnum == OX_ATOMIC");
    STAssertTrue([nameMapper.toType.type isSubclassOfClass:[NSString class]], @"name type");
    
    //test 'lastUpdated' text node property
    OXPathMapper *lastUpdatedMapper = elementMapper.bodyMapper;
    STAssertNotNil(lastUpdatedMapper, @"lastUpdated property mapping");
    STAssertEqualObjects(lastUpdatedMapper, [elementMapper findFirstMatch:^(OXPathMapper *m) { return [m.fromPath isEqualToString:@"text()"] ? m : nil; }], @"property and tag lookup");
    STAssertEquals(OX_ATOMIC, lastUpdatedMapper.toType.typeEnum, @"lastUpdatedMapper.toType.typeEnum == OX_ATOMIC");
    STAssertTrue([lastUpdatedMapper.toType.type isSubclassOfClass:[NSDate class]], @"lastUpdated type");
    
    //test 'homePage' attribute property
    OXPathMapper *homePageMapper = [elementMapper attributeMapperByProperty:@"homePage"];
    STAssertNotNil(homePageMapper, @"homePage property mapping");
    STAssertEqualObjects(homePageMapper, [elementMapper attributeMapperByTag:@"homePage" nsURI:nil], @"property and attribute lookup");
    STAssertEqualObjects(homePageMapper, [elementMapper attributeMapperByTag:@"@homePage" nsURI:nil], @"property and attribute lookup with '@' prefix");
    STAssertEquals(OX_ATOMIC, homePageMapper.toType.typeEnum, @"homePageMapper.toType.typeEnum == OX_ATOMIC");
    STAssertTrue([homePageMapper.toType.type isSubclassOfClass:[NSURL class]], @"homePage type");
    
}

- (void)testMultiTagPropertyMappings
{
    OXmlElementMapper *containerMapping = [[[OXmlElementMapper elementClass:[OXTestContainer class]]
                                            xpath:@"emails/email" toMany:[EmailItem class] property:@"emailArray"]
                                           lockMapping];
    [[OXmlMapper mapper] elements:@[containerMapping]];
    OXPathMapper *emailMapper = [containerMapping elementMapperByTag:@"email" nsURI:nil];
    STAssertNotNil(emailMapper, @"emailMapper lookup");
}

- (void)testAutomaticClassMapping
{
    OXmlMapper *mapper = [OXmlMapper mapper];
    [mapper configure:[[OXmlContext alloc] init]];
    OXmlElementMapper *addressMapper = [mapper elementMapperForClass:[AddressItem class]];
    STAssertNotNil(addressMapper, @"addressMapper");
    STAssertTrue(addressMapper.isConfigured, @"isConfigured");
}

- (void)testIgnoreTagMapping
{
    OXmlElementMapper *elementMapper = [[[[[OXmlElementMapper elementClass:[CommercialItem class]]
                                           tag:@"name"]                               //element
                                          tag:@"@homePage"]                           //attribute
                                         xpath:@"text()" property:@"lastUpdated"]     //text node
                                        ignoreProperties:@[@"prospect", @"emails", @"address"]]; //ignore properties
    //configure mapper:
    [[OXmlMapper mapper] elements:@[elementMapper]];
    OXmlContext *ctx = [[OXmlContext alloc] init];
    NSArray *errors = [elementMapper configure:ctx];
    STAssertNil(errors, @"no errors");
    
    //test ignore properties
    STAssertTrue([elementMapper.ignoreProperties containsObject:@"prospect"], @"ignore prospect property");
    STAssertNil([elementMapper elementMapperByProperty:@"emails"], @"emails property not mapped");
    STAssertNil([elementMapper elementMapperByProperty:@"address"], @"address property not mapped");
    STAssertFalse([elementMapper.ignoreProperties containsObject:@"homePage"], @"don't ignore homePage property");
    
    //test ignore tags
}

////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - root
////////////////////////////////////////////////////////////////////////////////////////

- (void)testToManyRootBuilder
{
    OXmlElementMapper *root = [OXmlElementMapper rootXPath:@"/contacts/contact/orginization" toMany:[CommercialItem class]];
    //configure mapper:
    [[OXmlMapper mapper] elements:@[root]];
    OXmlContext *ctx = [[OXmlContext alloc] init];
    NSArray *errors = [root configure:ctx];
    STAssertNil(errors, @"no errors");
    
    //test OXmlElementMapper
    STAssertTrue(root.lock, @"locked");
    STAssertEquals(OX_COMPLEX_MAPPER, root.mapperEnum, @"mapperEnum == OX_COMPLEX_MAPPER");
    STAssertNotNil(root.pathMappers, @"mappings");
    int rCount = [root.pathMappers count];
    STAssertEquals(1, rCount, @"locked mapping");
    STAssertEqualObjects([OXmlContext class], root.toType.type, @"use context to hold result");
    STAssertEqualObjects(ctx, root.factory(nil, ctx), @"instance factory just returns context instance");
    NSArray *RCC = @[@"/",@"contacts",@"contact"];
    STAssertTrue([root.xpath matches:RCC], @"root path less leaf node");
    
    //test OXmlElementMapper toMany result property
    OXPathMapper *resultMapper = [root elementMapperByProperty:@"result"];
    STAssertNotNil(resultMapper, @"result property mapping");
    STAssertEquals(OX_CONTAINER, resultMapper.toType.typeEnum, @"resultMapper.toType.typeEnum == OX_CONTAINER");
    STAssertTrue([resultMapper.toType.type isSubclassOfClass:[NSArray class]], @"defualt container type");
    STAssertTrue([resultMapper.toType.containerChildType.type isSubclassOfClass:[CommercialItem class]], @"specific child container type");
    STAssertEqualObjects(@"orginization", resultMapper.fromPath, @"gets the leaf node from the root path");
    
}

- (void)testToOneRootBuilder
{
    OXmlElementMapper *root = [OXmlElementMapper rootXPath:@"/commercial" type:[CommercialItem class]];
    //configure mapper:
    [[OXmlMapper mapper] elements:@[root]];
    OXmlContext *ctx = [[OXmlContext alloc] init];
    NSArray *errors = [root configure:ctx];
    STAssertNil(errors, @"no errors");
    
    //test OXmlElementMapper
    STAssertEqualObjects([OXmlContext class], root.toType.type, @"use context to hold result");
    STAssertEqualObjects(ctx, root.factory(nil, ctx), @"instance factory just returns context instance");
    NSArray *R = @[@"/"];
    STAssertTrue([root.xpath matches:R], @"root path less leaf node");
    
    //test OXmlElementMapper toMany result property
    OXPathMapper *resultMapper = [root elementMapperByProperty:@"result"];
    STAssertNotNil(resultMapper, @"result property mapping");
    STAssertEquals(OX_COMPLEX, resultMapper.toType.typeEnum, @"resultMapper.toType.typeEnum == OX_CONTAINER");
    STAssertTrue([resultMapper.toType.type isSubclassOfClass:[CommercialItem class]], @"specific result type");
    STAssertEqualObjects(@"commercial", resultMapper.fromPath, @"gets the leaf node from the root path");
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
