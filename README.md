SAXy OX - Objective-C XML and JSON Binding Library
====

SAXy OX is a full-featured XML and JSON marshalling framework for Objective-C.  It's purpose is to allow domain objects to
be serialized to XML or JSON with a minimal amount of coding.

Features include:

 * efficient reading/unmarshalling and writing/marshalling of XML from domain objects
 * full XML namespace support
 * built-in type conversion and formatting
 * highly configurable API
 * modern Objective-C: ARC and blocks
 * self-reflective automatic mapping
 * optimized for iOS with no no third-party dependencies


There are several well-documented examples in the SAXyTests folder, including:

 * [OXTutorialTests](SAXyTests/OXTutorialTests.m) - a step-by-step introduction to SAXy's features - START HERE!
 * [OXTwitterTests](SAXyTests/OXTwitterExampleTests.m)  - a classic twitter read and write example
 * [OXiTunesTests](SAXyTests/OXiTunesRSSExampleTests.m)   - an advanced mixed namespace iTunes RSS mapping example
 * [OXmlNonKVCTests](SAXyTests/OXmlNonKVCTests.m) - simple KVC and complex non-KVC-compliant mapping examples 
 * [OXJSONTests](SAXyTests/OXJSONTests.m) - a detailed JSON read and write example


Usage tips

 * run the examples (Product->Test in Xcode), set break points to inspect state 
 * watch the mapper in action by setting: reader.context.logReaderStack = YES;
 * create your own mapping by starting with a working example and making small modifications


As an example, given the class:

    @interface CartoonCharacter : NSObject
      @property(nonatomic)NSString *firstName;
      @property(nonatomic)NSString *lastName;
    @end

A SAXy mapper and reader can be defined in just a few lines of code:

    NSString *xml = @"<tune><first>Daffy</first><last>Duck</last></tune>";
    
    OXmlReader *reader = [OXmlReader readerWithMapper:          //declares a reader with embedded mapper
                          [[OXmlMapper mapper] elements:@[
                           [OXmlElementMapper rootXPath:@"/tune" type:[CartoonCharacter class]]
                           ,
                           [[[OXmlElementMapper elementClass:[CartoonCharacter class]]
                             xpath:@"first" property:@"firstName"]
                            xpath:@"last" property:@"lastName"]
                           ]]
                          ];
    
    CartoonCharacter *tune = [reader readXmlText:xml];          //reads xml
    
    STAssertEqualObjects(@"Daffy", tune.firstName, @"mapped 'first' element to 'firstName' property");
    STAssertEqualObjects(@"Duck",  tune.lastName,  @"mapped 'last'  element to 'lastName'  property");

 
