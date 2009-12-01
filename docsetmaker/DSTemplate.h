//
//  DSTemplate.h
//  docsetmaker
//
//  Created by numata on 09/09/20.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DSInformation.h"


@interface DSTemplate : NSObject {
    NSString    *mSource;
    int         mType;
}

- (id)initWithPath:(NSString *)path type:(int)type;
- (id)initWithSource:(NSString *)source type:(int)type;

- (void)outputAtPath:(NSString *)path baseInfo:(DSInformation *)baseInfo;

@end

