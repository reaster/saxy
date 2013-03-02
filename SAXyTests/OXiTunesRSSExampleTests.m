/**

  OXiTunesTests.m
  SAXy OX - Object-to-XML mapping library

  A mixed-namespace xml example using Apple's iTunes RSS feed. This example demonstrates:

    1) Marshalling and unmarshalling a complex xml schema to a multi-class object hierarchy
    2) Auto discovery and class-to-element mapping: OXAtomLink
    3) Disambiguation of identical element names using namespaces: link and atom:link
    4) Mixed namespace use with unspecified default namespace
    5) Expanding flat mapping to object hierarchy: OXAlbum, OXArtist and OXCoverArt
    6) Mapping an element with simple (atomic) content and attributes using 'body' method: OXAtomCategory and OXCoverArt
    7) Mapping to read-only properties
    8) Mapping to mutable (NSMutableArray) and non-mutable (NSArray) collection classes
    9) Use of custom date formatters and currency formatter
   10) Ordering element output via declaration ordering

  Sample feed taken from: http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wpa/MRSS/newreleases/limit=300/rss.xml


  Created by Richard Easterling on 2/13/13.

*/
#import <SenTestingKit/SenTestingKit.h>
#import "OXmlElementMapper.h"
#import "OXmlReader.h"
#import "OXmlContext.h"
#import "OXmlWriter.h"


///////////////////////////////////////////////////////////////////////////////////
#pragma mark - test classes
///////////////////////////////////////////////////////////////////////////////////

@interface OXAtomLink : NSObject
@property(strong, readonly, nonatomic) NSURL *href;           //xpath: @href
@property(strong, readonly, nonatomic) NSString *rel;         //xpath: @rel
@property(assign, readonly, nonatomic) NSString *type;        //xpath: @type
@end

@implementation OXAtomLink
@end

@interface OXAtomCategory : NSObject
@property(strong, readonly, nonatomic) NSURL *domain;         //xpath: @domain
@property(strong, readonly, nonatomic) NSString *value;       //xpath: text()
@end

@implementation OXAtomCategory
@end


@interface OXRSSImage : NSObject
@property(strong, readonly, nonatomic) NSURL *url;              //xpath: url
@property(strong, readonly, nonatomic) NSURL *link;             //xpath: link
@property(strong, readonly, nonatomic) NSString *title;         //xpath: title
@property(assign, readonly, nonatomic) NSInteger height;        //xpath: height
@property(assign, readonly, nonatomic) NSInteger width;         //xpath: width
@end

@implementation OXRSSImage
@end


@interface OXArtist : NSObject
@property(strong, readonly, nonatomic) NSString *name;          //xpath: itms:artist
@property(strong, readonly, nonatomic) NSURL *link;             //xpath: itms:artistLink
@end

@implementation OXArtist
@end

@interface OXCoverArt : NSObject
@property(strong, readonly, nonatomic) NSURL *href;           //xpath: text()
@property(assign, readonly, nonatomic) NSInteger height;      //xpath: @height
@property(assign, readonly, nonatomic) NSInteger width;       //xpath: @width
@end

@implementation OXCoverArt
@end


@interface OXAlbum : NSObject
@property(strong, readonly, nonatomic) NSString *name;          //xpath: itms:album
@property(strong, readonly, nonatomic) NSURL *link;             //xpath: itms:albumLink
@property(strong, readonly, nonatomic) OXArtist *artist;        //xpath: 'itms' namespace - flat mapping expansion example
@property(strong, readonly, nonatomic) NSNumber *price;         //xpath: itms:albumPrice - use currency formatter to handle '$' char
@property(strong, readonly, nonatomic) NSString *rights;        //xpath: itms:rights
@property(strong, readonly, nonatomic) NSDate *releasedate;     //xpath: itms:releasedate
@property(strong, readonly, nonatomic) NSArray *coverArtList;   //xpath: itms:coverArt
@end

@implementation OXAlbum
- (id)init
{
    if (self = [super init]) {
        _artist = [[OXArtist alloc] init]; //pre allocate to avoid special handling in flat mapping expansion
    }
    return self;
}
@end


@interface OXRSSItem : NSObject
@property(strong, readonly, nonatomic) NSString *title;         //xpath: title
@property(strong, readonly, nonatomic) NSURL *link;             //xpath: link
@property(strong, readonly, nonatomic) NSString *subTitle;      //xpath: description
@property(strong, readonly, nonatomic) NSDate *pubDate;         //xpath: pubDate
@property(strong, readonly, nonatomic) NSString *encoded;       //xpath: content:encoded
@property(strong, readonly, nonatomic) OXAtomCategory *category;//xpath: category
@property(strong, readonly, nonatomic) OXAlbum *album;          //xpath: 'itms' namespace - flat mapping expansion example
@end

@implementation OXRSSItem
- (id)init
{
    if (self = [super init]) {
        _album = [[OXAlbum alloc] init]; //pre allocate to avoid special handling in flat mapping expansion
    }
    return self;
}
@end


@interface OXRSSChannel : NSObject
@property(strong, readonly, nonatomic) NSString *title;         //xpath: title
@property(strong, readonly, nonatomic) NSURL *link;             //xpath: link
@property(strong, readonly, nonatomic) OXAtomLink *atomLink;    //xpath: atom:link
@property(strong, readonly, nonatomic) NSString *subTitle;      //xpath: description
@property(strong, readonly, nonatomic) NSString *language;      //xpath: language
@property(strong, readonly, nonatomic) NSString *copyright;     //xpath: copyright
@property(strong, readonly, nonatomic) NSDate *lastBuildDate;   //xpath: lastBuildDate
@property(strong, readonly, nonatomic) NSString *generator;     //xpath: generator
@property(strong, readonly, nonatomic) NSString *webMaster;     //xpath: webMaster
@property(strong, readonly, nonatomic) NSString *timeToLive;    //xpath: ttl

@property(strong, readonly, nonatomic) NSString *creator;       //xpath: dc:creator
@property(strong, readonly, nonatomic) NSDate *date;            //xpath: dc:date
@property(strong, readonly, nonatomic) NSString *updatePeriod;  //sy:updatePeriod
@property(assign, readonly, nonatomic) NSInteger updateFrequency; //xpath: sy:updateFrequency
@property(strong, readonly, nonatomic) NSDate *updateBase;      //xpath: sy:updateBase

@property(strong, readonly, nonatomic) OXRSSImage *image;       //xpath: image
@property(strong, readonly, nonatomic) NSMutableArray *items;   //xpath: item
@end


@implementation OXRSSChannel
@end





@interface OXiTunesTests : SenTestCase
@end

@implementation OXiTunesTests

///////////////////////////////////////////////////////////////////////////////////
// simple XML read example
///////////////////////////////////////////////////////////////////////////////////

- (void)testComplexRSSReadAndWrite
{
#define CHANNEL_DATE_FORMATTER @"CHANNEL_DATE_FORMATTER"
#define RELEASE_DATE_FORMATTER @"RELEASE_DATE_FORMATTER"
    
    OXmlMapper *mapper = [[[[[[[OXmlMapper mapper]
                               defaultPrefix:@"atom" forNamespaceURI:@"http://www.w3.org/2005/Atom"]
                              defaultPrefix:@"content" forNamespaceURI:@"http://purl.org/rss/1.0/modules/content/"]
                             defaultPrefix:@"dc" forNamespaceURI:@"http://purl.org/dc/elements/1.1/"]
                            defaultPrefix:@"sy" forNamespaceURI:@"http://purl.org/rss/1.0/modules/syndication/"]
                           defaultPrefix:@"itms" forNamespaceURI:@"http://phobos.apple.com/rss/1.0/modules/itms/"]
                          elements:@[                                                               //defines root node and element mappings in document order
                          
                          [OXmlElementMapper rootXPath:@"/rss/channel" type:[OXRSSChannel class]]   //for 'channel' element create a single OXRSSChannel result instance
                          ,
                          [[[[[[[[[[[[[[[[[OXmlElementMapper elementClass:[OXRSSChannel class]]     //populate OXRSSChannel properties with the specified xpath values
                                          tags:@[@"title", @"link"]]
                                         switchToNamespaceURI:@"http://www.w3.org/2005/Atom"]       //switches namesapce, 'atom' prefix
                                        xpath:@"link" property:@"atomLink"]                         //note: 'atom:link' will be mapped differently than 'link'
                                       switchToNamespaceURI:nil]                                    //switches back to default namespace
                                      xpath:@"description" property:@"subTitle"]                    //use old RSS 1.0 name avoiding method of the same name
                                     tags:@[@"language", @"copyright"]]
                                    xpathMapper:[[OXmlXPathMapper xpath:@"lastBuildDate" type:[NSDate class] property:@"lastBuildDate"]
                                                 formatter:CHANNEL_DATE_FORMATTER]]              //date mapper with custom formatter
                                   xpath:@"webMaster"]
                                  xpath:@"ttl" property:@"timeToLive"]
                                 switchToNamespaceURI:@"http://purl.org/dc/elements/1.1/"]          //switches namesapce, 'dc' prefix
                                tags:@[@"creator", @"date"]]
                               switchToNamespaceURI:@"http://purl.org/rss/1.0/modules/syndication/"]//switches namesapce, 'sy' prefix
                              tags:@[@"updatePeriod",@"updateFrequency",@"updateBase"]]
                             switchToNamespaceURI:nil]                                              //switches back to default namespace
                            xpath:@"image"]
                           xpath:@"item" toMany:[OXRSSItem class] property:@"items"]
                          ,
                          [[[[[[[[[[[[[[[[[OXmlElementMapper elementClass:[OXRSSItem class]]           //populate OXRSSItem properties with the specified xpath values
                                          tags:@[@"title", @"link"]]
                                         xpath:@"description" property:@"subTitle"]                    //uses old RSS 1.0 name avoiding iOS method of the same name
                                        xpathMapper:[[OXmlXPathMapper xpath:@"pubDate" type:[NSDate class] property:@"pubDate"]
                                                     formatter:CHANNEL_DATE_FORMATTER]]             //date mapper with custom formatter
                                       switchToNamespaceURI:@"http://purl.org/rss/1.0/modules/content/"]//switches namespace, use the 'content' prefix
                                      xpath:@"encoded"]
                                     switchToNamespaceURI:nil]                                          //switches back to default namespace
                                    xpath:@"category"]
                                   switchToNamespaceURI:@"http://phobos.apple.com/rss/1.0/modules/itms/"]//switches namespace, use the 'itms' prefix
                                  xpath:@"album" property:@"album.name" type:[NSString class]]          //expand flat mapping to object hierarchy
                                 xpath:@"albumLink" property:@"album.link" type:[NSURL class]]
                                xpathMapper:[[OXmlXPathMapper xpath:@"albumPrice" scalar:@encode(float) property:@"album.price"]
                                             formatter:OX_CURRENCY_FORMATTER]]
                               xpath:@"artist" property:@"album.artist.name" type:[NSString class]]
                              xpath:@"artistLink" property:@"album.artist.link" type:[NSURL class]]
                             xpath:@"coverArt" toMany:[OXCoverArt class] property:@"album.coverArtList" containerType:[NSArray class]]
                            xpath:@"rights" property:@"album.rights" type:[NSString class]]
                           xpathMapper:[[OXmlXPathMapper xpath:@"releasedate" type:[NSDate class] property:@"album.releasedate"]
                                        formatter:RELEASE_DATE_FORMATTER]]
                          ,
                          [[[OXmlElementMapper elementClass:[OXCoverArt class]]                     //populate OXCoverArt properties with the specified xpath values
                            body:@"href"]
                           attributes:@[@"height",@"width"]]
                          ,
                          [[[OXmlElementMapper elementClass:[OXAtomCategory class]]                 //populate OXAtomCategory properties with the specified xpath values
                            attribute:@"domain"]
                           body:@"value"]
                          ,
                          [[OXmlElementMapper elementClass:[OXAtomLink class]]                      //populate OXAtomLink properties with the specified xpath values
                           attributes:@[@"href",@"rel",@"type"]]                                    //can't rely on auto discovery because properties are attributes
                          
                          //[[OXmlElementMapper elementClass:[OXRSSImage class]]                    //not necessary - auto discovered and default mappings work fine
                          
                          ]]
    ;
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];                                      //creates a reader using the mapper
    
    //register named formatters:
    NSDateFormatter *channelDateFormatter = [[NSDateFormatter alloc] init];                         //configures transform for atom channel date formatting
    [channelDateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [channelDateFormatter setDateFormat:@"EEE',' dd MMM yyyy HH:mm:ss Z"];                           //format: Tue, 12 Feb 2013 11:18:42 -0800
    [reader.context.transform registerFormatter:channelDateFormatter withName:CHANNEL_DATE_FORMATTER];
    NSDateFormatter *releaseDateFormatter = [[NSDateFormatter alloc] init];                         //configures transform for release date formatting
    [releaseDateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [releaseDateFormatter setDateFormat:@"MMMM dd',' yyyy"];                                         //format: February 8, 2013
    [reader.context.transform registerFormatter:releaseDateFormatter withName:RELEASE_DATE_FORMATTER];
    
    
    reader.context.logReaderStack = NO;
    
    OXRSSChannel *channel = [reader readXmlFile:@"iTunesNewReleasesRSS.xml"];                       //reads the XML -> single OXRSSChannel result instance
    
    //test OXRSSChannel instance:
    STAssertNotNil(channel, @"channel read");                                                       //test the results
    STAssertEqualObjects(@"iTunes 100 New Releases", channel.title, @"title == 'iTunes 100 New Releases'");
    STAssertTrue([channel.items count] > 0, @"items read");
    STAssertNotNil(channel.atomLink, @"{http://www.w3.org/2005/Atom}:link mapped to OXAtomLink");
    STAssertEqualObjects(@"application/rss+xml", channel.atomLink.type, @"type attribute mapped to OXAtomLink.type");
    STAssertNotNil(channel.image, @"automatically mapped OXRSSImage instance found");
    STAssertEqualObjects(@"http://r.mzstatic.com/images/rss/badge.gif", [channel.image.url absoluteString], @"OXRSSImage 'link' property mapped");
    STAssertEqualObjects(@"hourly", channel.updatePeriod, @"property mapped under 'http://purl.org/rss/1.0/modules/syndication/' namespace");
    
    NSDateFormatter *dateFormatter = (NSDateFormatter *)[reader.context.transform formatterWithName:OX_DEFAULT_DATE_FORMATTER];
    NSDate *expectedDate; NSError *error; [dateFormatter getObjectValue:&expectedDate forString:@"2013-02-12T11:18:42-08:00" range:nil error:&error];
    STAssertEqualObjects(expectedDate, channel.date, @"channel.date - default date formatter working");
    
    [dateFormatter getObjectValue:&expectedDate forString:@"2003-09-01T12:00:00+00:00" range:nil error:&error];
    STAssertEqualObjects(expectedDate, channel.updateBase, @"channel.date - default date formatter working");
    
    dateFormatter = (NSDateFormatter *)[reader.context.transform formatterWithName:@"CHANNEL_DATE_FORMATTER"];
    [dateFormatter getObjectValue:&expectedDate forString:@"Tue, 12 Feb 2013 11:18:42 -0800" range:nil error:&error];
    STAssertEqualObjects(expectedDate, channel.lastBuildDate, @"channel.lastBuildDate - custom date formatter working");
    
    //test first OXRSSItem instance:
    OXRSSItem *item = [channel.items objectAtIndex:0];
    STAssertEqualObjects(@"All Trap Music - Various Artists", item.title, @"item.title == 'All Trap Music - Various Artists'");
    STAssertNotNil(item, @"channel read");
    STAssertNotNil(item.encoded, @"'content:encoded' element improperly mapped in default namespace, is still discovered at runtime");
    STAssertEqualObjects(@"All Trap Music", item.album.name, @"itms:album -> item.album.name - expand flattened mapping");
    STAssertEqualObjects(@"Various Artists", item.album.artist.name, @"itms:artist -> item.album.artist.name - expand flattened mapping");
    STAssertNotNil(item.album.coverArtList, @"NSArray instantiated");
    STAssertTrue([item.album.coverArtList count] > 0, @"NSArray populated");
    
    dateFormatter = (NSDateFormatter *)[reader.context.transform formatterWithName:CHANNEL_DATE_FORMATTER];
    [dateFormatter getObjectValue:&expectedDate forString:@"Tue, 12 Feb 2013 11:18:42 -0800" range:nil error:&error];
    STAssertEqualObjects(expectedDate, item.pubDate, @"item.pubDate - custom date formatter working");
    
    dateFormatter = (NSDateFormatter *)[reader.context.transform formatterWithName:RELEASE_DATE_FORMATTER];
    [dateFormatter getObjectValue:&expectedDate forString:@"February 10, 2013" range:nil error:&error];
    STAssertEqualObjects(expectedDate, item.album.releasedate, @"item.album.releasedate - custom date formatter working");
    
    STAssertEquals(6.99f, [item.album.price floatValue], @"price - currency formatter working");
    
    //creates and fire off writer:
    OXmlWriter *writer = [[OXmlWriter writerWithMapper:mapper context:reader.context] rootAttributes:@{@"version": @"2.0"}];
    NSString *xml = [writer writeXml:channel prettyPrint:YES];
    //NSLog(@"iTunesNewReleasesRSS.xml = %@", xml);
    
    STAssertNotNil(xml, @"xml output"); //TODO need more writer tests
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
