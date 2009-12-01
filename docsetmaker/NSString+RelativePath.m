//
//  NSString+RelativePath.m
//  docsetmaker
//
//  Created by numata on 09/09/19.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "NSString+RelativePath.h"
#import "NSString+Tokenizer.h"


@implementation NSString (RelativePath)

- (NSString *)relativePathToAbsolutePathWithBasePath:(NSString *)basePath
{
    NSString *ret = basePath;

    NSEnumerator *components = [self tokenize:@"/"];
    
    NSString *aComponent = nil;
    while (aComponent = [components nextObject]) {
        if ([aComponent isEqualToString:@"."]) {
            // Do nothing.
        } else if ([aComponent isEqualToString:@".."]) {
            ret = [ret stringByDeletingLastPathComponent];
        } else {
            ret = [ret stringByAppendingPathComponent:aComponent];
        }
    }
    
    return ret;
}

@end

