//
//  NSString+Tokenizer.h
//  Cocoa Browser Air
//
//  Created by numata on 08/05/03.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (Tokenizer)

- (NSEnumerator *)tokenize;
- (NSEnumerator *)tokenize:(NSString *)delimiters;

@end
