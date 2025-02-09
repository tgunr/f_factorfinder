//
//  ImportExtension.m
//  FactorFinderImporter
//
//  Created by Dave Carlton on 3/24/23.
//

#import "ImportExtension.h"

@implementation ImportExtension

- (BOOL)updateAttributes:(CSSearchableItemAttributeSet *)attributes forFileAtURL:(NSURL *)contentURL error:(NSError **)error {
    // Add attributes that describe the file at contentURL.
    // Return NO on error, and provide an NSError with details.
    return YES;
}

@end
