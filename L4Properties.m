/**
 * For copyright & license, see COPYRIGHT.txt.
 */

#import "L4Properties.h"
#import "L4LogLog.h"

static NSString *L4PropertiesCommentChar = @"#";
static NSString *DELIM_START = @"${";
static int DELIM_START_LEN = 2;
static NSString *DELIM_STOP = @"}";
static int DELIM_STOP_LEN = 1;


@interface L4Properties (Private)
- (void) replaceEnvironmentVariables;

/**
 * A helper method that takes a string - typically a token from the properties file - and returnes the value
 * of the environment variable with the same name.
 *
 * @param the token to obtain the environemnt value for.
 * @return the value of the environemnt variable, or aString if no environment variable exists.
 */
- (NSString *) substituteEnvironmentVariablesForString:(NSString *) aString;
@end

@implementation L4Properties
/* ********************************************************************* */
#pragma mark Class methods
/* ********************************************************************* */
+ (id) propertiesWithFileName:(NSString *) aName
{
 	return [[[L4Properties alloc] initWithFileName: aName] autorelease];
}

+ (id) propertiesWithProperties:(NSDictionary *) aProperties
{
 	return [[[L4Properties alloc] initWithProperties: aProperties] autorelease];
}

/* ********************************************************************* */
#pragma mark Instance methods
/* ********************************************************************* */

- (NSArray *) allKeys
{
 	return [properties allKeys];
}

- (int) count
{
 	return [properties count];
}

- (void)dealloc
{
	[properties release];
	properties = nil;
 	
	[super dealloc];
}

- (NSString *) description
{
 	return [properties description];
}

- (id) init
{
	return [self initWithFileName: nil];
}

- (id) initWithFileName:(NSString *) aName
{
	if ( self = [super init] ) {
		properties = [[NSMutableDictionary dictionary] retain];
  		
  		NSString *fileContents = [NSString stringWithContentsOfFile:aName];
  		
  		NSEnumerator *lineEnum = [[fileContents componentsSeparatedByString:@"\n"] objectEnumerator];
  		NSString *currentLine = nil;
  		while ( ( currentLine = [lineEnum nextObject] ) != nil ) {
			currentLine = [currentLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				
			NSString *linePrefix = nil;
			if ( [currentLine length] >= [L4PropertiesCommentChar length] ) {
 				linePrefix = [currentLine substringToIndex:[L4PropertiesCommentChar length]];
			}
				
			if ( ![L4PropertiesCommentChar isEqualToString:linePrefix] ) {
				NSRange range = [currentLine rangeOfString:@"="];
				
				if ( ( range.location != NSNotFound ) && ( [currentLine length] > range.location + 1 ) ) {
					[properties setObject:[currentLine substringFromIndex:range.location + 1]
								   forKey:[currentLine substringToIndex:range.location]];
				}
			}
  		}
	}
	[self replaceEnvironmentVariables];
	return self;
}

- (id) initWithProperties:(NSDictionary *) aProperties
{
	if ( self = [super init] ) {
  		properties = [aProperties retain];
 	}
 	
 	return self;
}

- (void) removeStringForKey:(NSString *) aKey
{
 	[properties removeObjectForKey: aKey];
}

- (void) setString:(NSString *) aString forKey:(NSString *) aKey
{
 	[properties setObject: aString forKey: aKey];
}

- (NSString *) stringForKey:(NSString *) aKey
{
 	return [self stringForKey: aKey withDefaultValue: nil];
}

- (NSString *) stringForKey:(NSString *) aKey withDefaultValue:(NSString *) aDefaultVal
{
 	NSString *string = [properties objectForKey: aKey];
 	
 	if ( string == nil ) {
  		return aDefaultVal;
 	} else {
  		return string;
 	}
}

- (L4Properties *) subsetForPrefix:(NSString *) aPrefix
{
 	NSMutableDictionary *subset = [NSMutableDictionary dictionaryWithCapacity: [properties count]];
 	
 	NSEnumerator *keyEnum = [[properties allKeys] objectEnumerator];
 	NSString *key = nil;
 	while ( ( key = [keyEnum nextObject] ) != nil ) {
  		NSRange range = [key rangeOfString: aPrefix options: 0 range: NSMakeRange(0, [key length])];
  		if ( range.location != NSNotFound ) {
			NSString *subKey = [key substringFromIndex: range.length];
			[subset setObject: [properties objectForKey: key] forKey: subKey];
  		}
 	}
 	
 	return [L4Properties propertiesWithProperties: subset];
}

/* ********************************************************************* */
#pragma mark Private methods
/* ********************************************************************* */
- (void) replaceEnvironmentVariables
{
 	NSEnumerator *keyEnum = [[self allKeys] objectEnumerator];
 	NSString *key = nil;
 	while ( ( key = [keyEnum nextObject] ) != nil ) {
  		NSString *value = [self stringForKey:key];
  		NSString *subKey = [self substituteEnvironmentVariablesForString:key];
  		if ( ![subKey isEqualToString:key] ) {
			[self removeStringForKey:key];
			[self setString:subKey forKey:value];
  		}
  		NSString *subVal = [self substituteEnvironmentVariablesForString:value];
  		if ( ![subVal isEqualToString:value] ) {
			[self setString:subVal forKey:subKey];
  		}
 	}
}

- (NSString *) substituteEnvironmentVariablesForString:(NSString *) aString
{
 	int len = [aString length];
 	NSMutableString *buf = [NSMutableString string];
 	NSRange i = NSMakeRange(0, len);
 	NSRange j, k;
 	while ( true ) {
  		j = [aString rangeOfString:DELIM_START options:0 range:i];
  		if ( j.location == NSNotFound ) {
			if ( i.location == 0 ) {
				return aString;
			} else {
				[buf appendString: [aString substringFromIndex:i.location]];
				return buf;
			}
  		} else {
			[buf appendString: [aString substringWithRange:NSMakeRange(i.location, j.location - i.location)]];
			k = [aString rangeOfString:DELIM_STOP options:0 range:NSMakeRange(j.location, len - j.location)];
			if ( k.location == NSNotFound ) {
				[L4LogLog error: 
				 [NSString stringWithFormat: @"\"%@\" has no closing brace. Opening brace at position %@.", 
				  aString, [NSNumber numberWithInt:j.location]]];
				return aString;
			} else {
				j.location += DELIM_START_LEN;
				j = NSMakeRange(j.location, k.location - j.location);
				NSString *key = [aString substringWithRange:j];
				char *replacement = getenv([key UTF8String]);
				if ( replacement != NULL ) {
					[buf appendString: [NSString stringWithUTF8String: replacement]];
				}
				i.location += (k.location + DELIM_STOP_LEN);
				i.length -= i.location;
			}
  		}
 	}
}

@end
