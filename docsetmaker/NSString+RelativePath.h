//
//  NSString+RelativePath.h
//  docsetmaker
//
//  Created by numata on 09/09/19.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (RelativePath)

- (NSString *)relativePathToAbsolutePathWithBasePath:(NSString *)basePath;

@end


