/**
 
 OXTwitterExampleTests.m
 SAXy OX - Object-to-XML mapping library
 
 This demonstrates using SAXy with twitter feeds.
 
 There are both single-object and a multi-object mapping examples using the same data file: 'BarackObamaTwitterFeed.xml'.
 
 
 Created by Richard Easterling on 2/12/13.
 
 */
#import <SenTestingKit/SenTestingKit.h>

#import "OXmlElementMapper.h"
#import "OXmlReader.h"
#import "OXmlContext.h"
#import "OXmlWriter.h"
#import "OXmlXPathMapper.h"


///////////////////////////////////////////////////////////////////////////////////
#pragma mark - single-object mapping class
///////////////////////////////////////////////////////////////////////////////////

//OXSimpleTweet - used in testSimpleRead test
@interface OXSimpleTweet : NSObject
@property(strong, readonly, nonatomic) NSDate *date;            //xpath: created_at
@property(strong, readonly, nonatomic) NSString *text;          //xpath: text
@property(strong, readonly, nonatomic) NSString *screenName;    //xpath: user/screen_name
@end

@implementation OXSimpleTweet
@end

///////////////////////////////////////////////////////////////////////////////////
#pragma mark - multi-object mapping classes
///////////////////////////////////////////////////////////////////////////////////

@interface OXTwitterUser : NSObject
@property(strong, readonly, nonatomic) NSNumber *key;           //id - avoid reserved word
@property(strong, readonly, nonatomic) NSString *name;
@property(strong, readonly, nonatomic) NSString *screenName;    //screen_name
@property(strong, readonly, nonatomic) NSString *location;
@property(strong, readonly, nonatomic) NSString *about;         //description - avoid method by the same name
@property(strong, readonly, nonatomic) NSURL *image;            //profile_image_url
@property(strong, readonly, nonatomic) NSURL *url;
@property(assign, readonly, nonatomic) NSInteger followers;     //followers_count
@property(assign, readonly, nonatomic) NSInteger friends;       //friends_count
@property(assign, readonly, nonatomic) NSInteger favourites;    //favourites_count
@property(assign, readonly, nonatomic) NSInteger posts;         //statuses_count
@property(strong, readonly, nonatomic) NSString *lang;
@property(assign, readonly, nonatomic) NSInteger listed;        //listed_count
@property(strong, readonly, nonatomic) NSDate *date;            //created_at
@end

@interface OXTweet : NSObject
@property(strong, readonly, nonatomic) NSNumber *key;          //id - avoid reserved word
@property(strong, readonly, nonatomic) NSDate *date;           //created_at
@property(strong, readonly, nonatomic) NSString *text;
@property(assign, readonly, nonatomic) BOOL retweeted;
@property(assign, readonly, nonatomic) BOOL truncated;
@property(assign, readonly, nonatomic) BOOL favorited;
@property(strong, readonly, nonatomic) OXTwitterUser *user;
@end

@implementation OXTwitterUser @end

@implementation OXTweet @end



///////////////////////////////////////////////////////////////////////////////////
#pragma mark - tests
///////////////////////////////////////////////////////////////////////////////////


@interface OXTwitterExampleTests : SenTestCase @end

@implementation OXTwitterExampleTests


/**
 This demonstrates how to selectively pull some data from an XML file. This is useful for read-only
 applications where you don't need the entire document model.
 
 Here a single list of OXSimpleTweet objects is extracted.  Notice the screenName is obtained using
 a multi-element xpath value: 'user/screen_name'
 */
- (void)testSimpleRead
{
    OXmlMapper *mapper = [[OXmlMapper mapper] elements:@[                               //mapper defines a root path and a single class to populate
                          
                          [OXmlElementMapper rootXPath:@"/statuses/status" toMany:[OXSimpleTweet class]],   //for each 'status' element create a OXSimpleTweet instance
                          
                          [[[[OXmlElementMapper elementClass:[OXSimpleTweet class]]                         //populate OXSimpleTweet properties with the specified xpath values
                             xpath:@"created_at" property:@"date"]
                            xpath:@"text" property:@"text"]
                           xpath:@"user/screen_name" property:@"screenName"]
                          
                          ]];
    
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];                          //create a reader using the mapper
    reader.context.logReaderStack = NO;                                                 //set to 'YES' for a mapper trace
    
    NSDateFormatter *twitterDateFormatter = [[NSDateFormatter alloc] init];             //configure transform for twitter date formatting
    [twitterDateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [twitterDateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
    [reader.context.transform registerDefaultDateFormatter:twitterDateFormatter];
    
    NSArray *tweets = [reader readXmlFile:@"BarackObamaTwitterFeed.xml"];               //read the XML
    
    STAssertTrue([tweets count] > 0, @"tweets read");                                   //test the results
    OXSimpleTweet *tweet = [tweets objectAtIndex:0];
    STAssertNotNil(tweet.text, @"got the message");
    STAssertEqualObjects(@"BarackObama", tweet.screenName, @"screenName == 'BarackObama'");
    STAssertEqualObjects([twitterDateFormatter dateFromString:@"Mon Mar 05 22:08:25 +0000 2007"], tweet.date, @"date == 'Mon Mar 05 22:08:25 +0000 2007'");
}


///////////////////////////////////////////////////////////////////////////////////
// XML read and write example
///////////////////////////////////////////////////////////////////////////////////

/**
 This demonstrates a more complete twitter mapping used to read and write a feed.
 
 Notice the configuration only specifies element mappings that can't be inferred by SAXy using self reflection of
 the class properties.  In this case, they are:
 
 1) The actual scalar types stored in NSNumber using an @encode() statement
 2) BOOL mappings require the special OX_ENCODED_BOOL constant because @encode(BOOL) returns 'c', the mapping for char types
 3) Element names that do not match property names
 
 SAXy figures out everything else automatically. For example it can see that the 'date' property is an NSDate type and
 maps it accordingly.  Likewise, it figures out the relationship between the two object via the 'user' property.
 
 Also twitter does not use the standard XML date format, so we register a custom NSDateFormatter that parses twitter dates.
 The date formatter is registered with a stand-alone context instance, that is passed to both the reader and writer.
 */
- (void)testReaderAndWrite
{
    OXmlElementMapper *rootMapper = [OXmlElementMapper rootXPath:@"/statuses/status" toMany:[OXTweet class]];
    
    OXmlElementMapper *tweetMapper = [[[[[[OXmlElementMapper elementClass:[OXTweet class]]
                                          xpath:@"id" property:@"key" scalarType:@encode(unsigned long)]
                                         xpath:@"created_at" property:@"date"]
                                        tag:@"retweeted" scalarType:OX_ENCODED_BOOL]
                                       tag:@"truncated" scalarType:OX_ENCODED_BOOL]
                                      tag:@"favorited" scalarType:OX_ENCODED_BOOL];
    
    OXmlElementMapper *userMapper = [[[OXmlElementMapper elementClass:[OXTwitterUser class]]
                                      xpath:@"id" property:@"key" scalarType:@encode(unsigned long)]
                                     tagMap:@{
                                     @"screen_name":       @"screenName",
                                     @"description":       @"about",
                                     @"profile_image_url": @"image",
                                     @"followers_count":   @"followers",
                                     @"friends_count":     @"friends",
                                     @"favourites_count":  @"favourites",
                                     @"statuses_count":    @"posts",
                                     @"listed_count":      @"listed",
                                     @"created_at":        @"date"
                                     }];
    
    //shared mapper instance:
    OXmlMapper *mapper = [[OXmlMapper mapper] elements:@[rootMapper, tweetMapper, userMapper]];
    
    //use shared context configured to handle twitter date formatting:
    OXmlContext *context = [[OXmlContext alloc] init];
    NSDateFormatter *twitterDateFormatter = [[NSDateFormatter alloc] init];
    [twitterDateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [twitterDateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
    [context.transform registerDefaultDateFormatter:twitterDateFormatter];
    
    //create and invoke a reader on a twitter feed
    OXmlReader *reader = [OXmlReader readerWithContext:context mapper:mapper];
    NSArray *tweets = [reader readXmlFile:@"BarackObamaTwitterFeed.xml"];
    STAssertTrue([tweets count] > 0, @"tweets read");
    OXTweet *tweet = [tweets objectAtIndex:0];
    STAssertNotNil(tweet.user, @"got the tweeter");
    STAssertEqualObjects(@"BarackObama", tweet.user.screenName, @"screenName == 'BarackObama'");
    STAssertEqualObjects([NSNumber numberWithUnsignedLong:813286], tweet.user.key, @"id == '813286'");
    STAssertEqualObjects([NSURL URLWithString:@"http://www.barackobama.com"], tweet.user.url, @"url == 'http://www.barackobama.com'");
    STAssertEqualObjects([twitterDateFormatter dateFromString:@"Mon Mar 05 22:08:25 +0000 2007"], tweet.user.date, @"date == 'Mon Mar 05 22:08:25 +0000 2007'");
    
    //create and invoke a writer
    OXmlWriter *writer = [[OXmlWriter writerWithMapper:mapper context:context] rootAttributes:@{@"type":@"array"}];
    NSString *xml = [writer writeXml:tweets];
    //NSLog(@"xml = %@", xml);
    STAssertNotNil(xml, @"wrote some xml");
}



/**
 This example refines the data handling by caching user instances to eliminate duplicates.
 
 A custom setter block checks a cache for pre-existing OXTwitterUser instances before setting them on the
 OXTweet instance.  For the cache we use the 'userData' NSDictionary in the OXContext class which is provided
 by SAXy for just such proposes.
 */
- (void)testReaderAndWriteWithCachedUsers
{
    //use custom setter block to cache unique user instances and ignore duplicates:
    OXmlXPathMapper *userPathMapper = [[OXmlXPathMapper xpath:@"user"]
                                       setter: ^(NSString *property, id value, id target, OXContext *ctx) {
                                           OXTwitterUser *user = (OXTwitterUser *)value;
                                           OXTwitterUser *cachedUser = [ctx.userData objectForKey:user.key];  //already in cache?
                                           if (cachedUser) {                 //yes: use cached version, discard new user
                                               user = cachedUser;
                                           } else {                            //no: save user in cache
                                               [ctx.userData setObject:user forKey:user.key];
                                           }
                                           if (((OXmlContext *)ctx).logReaderStack)
                                               NSLog(@"  end: %@ - %@.%@ += '%@', cached:%@", [(OXmlContext*)ctx tagPath], target, property, user, cachedUser ? @"true":@"false");
                                           [target setValue:user forKey:property];  //set using KVC
                                       }]
    ;
    
    OXmlElementMapper *rootMapper = [OXmlElementMapper rootXPath:@"/statuses/status" toMany:[OXTweet class]];
    
    OXmlElementMapper *tweetMapper = [[[[[[[OXmlElementMapper elementClass:[OXTweet class]]
                                           xpath:@"id" property:@"key" scalarType:@encode(unsigned long)]
                                          xpath:@"created_at" property:@"date"]
                                         tag:@"retweeted" scalarType:OX_ENCODED_BOOL]
                                        tag:@"truncated" scalarType:OX_ENCODED_BOOL]
                                       tag:@"favorited" scalarType:OX_ENCODED_BOOL]
                                      xpathMapper:userPathMapper]
    ;
    
    
    OXmlElementMapper *userMapper = [[[OXmlElementMapper elementClass:[OXTwitterUser class]]
                                      xpath:@"id" property:@"key" scalarType:@encode(unsigned long)]
                                     tagMap:@{
                                     @"screen_name":       @"screenName",
                                     @"description":       @"about",
                                     @"profile_image_url": @"image",
                                     @"followers_count":   @"followers",
                                     @"friends_count":     @"friends",
                                     @"favourites_count":  @"favourites",
                                     @"statuses_count":    @"posts",
                                     @"listed_count":      @"listed",
                                     @"created_at":        @"date"
                                     }]
    ;
    
    //shared mapper instance:
    OXmlMapper *mapper = [[OXmlMapper mapper] elements:@[rootMapper, tweetMapper, userMapper]];
    
    //use shared context configured to handle twitter date formatting:
    OXmlContext *context = [[OXmlContext alloc] init];
    NSDateFormatter *twitterDateFormatter = [[NSDateFormatter alloc] init];
    [twitterDateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [twitterDateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
    [context.transform registerDefaultDateFormatter:twitterDateFormatter];
    
    //create and invoke a reader on a twitter feed
    OXmlReader *reader = [OXmlReader readerWithContext:context mapper:mapper];
    NSArray *tweets = [reader readXmlFile:@"BarackObamaTwitterFeed.xml"];
    
    //test for no duplicate OXTwitterUser instances with the same id
    STAssertTrue([tweets count] > 0, @"tweets read");
    OXTwitterUser *cachedUser = [context.userData objectForKey:[NSNumber numberWithUnsignedLong:813286]];
    STAssertNotNil(cachedUser, @"cachedUser in cache");
    for(OXTweet *tweet in tweets) {
        STAssertEquals(cachedUser, tweet.user, @"some instance of user");
    }
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
