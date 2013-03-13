/**
 
  OXTutorialTests.m
  SAXy OX - Object-to-XML mapping library

  Hands-on SAXy tutorial. Topics covered:

  1) A simple XML mapping example
  2) Library anatomy - OXmlReader, OXmlWriter, OXmlMapper and OXmlElementMapper
  3) Concise mapping declarations - the builder pattern
  4) Reading lists of data
  5) Working with attributes and body text
  6) OXmlXPathMapper - for fine-grained control
  7) Namespace support

  Created by Richard Easterling on 2/26/13.
 
 */
#import <SenTestingKit/SenTestingKit.h>

#import "OXmlReader.h"
#import "OXmlWriter.h"
#import "OXmlMapper.h"
#import "OXmlElementMapper.h"
#import "OXmlXPathMapper.h"


////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - test class
////////////////////////////////////////////////////////////////////////////////////////


@interface CartoonCharacter : NSObject
@property(nonatomic)NSString *firstName;
@property(nonatomic)NSString *lastName;
@property(nonatomic)NSDate *birthDay;
@end

@implementation CartoonCharacter
@end

////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tutorial
////////////////////////////////////////////////////////////////////////////////////////

@interface OXTutorialTests : SenTestCase  @end

@implementation OXTutorialTests

/**
 SAXy makes working with XML as easy as possible. Here is a very simple example demonstrating
 reading and writing XML using the CartoonCharacter class.
 */
- (void)testXMLMappingMadeSimple
{
    NSString *xml = @"<tune><firstName>Daffy</firstName><lastName>Duck</lastName></tune>";
    
    //map 'tune' element to CartoonCharacter class:
    OXmlMapper *mapper = [[OXmlMapper mapper] elements:@[ [OXmlElementMapper rootXPath:@"/tune" type:[CartoonCharacter class]] ]];
    
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];          //creates a reader based on the mapper
    
    CartoonCharacter *duck = [reader readXmlText:xml];                  //reads xml
    
    STAssertEqualObjects(@"Daffy", duck.firstName,  @"mapped 'firstName' element to 'firstName' property");  //test results
    STAssertEqualObjects(@"Duck",  duck.lastName,   @"mapped 'lastName' element to 'lastName' property");
    
    OXmlWriter *writer = [OXmlWriter writerWithMapper:mapper];          //creates a writer based on mapper
    writer.xmlHeader = nil;                                             //doesn't include XML header so we can campare result string
    
    NSString *output = [writer writeXml:duck prettyPrint:NO];           //writes xml
    STAssertEqualObjects(xml, output, @"input xml equals output xml");
}


/**
 SAXy's most important XML mapping classes are:
 
 1) OXmlReader          - used for reading XML (unmarshalling) to class instances
 2) OXmlWriter          - used for writing XML (marshalling) from class instances
 3) OXmlMapper          - high-level mapping of how to convert an XML schema to an object hierarchy
 4) OXmlElementMapper   - describes how attributes and elements are converted to class properties
 
 Readers and writers are easy to use and understand, all they require to do their job is a mapper instance.
 Mappers are basically a list of element mappings, starting with a root mapping.
 
 Element mappers associate XML element and attribute names with class properties. For specifying xml, SAXy
 supports a subset of the xpath language, but most of the time you can just think element names when you see xpath.
 
 This example modifies the last by explicitly mapping the CartoonCharacter's properties, something that was done
 automatically by SAXy before. We'll also shorten the element names to make it more interesting.
 */
- (void)testLibraryAnatomy
{
    NSString *xml = @"<tune><first>Daffy</first><last>Duck</last></tune>";
    
    //map the '/tune' path to the CartoonCharacter class:
    OXmlElementMapper *rootMapper = [OXmlElementMapper rootXPath:@"/tune" type:[CartoonCharacter class]];
    
    //map CartoonCharacter properties:
    OXmlElementMapper *tuneMapper = [OXmlElementMapper elementClass:[CartoonCharacter class]];
    [tuneMapper xpath:@"first" property:@"firstName"];
    [tuneMapper xpath:@"last" property:@"lastName"];
    
    OXmlMapper *mapper = [OXmlMapper mapper];                           //creates the mapper
    [mapper elements:@[ rootMapper, tuneMapper ]];                      //contains two element mappers
    
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];          //creates a reader based on the mapper
    reader.context.logReaderStack = NO;                                 //'YES' -> log mapping process

    CartoonCharacter *duck = [reader readXmlText:xml];                  //reads xml
    
    STAssertEqualObjects(@"Daffy", duck.firstName, @"mapped 'first' element to 'firstName' property");  //test results
    STAssertEqualObjects(@"Duck", duck.lastName, @"mapped 'last' element to 'lastName' property");
    
    OXmlWriter *writer = [OXmlWriter writerWithMapper:mapper];          //creates a writer based on mapper
    writer.xmlHeader = nil;                                             //doesn't include XML header so we can compare strings
    
    NSString *output = [writer writeXml:duck prettyPrint:NO];           //writes xml
    STAssertEqualObjects(xml, output, @"input xml equals output xml");
}

/**
 SAXy makes extensive use of the builder design pattern. The builder style in Objective-C takes a little getting  
 used to, but once mastered allows for concise, flexible mappings. Refer to the 'builder' section of the OXmlMapper 
 and OXmlElementMapper header files for available methods.
 
 In this example we'll wrap the 'first' and 'last' mappings around the elementClass constructor.  Also we'll drop the
 unnecessary instance variables.  You just have to balance your brackets and the code becomes much easier to read.  

 Mapping tips: - use Xcode's automatic indentation (^I) to help make the builder code more readable.
               - getting wierd errors? verify you're calling a builder method that returns self.
*/
- (void)testBuilderPattern
{
    NSString *xml = @"<tune><first>Daffy</first><last>Duck</last></tune>";
    
    OXmlReader *reader = [OXmlReader readerWithMapper:                  //declare a reader with embedded mapper
                          [[OXmlMapper mapper] elements:@[              //'elemnts:' builder method
                           
                               [OXmlElementMapper rootXPath:@"/tune" type:[CartoonCharacter class]]
                               ,
                           
                               [[[OXmlElementMapper elementClass:[CartoonCharacter class]]
                                 xpath:@"first" property:@"firstName"]  //'xpath:property:' builder method
                                xpath:@"last" property:@"lastName"]     //'xpath:property:' builder method
                           
                           ]]
                          ];
    
    CartoonCharacter *duck = [reader readXmlText:xml];                  //reads xml
    
    STAssertEqualObjects(@"Daffy", duck.firstName, @"mapped 'first' element to 'firstName' property");  //test results
    STAssertEqualObjects(@"Duck", duck.lastName, @"mapped 'last' element to 'lastName' property");
}

/**
 The mapper can be configured to read collections of data by calling a 'toMany' constructor. The default container type
 is NSMutableArray, but SAXy supports NSDictionary, NSSet, NSOrderedSet, NSArray and their mutable counterparts.
 */
- (void)testReadingLists
{
    NSString *xml = @"<tunes><tune><first>Elmer</first><last>Fudd</last></tune><tune><first>Daffy</first><last>Duck</last></tune></tunes>";
        
    //map 'tune' element to CartoonCharacter class:
    OXmlMapper *mapper = [[OXmlMapper mapper]
                          elements:@[
                          [OXmlElementMapper rootXPath:@"/tunes/tune" toMany:[CartoonCharacter class]]
                          ,
                          [[[OXmlElementMapper elementClass:[CartoonCharacter class]]
                            xpath:@"first" property:@"firstName"]
                           xpath:@"last" property:@"lastName"]
                          ]];
    
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];                      //creates a reader based on the mapper
    reader.context.logReaderStack = NO;                                             //'YES' -> log mapping process 
    
    NSMutableArray *tunes = [reader readXmlText:xml];                               //reads xml
    
    STAssertEquals((NSUInteger)2, [tunes count],  @"both Elmer and Daffy");         //test results
    
    CartoonCharacter *elmer = [tunes objectAtIndex:0];
    STAssertEqualObjects(@"Elmer", elmer.firstName,  @"mapped 'firstName' element to 'firstName' property");  //test elmer
    STAssertEqualObjects(@"Fudd",  elmer.lastName,   @"mapped 'lastName' element to 'lastName' property");
    
    CartoonCharacter *daffy = [tunes objectAtIndex:1];
    STAssertEqualObjects(@"Daffy", daffy.firstName,  @"mapped 'firstName' element to 'firstName' property");  //test daffy
    STAssertEqualObjects(@"Duck",  daffy.lastName,   @"mapped 'lastName' element to 'lastName' property");
    
    OXmlWriter *writer = [OXmlWriter writerWithMapper:mapper];          //creates a writer based on mapper
    writer.xmlHeader = nil;                                             //doesn't include XML header so we can campare result string
    
    NSString *outputXml = [writer writeXml:tunes prettyPrint:NO];       //writes xml using the array
    STAssertEqualObjects(xml, outputXml, @"input xml equals output xml");
}


/**
 SAXy supports mapping XML attributes to properties. Attributes can be mapped using the 'attribute' builder methods or
 by prefixing names with the '@' character in the 'xpath' builder methods.  Again refer to the 'builder' section of the
 OXmlElementMapper header file for usage.
 
 In addition to the attributes, we'll map Daffy's birthday into the body of the 'tune' element using the 'body'
 builder method. Notice that the body mapping is a bit of a special case, it only applies to elements that have attributes
 but no child elements.
 
 One last detail is to change the default date mapper, so we don't have to use the default RFC-3339 formatter.  We also
 reuse the formatter in the writer, by initializing the writer with the reader's context.
 */
- (void)testAttributesAndBodyMappings
{
    NSString *xml = @"<tune first='Daffy' last='Duck'>April 4, 1937</tune>";
    
    OXmlMapper *mapper = [[OXmlMapper mapper] elements:@[
                          [OXmlElementMapper rootXPath:@"/tune" type:[CartoonCharacter class]]
                          ,
                          [[[[OXmlElementMapper elementClass:[CartoonCharacter class]]
                             attribute:@"first" property:@"firstName"]                   //map to attributes
                            attribute:@"last" property:@"lastName"]
                           body:@"birthDay"]                                             //map birthDay to element body text
                          ]];
    
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];
    reader.context.logReaderStack = NO;                                                 //'YES' -> log mapping process

    NSDateFormatter *daffyDateFormatter = [[NSDateFormatter alloc] init];               //configure a new default date formatter
    [daffyDateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [daffyDateFormatter setDateFormat:@"MMMM d',' yyyy"];                               //format: April 4, 1937
    [reader.context.transform registerDefaultDateFormatter:daffyDateFormatter];         //register formatter with transform
    
    CartoonCharacter *duck = [reader readXmlText:xml];                                  //reads xml
    
    STAssertEqualObjects(@"Daffy", duck.firstName, @"mapped 'first' attribute to 'firstName' property");  //test results
    STAssertEqualObjects(@"Duck", duck.lastName, @"mapped 'last' attribute to 'lastName' property");
    STAssertEqualObjects([daffyDateFormatter dateFromString:@"April 4, 1937"], duck.birthDay, @"mapped element body to 'birthDay' property");
    
    OXmlWriter *writer = [OXmlWriter writerWithMapper:mapper context:reader.context];  //creates writer with reader context's new date formatter
    writer.xmlHeader = nil;                                             //doesn't include XML header so we can compare strings
    writer.printer.quoteChar = @"'";                                    //use single quotes for the same reason
    
    NSString *outputXml = [writer writeXml:duck prettyPrint:NO];        //writes xml
    STAssertEqualObjects(xml, outputXml, @"input xml equals output xml");
}


/**
 Most of the time mappings can be configured using OXmlElementMapper's builder methods.  However, when fine-grain
 control is required, custom OXmlXPathMapper instances can be created.  OXmlXPathMapper defines several important
 block properties (i.e. getter, setter, factory and transform functions) that are assigned default functions by
 SAXy, unless you set them first.
 
 In this example, we'll override the default KVC setter and getter blocks in OXmlXPathMapper to split a single tag
 into two properties.  The setter (called by the XML reader) splits the 'name' attribute into segments, assigning
 them to their respective properties.  The getter (called by the XML writer) concatenates the two properties
 back together, returning the value part of the 'name' attribute.
 
 Additionally, two problems have to be avoided:
 
 1) prevent SAXy from validating the 'name' property against the CartoonCharacter class (because it won't find it)
 2) avoid writing the 'firstName' and 'lastName' properties to the XML output
 
 The first problem is handled by declaring the 'name' attribute virtual.  The second problem can be solved by either
 an ignoreProperties:@[@"firstName", @"lastName"] clause.  Or, in this case, you could also call the lockMapping
 method, effectively telling SAXy to ignore the man behind the curtain (i.e. not engage in any self reflection).
 
 Lastly, this example reverts to the default XML RFC-3339 date formatter.  As you may already know, for full ISO 8601
 date support, you may want to register a good third-party date formatter (see http://boredzo.org/iso8601unparser/).
 */
- (void)testFineGrainedMapping
{
    NSString *xml = @"<tune name='Elmer Fudd'>1940-03-02T00:00:00+0000</tune>";
    
    OXmlMapper *mapper = [[OXmlMapper mapper] elements:@[
                          [OXmlElementMapper rootXPath:@"/tune" type:[CartoonCharacter class]]
                          ,
                          [[[[OXmlElementMapper elementClass:[CartoonCharacter class]]
                             xpathMapper:[[[[OXmlXPathMapper xpath:@"@name" type:[NSString class]]                //attribute is indicated with '@' prefix
                                            setter:^(NSString *path, id name, id target, OXContext *ctx) {
                                                CartoonCharacter *tune = target;
                                                NSArray *segments = [name componentsSeparatedByString:@" "];
                                                tune.firstName = [segments count] > 0 ? [segments objectAtIndex:0] : nil;
                                                tune.lastName = [segments count] > 1 ? [segments objectAtIndex:1] : nil;
                                            }]
                                           getter:^(NSString *path, id source, OXContext *ctx) {
                                               CartoonCharacter *tune = source;
                                               return [NSString stringWithFormat:@"%@ %@", tune.firstName, tune.lastName];
                                           }]
                                          isVirtualProperty]   //prevent validation against CartoonCharacter class
                             ]
                            body:@"birthDay"]
                           ignoreProperties:@[@"firstName", @"lastName"]]   //doesn't write (or read) these properties
                          //lockMapping]  //prevents SAXy from discovering and writing firstName and lastName properties
                          ]];
    
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];
    reader.context.logReaderStack = NO;                                //'YES' -> log mapping process
    
    CartoonCharacter *fudd = [reader readXmlText:xml];                 //reads xml
    
    STAssertEqualObjects(@"Elmer", fudd.firstName, @"mapped 'first' attribute to 'firstName' property");  //test results
    STAssertEqualObjects(@"Fudd", fudd.lastName, @"mapped 'last' attribute to 'lastName' property");
    NSDateFormatter *formatter = [reader.context.transform defaultDateFormatter];          //dig out default date formatter
    STAssertEqualObjects([formatter dateFromString:@"1940-03-02T00:00:00+0000"], fudd.birthDay, @"mapped element body to 'birthDay' property");
    
    OXmlWriter *writer = [OXmlWriter writerWithMapper:mapper];          //creates a writer based on mapper
    writer.xmlHeader = nil;                                             //doesn't include XML header so we can compare strings
    writer.printer.quoteChar = @"'";                                    //use single quotes for the same reason
    
    NSString *output = [writer writeXml:fudd prettyPrint:NO];           //writes xml
    STAssertEqualObjects(xml, output, @"input xml equals output xml");
}


/**
 SAXy has full XML naemespace support including support for prefixed and default (non-prefixed) namespaces.
 
 Namespaces can be declared:
 
 1) per mapping   - in the OXmlMapper constructor
 2) per class     - in the OXmlElementMapper constructor
 3) per property  - using OXmlElementMapper's switchToNamespaceURI builder method
 
 This example demonstrates how to declare a prefixed namespace for an entire mapping.
 
 See OXiTunesTests.m for an example of a complex, mixed namespace mapping on a RSS document.
 */
- (void)testNamespaceSupport
{
    NSString *xml = @"<l:tune xmlns:l='disney.com/luneytunes'><l:first>Elmer</l:first><l:last>Fudd</l:last></l:tune>";
    
    //map 'tune' element to CartoonCharacter class:
    OXmlMapper *mapper = [[OXmlMapper mapperWithRootNamespace:@"disney.com/luneytunes" recommendedPrefix:@"l"]
                          elements:@[
                          [OXmlElementMapper rootXPath:@"/tune" type:[CartoonCharacter class]]
                          ,
                          [[[OXmlElementMapper elementClass:[CartoonCharacter class]]
                            xpath:@"first" property:@"firstName"]
                           xpath:@"last" property:@"lastName"]
                          ]];
    
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];         //creates a reader based on the mapper
    
    CartoonCharacter *fudd = [reader readXmlText:xml];                 //reads xml
    
    STAssertEqualObjects(@"Elmer", fudd.firstName, @"mapped 'first' attribute to 'firstName' property");  //test results
    STAssertEqualObjects(@"Fudd", fudd.lastName, @"mapped 'last' attribute to 'lastName' property");
    
    OXmlWriter *writer = [OXmlWriter writerWithMapper:mapper];          //creates a writer based on mapper
    writer.xmlHeader = nil;                                             //doesn't include XML header so we can compare strings
    writer.printer.quoteChar = @"'";                                    //use single quotes for the same reason
    
    NSString *output = [writer writeXml:fudd prettyPrint:NO];           //writes xml
    STAssertEqualObjects(xml, output, @"input xml equals output xml");
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

