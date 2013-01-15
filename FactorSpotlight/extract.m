#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <CoreFoundation/CFPlugInCOM.h>
#import <Foundation/Foundation.h>
#import <stdio.h>
#import <syslog.h>
#import "pms.h"

#import "extract.h"

/* -----------------------------------------------------------------------------
   Step 1
   Set the UTI types the importer supports

   Modify the CFBundleDocumentTypes entry in Info.plist to contain
   an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes
   that your importer can handle

   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 2
   Implement the GetMetadataForFile function

   Implement the GetMetadataForFile function below to scrape the relevant
   metadata from your document and return it as a CFDictionary using standard keys
   (defined in MDItem.h) whenever possible.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 3 (optional)
   If you have defined new attributes, update the schema.xml file

   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.

   Add any custom types that your importer requires to the <attributes> element

   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>

   ----------------------------------------------------------------------------- */

Boolean
assertRegex(NSString * stringToSearch, NSString * regexString)
{
	NSPredicate * regex = [NSPredicate predicateWithFormat: @"SELF MATCHES %@", regexString];

	return [regex evaluateWithObject: stringToSearch];
}

NSString *squeeseString(NSString *string) {
    NSString *squeezed = [string stringByReplacingOccurrencesOfString: @"\t" withString: @" "];
    NSRange range;
    range.location = 0;
    range.length = [squeezed length];
    squeezed = [squeezed stringByReplacingOccurrencesOfString:@"\\s+" withString:@" " options:NSRegularExpressionSearch range:range];
    return squeezed;
}

/* -----------------------------------------------------------------------------
    Get metadata attributes from file

   This function's job is to extract useful information your file format supports
   and return it as a dictionary
   ----------------------------------------------------------------------------- */

Boolean
extract(void * thisInterface,
	NSMutableDictionary *attributes,
	NSString * contentTypeUTI,
	NSString * pathToFile)
{
	/* Pull any available metadata from the file at the specified path */
	/* Return the attribute keys and attribute values in the dict */
	/* Return TRUE if successful, FALSE if there was no data provided */

	NSRange           range, theRange;
	NSString          *version, *author, *description, *uses, *copyright;
	NSArray           * lineComponents;
	NSArray           * lineSubComponents;
	NSMutableArray    * definitions = [NSMutableArray arrayWithCapacity: 128];
	NSMutableArray    * usesArray = [NSMutableArray arrayWithCapacity: 128];
	NSMutableString   * sourceContent = [NSMutableString stringWithCapacity: 4096];

    NSLog(@"FactorSpotlight: %@", pathToFile);

	// Grab our plist for file extensions
	NSBundle     * myBundle = [NSBundle bundleWithIdentifier: @"org.factorcode.spotlight"];
	NSDictionary * bundleDictionary = [myBundle infoDictionary];
	NSArray      * myDocuentTypes = [bundleDictionary objectForKey: @"CFBundleDocumentTypes"];
	NSDictionary * myDocuentTypesDictionary = [myDocuentTypes objectAtIndex: 0];
	NSArray      * myFileExtensions = [myDocuentTypesDictionary objectForKey: @"CFBundleTypeExtensions"];

	// Fallback option for testing
	if ([myFileExtensions count] == 0) {
        PMLOG(1,@"Bundle extensions not found, using default");
		myFileExtensions = [NSArray arrayWithObjects: @"factor", nil];
    }

	NSString * fileExtension = [pathToFile pathExtension];
	NSString * extObject;
	Boolean    extensionOK = NO;
	for (extObject in myFileExtensions) {
		if ([fileExtension isEqualToString: extObject]) {
			extensionOK = YES;
			break;
		}
	}

	if (!extensionOK)
        return NO;
    
	NSStringEncoding fileEncoding;
	NSError        * fileError = nil;
	NSString * fileContent = [NSString stringWithContentsOfFile: pathToFile usedEncoding: &fileEncoding error: &fileError];
	if (!fileContent)
		return NO;

	NSArray * fileLines = nil;
	if (fileContent) {
        // Format content
		fileContent = [fileContent stringByReplacingOccurrencesOfString: @"\r" withString: @"\n"];
		fileContent = [fileContent stringByReplacingOccurrencesOfString: @"\n\n" withString: @"\n"];
		fileLines = [fileContent componentsSeparatedByString: @"\n"];
	}

    NSUInteger fileLineCount = [fileLines count];
    for (int i = 0; i < fileLineCount; i++) {
        NSString *fileLine = squeeseString([fileLines objectAtIndex:i]);
		range.location = 0;
		range.length = [fileLine length];
        //        PMLOG(1, @"Factor File line: %@", aString);
        

		// Look thu header lines to glean info
		// Look for '! Copyright` in the line
		theRange = [fileLine rangeOfString: @"! Copyright" options: NSLiteralSearch range: range];
		// syslog(LOG_ALERT, "Factor File: theRange = %d %d", theRange.location, theRange.length);
		if (theRange.location != NSNotFound) {
			// found it, now split line at the ',` to see if it is an old CVS style tagged file
			lineComponents = [fileLine componentsSeparatedByString: @"! Copyright "];
			if ([lineComponents count] == 2) {
				copyright = [lineComponents objectAtIndex: 1];
                [attributes setObject: copyright
                               forKey: (NSString *)kMDItemCopyright];
            }
        }
        // Look for a description tag
        theRange = [fileLine rangeOfString: @"! Description:" options: NSLiteralSearch range: range];
		if (theRange.location != NSNotFound) {
			// found it, now split line
			lineComponents = [fileLine componentsSeparatedByString: @"! Description: "];
			if ([lineComponents count] == 2) {
				description = [lineComponents objectAtIndex: 1];
                [attributes setObject: description
                               forKey: (NSString *)kMDItemDescription];
            }
        }

		// Find the Version number, if any
        theRange = [fileLine rangeOfString: @"! Version: " options: NSLiteralSearch range: range];
        if (theRange.location != NSNotFound) {
            NSArray  * lineComponents = [fileLine componentsSeparatedByString: @"Version: "];
            version = [lineComponents objectAtIndex: 1];
            version = [version stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
            [attributes setObject: version
                           forKey: (NSString *)kMDItemVersion];
        }
        // Find the Directly Responsible Individual (DRI), if any
        theRange = [fileLine rangeOfString: @"! DRI: " options: NSLiteralSearch range: range];
        if (theRange.location != NSNotFound) {
            NSArray  * lineComponents = [fileLine componentsSeparatedByString: @"DRI: "];
            author = [lineComponents objectAtIndex: 1];
            author = [author stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
            [attributes setObject: author
                           forKey: (NSString *)kMDItemAuthors];
        }

		// Look for other data after the initial header line
		// Find the containing line describing the file uses array
		theRange = [fileLine rangeOfString: @"USING: " options: NSLiteralSearch range: range];
		if (theRange.location != NSNotFound) {
			// found it, now split line at USING:
			lineComponents = [fileLine componentsSeparatedByString: @"USING: "];
            if ([lineComponents count] == 2) {
                fileLine = [lineComponents objectAtIndex: 1];
                // start processing lines until `;' is encountered
                BOOL endOfUSING = NO;
                do {
                    lineSubComponents = [fileLine componentsSeparatedByString: @" "];
                    if ([lineSubComponents count]) {
                        for (uses in lineSubComponents) {
                            endOfUSING = [uses isEqualToString: @";"];
                            if ( ! endOfUSING && [uses length] )
                                [usesArray addObject: uses];
                        }
                    }
                    // possibly process more USINGS lines
                    if (endOfUSING == NO) {
                        i++;
                        if (i < fileLineCount) { // in case no `;' is ever found
                            fileLine = squeeseString([fileLines objectAtIndex:i]);
                            [sourceContent appendString: [NSString stringWithFormat: @"%@\n", fileLine]];
                            range.length = [fileLine length];
                        }
                    }
                } while (endOfUSING == NO);
                [attributes setObject: usesArray
                               forKey: (NSString *)@"public_factor_uses"];
            }
        }

        // Look for additional USE
		theRange = [fileLine rangeOfString: @"USE: " options: NSLiteralSearch range: range];
        if (theRange.location != NSNotFound) {
			// found it, now split line at USE:
			lineComponents = [fileLine componentsSeparatedByString: @"USE: "];
            if ([lineComponents count] == 2) {
                [usesArray addObject: [lineComponents objectAtIndex: 1]];
            }
        }
        
		// Parse for defining words
		if ( assertRegex(fileLine, @"^:\\s*(\\S+)\\s+.*") ||
            assertRegex(fileLine, @"^::\\s*(\\S+)\\s+.*") ||
            assertRegex(fileLine, @"^M:\\s*(\\S+)\\s+.*") ||
            assertRegex(fileLine, @"^M::\\s*(\\S+)\\s+.*") ||
		    assertRegex(fileLine, @"^\\s*(TUPLE:)\\s+(\\S+)\\s+.*") ||
		    assertRegex(fileLine, @"^\\s*(code|CODE)\\s+(\\S+)\\s+.*") ||
		    assertRegex(fileLine, @"^\\s*(tcode|TCODE)\\s+(\\S+)\\s+.*") ) {
			NSArray  * lineComponents = [fileLine componentsSeparatedByString: @" "];
			NSString * definition = [lineComponents objectAtIndex: 1];
			definition = [definition stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
			[definitions addObject: definition];
		}
		// accumulate line
		[sourceContent appendString: [NSString stringWithFormat: @"%@\n", fileLine]];
	}

	// store definitions into metadata
	if ([definitions count] > 0) [attributes setObject: definitions forKey: @"public_factor_definitions"];
    if ([usesArray count] > 0) [attributes setObject: usesArray forKey: (NSString *)@"public_factor_uses"];
	[attributes setObject: @"Factor Source Code File" forKey: (NSString *)kMDItemKind];
	[attributes setObject: sourceContent forKey: (id)kMDItemTextContent];

	return YES;
} /* extract */