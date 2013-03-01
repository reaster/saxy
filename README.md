SAXy OX - Objective-C Object-to-XML Marshalling Library
====

SAXy OX is a full-featured XML marshalling framework for Objective-C.  

It supports

 * reading and writing xml from object hierarchies
 * full namespace support
 * built-in type conversion
 * extensive configuration options
 * modern Objective-C: ARC and blocks
 * automatic discovery of mapping details


There are several well-documented  examples in the SAXyTests folder, including:

 * OXTutorialTests - a step-by-step introduction to SAXy's features - START HERE!
 * OXTwitterTests  - a classic twitter read and write example
 * OXiTunesTests   - an advanced mixed namespace iTunes RSS mapping example
 * OXmlNonKVCTests - simple KVC and complex non-KVC-compliant mapping examples 


Usage tips

 * Run the examples (Product->Test in Xcode), set break points to inspect state 
 * watch the mapper in action by setting: reader.context.logReaderStack = YES;
 * create your own mapping by starting with a working example and making small modifications


As an example, given the class:

    @interface CartoonCharacter : NSObject
      @property(nonatomic)NSString *firstName;
      @property(nonatomic)NSString *lastName;
    @end

A SAXy mapping looks like this:

    NSString *xml = @"<tune><first>Daffy</first><last>Duck</last></tune>";
    
    OXmlReader *reader = [OXmlReader readerWithMapper:          //declare a reader with embedded mapper
                          [[OXmlMapper mapper] elements:@[
                           [OXmlElementMapper rootXPath:@"/tune" type:[CartoonCharacter class]]
                           ,
                           [[[OXmlElementMapper elementClass:[CartoonCharacter class]]
                             xpath:@"first" property:@"firstName"]
                            xpath:@"last" property:@"lastName"]
                           ]]
                          ];
    
    CartoonCharacter *duck = [reader readXmlText:xml];          //read xml
    
    STAssertEqualObjects(@"Daffy", duck.firstName, @"mapped 'first' element to 'firstName' property");
    STAssertEqualObjects(@"Duck", duck.lastName, @"mapped 'last' element to 'lastName' property");

 
