/**
 * Convience methods for all NSObject classes.
 * This catagory provedes methods to obtain an L4Logger instance from all classes and instances.
 * You may want to override these methods in your local base class and provide caching local iVar,
 * since these methods result in an NSDictionary lookup each time they are called.  Actually it's 
 * not a bad hit, but in a high volume logging environment, it might make a difference.
 *
 * Here is an example of what that might look like:
 * \code
 CODE TO ADD TO YOUR BASE CLASS .h file declarations
 
 L4Logger *myLoggerIVar; // instance variable

 
 CODE TO ADD TO YOUR BASE CLASS .m file
 
 static L4Logger *myLoggerClassVar; // static "class" variable
 
 + (L4Logger *) log 
 {
 if( myLoggerClassVar == nil ) {
 myLoggerClassVar = [super logger];  
 }
 
 return myLoggerClassVar;
 }
 
 - (L4Logger *) log
 {
 if( myLoggerIVar == nil ) {
 myLoggerIVar = [super logger];  
 }
 
 return myLoggerIVar;
 }
 * \endcode
 * For copyright & license, see COPYRIGHT.txt.
 */

#import <Cocoa/Cocoa.h>
@class L4Logger;

@interface NSObject (Log4Cocoa)

+ (L4Logger *) l4Logger;
- (L4Logger *) l4Logger;
@end