//
//  OXmlNamespaceTests.m
//  SAXy OX - Object-to-XML mapping library
//
//  Created by Richard Easterling on 2/19/13.
//

#import <SenTestingKit/SenTestingKit.h>
#import "OXmlMapper.h"
#import "OXmlElementMapper.h"
#import "OXmlContext.h"
#import "OXmlReader.h"
#import "OXmlWriter.h"


////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - test class
////////////////////////////////////////////////////////////////////////////////////////


@interface OXNS : NSObject
@property(nonatomic)NSString *a;
@property(nonatomic)NSString *b;
@property(nonatomic)NSString *c;
@property(nonatomic)NSString *d;
@end

@implementation OXNS  @end


////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tests
////////////////////////////////////////////////////////////////////////////////////////

@interface OXmlNamespaceTests : SenTestCase  @end

@implementation OXmlNamespaceTests



- (void)testTwoMixedNamespaces
{
    OXmlMapper *mapper = [[[OXmlMapper mapperWithRootNamespace:@"ns.com/x" recommendedPrefix:@"x"]
                           defaultPrefix:@"y" forNamespaceURI:@"ns.com/y"]
                          elements:@[
                              [OXmlElementMapper rootXPath:@"/ns" type:[OXNS class]]
                              ,
                              [[[[[[OXmlElementMapper elementClass:[OXNS class]]
                                   xpath:@"a"]
                                  attribute:@"b"]
                                 switchToNamespaceURI:@"ns.com/y" ]
                                xpath:@"c"]
                               attribute:@"d"]
                          ]]
    ;
    //test namespace mappings:
    NSString *xPrefix = [mapper.nsByURI objectForKey:@"ns.com/x"];
    NSString *xNS = [mapper.nsByPrefix objectForKey:@"x"];
    STAssertEqualObjects(@"x", xPrefix, @"registered 'x' prefix");
    STAssertEqualObjects(@"y", [mapper.nsByURI objectForKey:@"ns.com/y"], @"registered 'y' prefix");
    STAssertEqualObjects(@"ns.com/x", xNS, @"registered 'x' URI");
    STAssertEqualObjects(@"ns.com/y", [mapper.nsByPrefix objectForKey:@"y"], @"registered 'x' URI");

    OXmlElementMapper *rootMapper = mapper.rootMapper;
    STAssertNotNil(rootMapper, @"root mapper");
    STAssertEqualObjects(@"ns.com/x", rootMapper.nsURI, @"root assigned root namespace");

    //test lookups:
    OXmlXPathMapper *resultMapper1 = [rootMapper matchPathStack:@[@"ns"] forNSPrefix:@"x"];
    STAssertNotNil(resultMapper1, @"result by-path mapper");
    OXmlXPathMapper *resultMapper2 = [rootMapper elementMapperByProperty:@"result"];
    STAssertNotNil(resultMapper2, @"result by-property mapper");
    OXmlElementMapper *nsMapper = [mapper elementMapperForClass:[OXNS class]];
    STAssertNotNil(nsMapper, @"ns mapper");
    OXmlXPathMapper *aMapper1 = [nsMapper elementMapperByTag:@"a" nsURI:@"ns.com/x"];
    STAssertNotNil(aMapper1, @"'a' path mapper");
    OXmlXPathMapper *aMapper2 = [nsMapper matchPathStack:@[@"a"] forNSPrefix:@"x"];
    STAssertNotNil(aMapper2, @"'a' path mapper");
    OXmlXPathMapper *bMapper = [nsMapper attributeMapperByTag:@"b" nsURI:@"ns.com/x"];
    STAssertNotNil(bMapper, @"'b' path mapper");
    OXmlXPathMapper *cMapper = [nsMapper matchPathStack:@[@"c"] forNSPrefix:@"y"];
    STAssertNotNil(cMapper, @"'c' path mapper");
    OXmlXPathMapper *dMapper = [nsMapper attributeMapperByTag:@"d" nsURI:@"ns.com/y"];
    STAssertNotNil(dMapper, @"'d' path mapper");
    
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];
    reader.context.logReaderStack = NO;    //debug mapping
    
    NSString *xml1 = @"<x:ns b='B' xmlns:x='ns.com/x' xmlns:y='ns.com/y'><x:a>A</x:a><y:c>C</y:c></x:ns>";
    OXNS *ns = [reader readXmlText:xml1];
    
    STAssertEqualObjects(@"A", ns.a, @"'x' namespace element: a");
    STAssertEqualObjects(@"B", ns.b, @"'x' namespace attribute: @b");
    STAssertEqualObjects(@"C", ns.c, @"'y' namespace element: c");
    
    //Create a writer configured to match input xml (no header and single quotes):
    OXmlWriter *writer = [OXmlWriter writerWithMapper:mapper];
    writer.xmlHeader = nil;
    writer.printer.quoteChar =@"'";
    
    NSString *xml2 = [writer writeXml:ns prettyPrint:NO];
    STAssertEqualObjects(xml1, xml2, @"input xml == output xml");
    
    //move 'y' namespace decl:
    NSString *xml3 = @"<x:ns b='B' xmlns:x='ns.com/x'><x:a>A</x:a><y:c xmlns:y='ns.com/y'>C</y:c></x:ns>";
    OXNS *ns2 = [reader readXmlText:xml3];
    NSString *xml4 = [writer writeXml:ns2 prettyPrint:NO];
    STAssertEqualObjects(xml1, xml4, @"input xml == output xml");
    
    //swap a and c tag positions:
    NSString *xml5 = @"<x:ns b='B' xmlns:x='ns.com/x'><y:c xmlns:y='ns.com/y'>C</y:c><x:a>A</x:a></x:ns>";
    OXNS *ns3 = [reader readXmlText:xml5];
    NSString *xml6 = [writer writeXml:ns3 prettyPrint:NO];
    STAssertEqualObjects(xml1, xml6, @"input xml == output xml");
    
    //test prefixed attribute
    NSString *xml7 = @"<x:ns b='B' y:d='D' xmlns:x='ns.com/x' xmlns:y='ns.com/y'><x:a>A</x:a><y:c>C</y:c></x:ns>";
    OXNS *ns4 = [reader readXmlText:xml7];
    STAssertEqualObjects(@"D", ns4.d, @"'y' namespace attribute: d");
    NSString *xml8 = [writer writeXml:ns4 prettyPrint:NO];
    STAssertEqualObjects(xml7, xml8, @"input xml == output xml with prefixed attribute");
}



- (void)testDefaultNamespace
{
    OXmlMapper *mapper = [[OXmlMapper mapperWithDefaultNamespace:@"ns.com/x"]
                          elements:@[
                              [OXmlElementMapper rootXPath:@"/ns" type:[OXNS class]]
                              ,
                              [[[[[OXmlElementMapper elementClass:[OXNS class]]
                                  xpath:@"a"]
                                 attribute:@"b"]
                                switchToNamespaceURI:@"ns.com/y" ]
                               xpath:@"c"]
                          ]]
    ;
    //test lookups:
    OXmlElementMapper *rootMapper = [mapper elementMapperForPath:OX_ROOT_PATH];
    STAssertNotNil(rootMapper, @"root mapper");
    OXmlXPathMapper *resultMapper1 = [rootMapper elementMapperByTag:@"ns" nsURI:@"ns.com/x"];
    STAssertNotNil(resultMapper1, @"result by-path mapper");
    OXmlXPathMapper *resultMapper2 = [rootMapper elementMapperByProperty:@"result"];
    STAssertNotNil(resultMapper2, @"result by-property mapper");
    OXmlElementMapper *nsMapper = [mapper elementMapperForClass:[OXNS class]];
    STAssertNotNil(nsMapper, @"ns mapper");
    OXmlXPathMapper *aMapper1 = [nsMapper elementMapperByTag:@"a" nsURI:@"ns.com/x"];
    STAssertNotNil(aMapper1, @"'a' path mapper");
//    OXmlXPathMapper *aMapper2 = [nsMapper matchPathStack:@[@"a"] forNSPrefix:nil];
//    STAssertNotNil(aMapper2, @"'a' path mapper");
    OXmlXPathMapper *bMapper = [nsMapper attributeMapperByTag:@"b" nsURI:@"ns.com/x"];
    STAssertNotNil(bMapper, @"'b' path mapper");
    OXmlXPathMapper *cMapper = [nsMapper elementMapperByTag:@"c" nsURI:@"ns.com/y"];
    STAssertNotNil(cMapper, @"'c' path mapper");

    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];
    reader.context.logReaderStack = NO;    //debug mapping
    
    NSString *xml1 = @"<ns b='B' xmlns='ns.com/x' xmlns:y='ns.com/y'><a>A</a><y:c>C</y:c></ns>";
    OXNS *ns = [reader readXmlText:xml1];
    
    STAssertEqualObjects(@"A", ns.a, @"default namespace element: a");
    STAssertEqualObjects(@"B", ns.b, @"default namespace attribute: @b");
    STAssertEqualObjects(@"C", ns.c, @"'y' namespace element: c");
    
    [mapper
      //defaultPrefix:@"xmlns" forNamespaceURI:@"ns.com/x"]
     defaultPrefix:@"y" forNamespaceURI:@"ns.com/y"];
    
    //Create a writer configured to match input xml (no header and single quotes):
    OXmlWriter *writer = [OXmlWriter writerWithMapper:mapper];
    writer.xmlHeader = nil;
    writer.printer.quoteChar =@"'";
    
    NSString *xml2 = [writer writeXml:ns prettyPrint:NO];
    STAssertEqualObjects(xml1, xml2, @"input xml == output xml");

    //move 'y' namespace decl:
    NSString *xml3 = @"<ns b='B' xmlns='ns.com/x'><a>A</a><y:c xmlns:y='ns.com/y'>C</y:c></ns>";
    OXNS *ns2 = [reader readXmlText:xml3];
    NSString *xml4 = [writer writeXml:ns2 prettyPrint:NO];
    STAssertEqualObjects(xml1, xml4, @"input xml == output xml");
    
    //swap a and c tag positions:
    NSString *xml5 = @"<ns b='B' xmlns='ns.com/x'><y:c xmlns:y='ns.com/y'>C</y:c><a>A</a></ns>";
    OXNS *ns3 = [reader readXmlText:xml5];
    NSString *xml6 = [writer writeXml:ns3 prettyPrint:NO];
    STAssertEqualObjects(xml1, xml6, @"input xml == output xml");
}

- (void)testNoNamespaces
{
    OXmlMapper *mapper = [[OXmlMapper mapper] elements:@[
                          [OXmlElementMapper rootXPath:@"/ns" type:[OXNS class]]
                          ,
                          [[OXmlElementMapper elementClass:[OXNS class]] tags:@[@"a", @"@b", @"c"]]   //element,attribute,element
                          ]]
    ;
    //test lookups:
    OXmlElementMapper *rootMapper = [mapper elementMapperForPath:OX_ROOT_PATH];
    STAssertNotNil(rootMapper, @"root mapper");
    OXmlXPathMapper *resultMapper1 = [rootMapper matchPathStack:@[@"ns"] forNSPrefix:nil];
    STAssertNotNil(resultMapper1, @"result by-path mapper");
    OXmlXPathMapper *resultMapper2 = [rootMapper elementMapperByProperty:@"result"];
    STAssertNotNil(resultMapper2, @"result by-property mapper");
    OXmlElementMapper *nsMapper = [mapper elementMapperForClass:[OXNS class]];
    STAssertNotNil(nsMapper, @"ns mapper");
    OXmlXPathMapper *aMapper1 = [nsMapper elementMapperByTag:@"a" nsURI:nil];
    STAssertNotNil(aMapper1, @"'a' path mapper");
    OXmlXPathMapper *aMapper2 = [nsMapper matchPathStack:@[@"a"] forNSPrefix:nil];
    STAssertNotNil(aMapper2, @"'a' path mapper");
    OXmlXPathMapper *bMapper = [nsMapper attributeMapperByTag:@"b" nsURI:nil];
    STAssertNotNil(bMapper, @"'b' path mapper");
    OXmlXPathMapper *cMapper = [nsMapper matchPathStack:@[@"c"] forNSPrefix:nil];
    STAssertNotNil(cMapper, @"'c' path mapper");
    
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];
    reader.context.logReaderStack = NO;    //debug mapping
    
    NSString *xml1 = @"<ns b='B'><a>A</a><c>C</c></ns>";
    OXNS *ns = [reader readXmlText:xml1];
    
    STAssertEqualObjects(@"A", ns.a, @"element: a");
    STAssertEqualObjects(@"B", ns.b, @"attribute: @b");
    STAssertEqualObjects(@"C", ns.c, @"element: c");
    
    //Create a writer configured to match input xml (no header and single quotes):
    OXmlWriter *writer = [OXmlWriter writerWithMapper:mapper];
    writer.xmlHeader = nil;
    writer.printer.quoteChar =@"'";
    
    NSString *xml2 = [writer writeXml:ns prettyPrint:NO];
    STAssertEqualObjects(xml1, xml2, @"input xml == output xml");
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
