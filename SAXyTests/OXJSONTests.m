/**
 
  OXJSONTests.m
  SAXy

  Non-trivial JSON mapping example demonstrating how to:
 
  1) read and write JSON to an from domain objects
  2) map across inheritance hierarchies
  3) keep mapping declarations concise using the builder pattern
  4) register a default date formatter and apply other formatters individually
  5) register a global type transformer to avoid zero (false booleans in this case) scalar output
  6) flatten and expand a mapping using KVC paths (OXStudioLocation and OXStudioAddress respectively)
  7) SAXy's automatic mapping (OXStudioLocation)
 

  Created by Richard Easterling on 3/4/13.

 */
#import <SenTestingKit/SenTestingKit.h>
#import "OXUtil.h"
#import "OXJSONMapper.h"
#import "OXJSONObjectMapper.h"
#import "OXJSONPathMapper.h"
#import "OXContext.h"
#import "OXJSONReader.h"
#import "OXJSONWriter.h"



////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - test classes
////////////////////////////////////////////////////////////////////////////////////////

@interface OXTuneEntity : NSObject
@property (nonatomic, assign) long identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSURL *url;
@end

@implementation OXTuneEntity  @end


@interface OXStudioLocation : NSObject
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@end

@implementation OXStudioLocation  @end


@interface OXStudioAddress : OXTuneEntity
@property (nonatomic, strong) NSString *street;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, assign) NSUInteger zip;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) OXStudioLocation *location;
@end

@implementation OXStudioAddress
- (id)init
{
    if (self = [super init]) {
        _location = [[OXStudioLocation alloc] init];   //facilitates nested mapping
    }
    return self;
}
@end

@interface OXCartoon : OXTuneEntity
@property (nonatomic, assign) int year;
@end

@implementation OXCartoon  @end


@interface OXTune : OXTuneEntity
@property (nonatomic, strong) NSDate *firstAppearance;
@property (nonatomic, strong) NSSet *cartoonSeries;
@property (nonatomic, strong) NSOrderedSet *archRivals;
@property (nonatomic, strong) NSDictionary *buddies;
@property (nonatomic, strong) NSMutableArray *starredIn;
@property (nonatomic, strong) NSData *image;
@property (nonatomic, strong) OXStudioAddress *studio;
@property (nonatomic, assign) BOOL goldenAgeOfAnimationMember;
@property (nonatomic, strong) NSDecimalNumber *appearances;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, strong) NSArray *references;
@property (nonatomic, strong) NSDate *lastUpdated;
@end

@implementation OXTune
- (id)init
{
    if (self = [super init]) {
        _studio = [[OXStudioAddress alloc] init];   //facilitates nested mapping
    }
    return self;
}
@end



////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tests
////////////////////////////////////////////////////////////////////////////////////////

@interface OXJSONTests : SenTestCase  @end

@implementation OXJSONTests
{
    OXJSONMapper *mapper;
    OXContext *context;
    NSDateFormatter *shortDateFormatter;
    NSDateFormatter *longDateFormatter;
}

- (void)setUp
{
    [super setUp];
    mapper = [[OXJSONMapper mapper] objects:@[
              
              [OXJSONObjectMapper rootToManyClass:[OXTune class]]
              ,
              [[[[[[[[[[[[[[[OXJSONObjectMapper objectClass:[OXTune class]]
                            path:@"id" type:[NSNumber class] property:@"identifier"]
                           path:@"name"]
                          path:@"url"]
                         path:@"first_appearance" property:@"firstAppearance"]
                        path:@"cartoon_series" toMany:[NSString class] property:@"cartoonSeries"]
                       path:@"arch_rivals" toMany:[OXTune class] property:@"archRivals"]
                      path:@"buddies" toMany:[OXTune class] property:@"buddies" dictionaryKey:@"identifier"]
                     path:@"starred_in" toMany:[OXCartoon class] property:@"starredIn"]
                    path:@"appearances"]
                   path:@"golden_age_of_animation_member" property:@"goldenAgeOfAnimationMember" scalarType:OX_ENCODED_BOOL ]
                  path:@"studio"]
                 path:@"references" toMany:[NSURL class]]
                pathMapper:[[OXJSONPathMapper path:@"lastupdated" property:@"lastUpdated"]
                            formatter:OX_RFC3339_DATE_FORMATTER]]
               ignorePaths:@[@"age"]]
              ,
              [[[[[[[[[[[OXJSONObjectMapper objectClass:[OXStudioAddress class]]
                        path:@"id" type:[NSNumber class] property:@"identifier"]
                       path:@"name"]
                      path:@"url"]
                     path:@"address.street" type:[NSString class] property:@"street" propertyType:[NSString class]] //expaned mapping
                    path:@"address.city" type:[NSString class] property:@"city" propertyType:[NSString class]]
                   path:@"address.state" type:[NSString class] property:@"state" propertyType:[NSString class]]
                  path:@"address.zip" type:[NSNumber class] property:@"zip" scalarType:@encode(NSUInteger)]
                 path:@"address.country" type:[NSString class] property:@"country" propertyType:[NSString class]]
                path:@"latitude" type:[NSNumber class] property:@"location.latitude" scalarType:@encode(double)]    //flatten mapping
               path:@"longitude" type:[NSNumber class] property:@"location.longitude" scalarType:@encode(double)]
              ,
              [[[OXJSONObjectMapper objectClass:[OXCartoon class]]
                  path:@"id" type:[NSNumber class] property:@"identifier"]
                 //path:@"name"]
                //path:@"url"]
               path:@"year" type:[NSNumber class]]
              
    ]];
    
    context = [[OXContext alloc] init];
    longDateFormatter = [[NSDateFormatter alloc] init];
    [longDateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [longDateFormatter setDateFormat:@"MMMM d',' yyyy"];
    [context.transform registerDefaultDateFormatter:longDateFormatter];     //register a default date handler
    
    [context.transform registerFromScalar:OX_ENCODED_BOOL to:[NSString class] transformer:^(id value, OXContext *ctx) { 
        return (value && [value boolValue]) ? @"true" : nil;    //register global transformer - ignores 'false' BOOl values in writer by returning nil
    }];

    NSDate *date = [longDateFormatter dateFromString:@"July 4, 1987"];
    STAssertNotNil(date, @"sanity check on date formatter");
}

- (void)testJSONMapper
{
    STAssertNotNil(mapper, @"mapper");
    [mapper configure:[[OXContext alloc] init]];
    
    //root
    OXJSONPathMapper *resultMapper = [mapper.rootMapper objectMapperByPath:OX_ROOT_PATH];
    STAssertNotNil(resultMapper, @"resultMapper by path");
    OXJSONPathMapper *resultMapper2 = [mapper.rootMapper objectMapperByProperty:@"result"];
    STAssertNotNil(resultMapper2, @"resultMapper by property");
    STAssertEqualObjects([NSMutableArray class], resultMapper.toType.type, @"self reflection assigned toType");
    STAssertEqualObjects([OXTune class], resultMapper.toType.containerChildType.type, @"container child type preserved");
    
    //OXTune
    OXJSONObjectMapper *tuneMapper = [mapper objectMapperForClass:[OXTune class]];
    STAssertNotNil(tuneMapper, @"tuneMapper");
    
    OXJSONPathMapper *idMapper = [tuneMapper objectMapperByPath:@"id"];
    STAssertNotNil(idMapper, @"idMapper");
    //STAssertNil(idMapper.toTransform, @"NSNumber to NSNumber needs no transform");
    STAssertEqualObjects([NSNumber class], idMapper.toType.type, @"self reflection assigned toType");

    OXJSONPathMapper *dateMapper = [tuneMapper objectMapperByPath:@"first_appearance"];
    STAssertNotNil(dateMapper, @"firstAppearance");
    STAssertNotNil(dateMapper.toTransform, @"string to date needs transform");
    STAssertNil(dateMapper.formatterName, @"default dates have no formatterName");
    STAssertEqualObjects([NSDate class], dateMapper.toType.type, @"self reflection assigned toType");
    
    OXJSONPathMapper *seriesMapper = [tuneMapper objectMapperByPath:@"cartoon_series"];
    STAssertNotNil(seriesMapper, @"cartoon_series");
    STAssertEqualObjects([NSSet class], seriesMapper.toType.type, @"self reflection assigned toType");
    STAssertEqualObjects([NSString class], seriesMapper.toType.containerChildType.type, @"self reflection assigned toType.containerChildType");
    
    OXJSONPathMapper *referencesMapper = [tuneMapper objectMapperByPath:@"references"];
    STAssertNotNil(referencesMapper, @"references");
    STAssertEqualObjects([NSArray class], referencesMapper.toType.type, @"self reflection assigned toType");
    STAssertEqualObjects([NSURL class], referencesMapper.toType.containerChildType.type, @"self reflection assigned toType.containerChildType");
    
    OXJSONPathMapper *studioMapper = [tuneMapper objectMapperByPath:@"studio"];
    STAssertNotNil(studioMapper, @"studio");
    STAssertEqualObjects([OXStudioAddress class], studioMapper.toType.type, @"self reflection assigned toType");
    

    //OXStudioAddress
    OXJSONObjectMapper *addressMapper = [mapper objectMapperForClass:[OXStudioAddress class]];
    STAssertNotNil(addressMapper, @"addressMapper");
    
    OXJSONPathMapper *idAddrMapper = [addressMapper objectMapperByPath:@"id"];
    STAssertNotNil(idAddrMapper, @"idAddrMapper");
    //STAssertNil(idAddrMapper.toTransform, @"NSNumber to NSNumber needs no transform");
    STAssertEqualObjects([NSNumber class], idAddrMapper.toType.type, @"self reflection assigned toType");
    
    OXJSONPathMapper *cityMapper = [addressMapper objectMapperByPath:@"city"];
    STAssertNotNil(cityMapper, @"cityMapper");
    STAssertNil(cityMapper.toTransform, @"string to string doesn't need a transform");
    STAssertEqualObjects([NSString class], cityMapper.toType.type, @"self reflection assigned toType");
    
}

- (void)testReader
{
    OXJSONReader *reader = [OXJSONReader readerWithMapper:mapper context:context];
    reader.context.logReaderStack = NO;
    
    NSArray *tunes = [reader readResourceFile:@"tunes.json"];
    STAssertNotNil(tunes, @"read tunes");
    STAssertEquals((NSUInteger)4, [tunes count], @"4 tunes read");

    //OXTunes
    OXTune *tune = [tunes objectAtIndex:0];
    STAssertNotNil(tune, @"read tune");
    STAssertEquals(100101l, tune.identifier, @"identifier long - read");
    STAssertEqualObjects(@"Daffy Duck", tune.name, @"name read");
    STAssertEqualObjects([longDateFormatter dateFromString:@"April 17, 1937"], tune.firstAppearance, @"read NSDate - firstAppearance");
    STAssertEqualObjects(@"http://en.wikipedia.org/wiki/Daffy_Duck", [tune.url absoluteString], @"read url");
    STAssertTrue(tune.goldenAgeOfAnimationMember, @"read BOOL - goldenAgeOfAnimationMember");
    STAssertEquals(133.0, [tune.appearances doubleValue], @"read NSDecimalNumber - appearances");
    
    //date:
    NSDateFormatter *lastupdatedFormatter = (NSDateFormatter *)[reader.context.transform formatterWithName:OX_RFC3339_DATE_FORMATTER];
    NSDate *lastupdated = [lastupdatedFormatter dateFromString:@"2013-03-07T12:30:00-0000"];
    STAssertEqualObjects(lastupdated, tune.lastUpdated, @"read created_at");    
    //containers:
    STAssertNotNil(tune.cartoonSeries, @"read NSSet of NSStrings - cartoonSeries");
    STAssertEquals((NSUInteger)2, [tune.cartoonSeries count], @"read cartoonSeries");
    STAssertTrue([tune.cartoonSeries containsObject:@"Looney Tunes"], @"NSSet element - Looney Tunes");
    STAssertEqualObjects(@"Wile E. Coyote", [[tune.archRivals objectAtIndex:0] name], @"read 1st object in NSOrderedSet - Wile E. Coyote");
    STAssertEqualObjects(@"Porky Pig", [[tune.buddies objectForKey:[NSNumber numberWithLong:100104]] name], @"read NSDictionary of OXTune objects, keyed by id - Porky Pig");
    STAssertNotNil(tune.starredIn, @"read NSMutableArray of OXCartoon objects");
    STAssertEqualObjects(@"Duck Amuck", [[tune.starredIn lastObject] name], @"read NSMutableArray of OXCartoon objects, last object is - Duck Amuck");
    STAssertNotNil(tune.references, @"read NSArray of NSURL objects");
    STAssertEqualObjects(@"http://en.wikiquote.org/wiki/Daffy_Duck/", [[tune.references lastObject] absoluteString], @"read NSArray of NSURL objects, last object is - http://en.wikiquote.org/wiki/Daffy_Duck");
    //OXStudioAddress - expanded mapping
    STAssertNotNil(tune.studio, @"read nested OXStudioAddress - studio");
    STAssertEqualObjects(@"Warner Bros.", tune.studio.name, @"read nested studio name - Warner Bros.");
    STAssertEqualObjects(@"CA", tune.studio.state, @"read nested studio state - CA");
    STAssertEquals((NSUInteger)91522, tune.studio.zip, @"read nested zip - 91522");
    //OXStudioLocation - flattened mapping
    STAssertEquals(34.152141, tune.studio.location.latitude, @"read double from nested studio.location.latitude - 34.152141");
    STAssertEquals(-118.336852, tune.studio.location.longitude, @"read double from nested studio.location.longitude - -118.336852");
    
    //OXJSONWriter *writer = [[OXJSONWriter writerWithMapper:mapper context:context] writingOptions:NSJSONWritingPrettyPrinted];
    //NSLog(@"%@", [[writer writeAsText:tunes] stringByReplacingOccurrencesOfString:@"\\" withString:@""]);
    
}

- (void)testWriter
{
    NSString *json1 = @"[{\"id\":100103,\"name\":\"Bugs Bunny\",\"first_appearance\":\"April 30, 1938\",\"url\":\"http://en.wikipedia.org/wiki/Bugs_Bunny\",\"starred_in\":[{\"name\":\"A Wild Hare\",\"year\":1940,\"url\":\"http://en.wikipedia.org/wiki/A_Wild_Hare\"}],\"lastupdated\":\"2013-03-07T12:30:00+0000\"}]";
    
    OXJSONReader *reader = [OXJSONReader readerWithMapper:mapper context:context];
    NSArray *tunes = [reader readText:json1]; //lazy way to get the test data

    OXJSONWriter *writer = [OXJSONWriter writerWithMapper:mapper context:context];
    NSString *json2 = [[writer writeAsText:tunes] stringByReplacingOccurrencesOfString:@"\\" withString:@""];  //call reader and strip out '\' JavaScript encoding
    //what should be in output:
    STAssertTrue([json2 rangeOfString:@"\"id\":100103"].length > 0, @"\"id\":100103");
    STAssertTrue([json2 rangeOfString:@"\"name\":\"Bugs Bunny\""].length > 0, @"\"name\":\"Bugs Bunny\"");
    STAssertTrue([json2 rangeOfString:@"\"first_appearance\":\"April 30, 1938\""].length > 0, @"\"first_appearance\":\"April 30, 1938\"");
    STAssertTrue([json2 rangeOfString:@"\"url\":\"http://en.wikipedia.org/wiki/Bugs_Bunny\""].length > 0, @"\"url\":\"http://en.wikipedia.org/wiki/Bugs_Bunny\"");
    STAssertTrue([json2 rangeOfString:@"\"name\":\"A Wild Hare\""].length > 0, @"\"name\":\"A Wild Hare\"");
    STAssertTrue([json2 rangeOfString:@"\"year\":1940"].length > 0, @"\"year\":1940");
    STAssertTrue([json2 rangeOfString:@"\"lastupdated\":\"2013-03-07T12:30:00+0000\""].length > 0, @"OX_RFC3339_DATE_FORMATTER - \"lastupdated\":\"2013-03-07T12:30:00+0000\"");
    //what should not be there:
    STAssertFalse([json2 rangeOfString:@"\"age\":\"0\""].length > 0, @"ignorePaths working - \"age\":\"0\"");
    STAssertFalse([json2 rangeOfString:@"\"golden_age_of_animation_member\":\"false\""].length > 0, @"global transformer should eliminate 'false' BOOLs - \"golden_age_of_animation_member\":\"false\"");

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

