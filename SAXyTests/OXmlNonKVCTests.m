//
//  OXmlNonKVCTests.m
//  SAXy OX - Object-to-XML mapping library
//
//  Demonstrates KVC-compliant and non-KVC compliant mappings.
//
//  The KVC-compliant example is trivial in it's simplicity.
//
//  The non-KVC compliant example is not trivial, but demonstrates SAXy's most advanced features: 
//  1) proxies
//  2) custom getter and setter blocks
//  3) virtual properties
//  4) mapper locking
//  5) manual configuration of 'result' property
//
//  Created by Richard Easterling on 2/16/13.
//  Copyright (c) 2013 Outsource Cafe, Inc. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "OXmlMapper.h"
#import "OXmlElementMapper.h"
#import "OXmlContext.h"
#import <CoreLocation/CLLocation.h>
#import "OXmlReader.h"
#import "OXmlWriter.h"
#import "OXUtil.h"

////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - test class
////////////////////////////////////////////////////////////////////////////////////////


@interface OXLocation : NSObject
@property(nonatomic)CLLocationDegrees latitude;
@property(nonatomic)CLLocationDegrees longitude;
@property(nonatomic)CLLocationDistance altitude;
@property(nonatomic)CLLocationAccuracy horizontalAccuracy;
@property(nonatomic)CLLocationAccuracy verticalAccuracy;
@property(nonatomic)CLLocationDirection course;
@property(nonatomic)CLLocationSpeed speed;
@property(nonatomic)NSDate *timestamp;
- (CLLocation *)toCLLocation;
@end

@implementation OXLocation
- (CLLocation *)toCLLocation
{
    return [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(self.latitude, self.longitude)
                                         altitude:self.altitude
                               horizontalAccuracy:self.horizontalAccuracy
                                 verticalAccuracy:self.verticalAccuracy
                                           course:self.course
                                            speed:self.speed
                                        timestamp:self.timestamp];
}
@end


////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - tests
////////////////////////////////////////////////////////////////////////////////////////

@interface OXmlNonKVCTests : SenTestCase  @end

@implementation OXmlNonKVCTests


/**
 Many KVC compliant mappings can be trivial, especialy if element names match property names, and attributes
 and mixed namespaces are avoided.
 
 The mapping for KVC-compliant OXLocation occurs automaticly, each property being mapped to an element of the 
 same name.  By default, scalar properties with zero values are treated as nil avoiding output like: <course>0</course>
 Unspecified elements/properties are mapped in alphabetical order: altitude, latitude, longitude
 */
- (void)testKVC_ComplientReaderWriter
{
    //Declare a mapper with a root and a 'location' element that maps to a single OXLocation instance.
    OXmlMapper *mapper = [[OXmlMapper mapper] elements:@[ [OXmlElementMapper rootXPath:@"/location" type:[OXLocation class]] ]];
    
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];                      //Create a reader
    reader.context.logReaderStack = NO;                                             //log mapping
    
    NSString *xml1 = @"<location><altitude>3988.2</altitude><latitude>39.112233</latitude><longitude>-114.112233</longitude></location>";
    OXLocation *loc = [reader readXmlText:xml1];                                    //read xml
    
    STAssertEquals(3988.2, loc.altitude, @"loc.altitude==3988.2");
    STAssertEquals(39.112233, loc.latitude, @"loc.latitude==39.112233");
    STAssertEquals(-114.112233, loc.longitude, @"loc.longitude==-114.112233");
    
    OXmlWriter *writer = [OXmlWriter writerWithMapper:mapper];                      //Create a writer
    writer.xmlHeader = nil;                                                         //don't emit xml header:
    
    NSString *xml2 = [writer writeXml:loc prettyPrint:NO];
    STAssertEqualObjects(xml1, xml2, @"input xml == output xml");
}

/**
 CLLocation is a non-KVC compliant class and mapping it requires using SAXy's most advanced features. 
 
 Marshalling - CLLocation can be used directly for writing, but several challenges must be overcome:
    1) latitude and longitude are not real properties
        solution: create virtual, read-only properties using custom getter blocks
    2) timestamp allways returns a date instance even if instantiated with a nil
        solution: identify nil dates using 'timeIntervalSinceReferenceDate' in a custom getter block
    3) CLLocation has problematic hidden properties
        solution: declare desired properties, then lock mapping, preventing self-reflection scan

 Unmarshalling - CLLocation's properties can't be set individualy, but must be set all at once in the constructor.
 A SAXy work-around is to use a KVC-compliant equivalent class as a proxy.  The proxy in this case will be OXLocation
 configured by using the 'proxyClass' builder method.  SAXy will load the OXLocation mapper, push a new OXLocation 
 intance on the stack and populate its properties.  The only manual step required is to override the setter method,
 swapping the proxy for the desired object before the assignment is made. In this case, the setter is the root 
 element's 'result' setter.
 */
- (void)testNonKVC_ComplientReaderWriter
{
    OXmlMapper *mapper = [[OXmlMapper mapper] elements:@[
                          
                          //Map the root element, overriding its 'result' setter. We swap the OXLocation
                          //instance with a CLLocation instance via the 'toCLLocation' method:
                          [[OXmlElementMapper root]
                           xpathMapper:[[[OXmlXPathMapper xpath: @"location"
                                                         type: [CLLocation class]
                                                       property: @"result"]
                                         proxyClass: [OXLocation class]]
                                        setter: ^(NSString *path, id value, id target, OXContext *ctx) {
                                            //take the proxy (OXLocation) and convert it to the expected type (CLLocation):
                                            CLLocation *loc = [value isMemberOfClass:[OXLocation class]] ? [value toCLLocation] : value;
                                            [target setValue:loc forKey:path];  //basiclly: ctx.result = loc;
                                        }]
                           ],
                          
                          //map CLLocation for writing/marshalling.  Proxies are not used (or needed) for writing.
                          [[[[[[OXmlElementMapper elementClass:[CLLocation class]]
                              xpathMapper:[[[[OXmlXPathMapper xpath:@"latitude" scalar:@encode(CLLocationDegrees) property:@"latitude"]
                                             setter:^(NSString *key, id value, id target, OXContext *ctx) {
                                                 NSAssert(NO, @"NOOP - CLLocation.coordinate.latitude is readonly, setter should never be called");
                                             }]
                                            getter:^(NSString *key, id target, OXContext *ctx) {
                                                CLLocation *loc = target;
                                                return loc ? [NSString stringWithFormat:@"%f", loc.coordinate.latitude] : nil;
                                            }]
                                           isVirtualProperty]   //this sets a flag that prevents property validation against CLLocation
                              ]
                             xpathMapper:[[[[OXmlXPathMapper xpath:@"longitude" scalar:@encode(CLLocationDegrees) property:@"longitude"]
                                            setter:^(NSString *key, id value, id target, OXContext *ctx) {
                                                NSAssert(NO, @"NOOP - CLLocation.coordinate.longitude is readonly, setter should never be called");
                                            }]
                                           getter:^(NSString *key, id target, OXContext *ctx) {
                                               CLLocation *loc = target;
                                               return loc ? [NSString stringWithFormat:@"%f", loc.coordinate.longitude] : nil;
                                           }]
                                          isVirtualProperty]
                             ]
                            xpathMapper:[[OXmlXPathMapper xpath:@"timestamp" type:[NSDate class] property:@"timestamp"]
                                          getter:^(NSString *key, id target, OXContext *ctx) {
                                              //fix date handling - return nil if time interval is zero
                                              NSDate *date = [target timestamp];
                                              NSTimeInterval interval = date ? [date timeIntervalSinceReferenceDate] : 0.0;
                                              NSString *result = (interval == 0.0) ? nil : ctx.currentMapper.fromTransform(date, ctx);
                                              return result;
                                          }]
                            ]
                            tags:@[@"altitude",@"horizontalAccuracy",@"verticalAccuracy",@"course",@"speed"]]
                           lockMapping] //prevents self-reflective discovery of additional/hidden properties
    ]];
    
    OXmlReader *reader = [OXmlReader readerWithMapper:mapper];
    reader.context.logReaderStack = NO;
    
    NSString *xml1 = @"<location><latitude>39.112233</latitude><longitude>-114.112233</longitude><altitude>3988.2</altitude></location>";
    CLLocation *loc = [reader readXmlText:xml1];
    
    STAssertEquals(3988.2, loc.altitude, @"altitude");
    STAssertEquals(39.112233, loc.coordinate.latitude, @"loc.coordinate.latitude==39.112233");
    STAssertEquals(-114.112233, loc.coordinate.longitude, @"loc.coordinate.longitude==-114.112233");
    
    OXmlWriter *writer = [OXmlWriter writerWithMapper:mapper];
    writer.xmlHeader = nil;
    
    NSString *xml2 = [writer writeXml:loc prettyPrint:NO];
    //Notice that element ordering is determined by mapping declaration order: latitude, longitude, altitude
    STAssertEqualObjects(xml1, xml2, @"input xml == output xml"); 
    
    //uncomment to see hidden properties in CLLocation:
    //[OXUtil propertyInspectionForClass:[CLLocation class] withBlock:^(NSString *propertyName, Class propertyClass, const char *attributes) {
    //    NSLog(@"%@:%@ [%s]", propertyName, NSStringFromClass(propertyClass), attributes);
    //}];
}

@end
