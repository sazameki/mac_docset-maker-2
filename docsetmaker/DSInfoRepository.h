//
//  DSInfoRepository.h
//  DocSet Maker
//
//  Created by numata on 09/09/13.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DSTemplateManager.h"


@class DSInformation;


@interface DSInfoRepository : NSObject {
    NSMutableArray  *mGroupInfos;
    NSString        *mBaseRubyScript;
}

+ (DSInfoRepository *)sharedRepository;

- (void)clearAllInfos;

- (void)addInfos:(NSArray *)infos;

- (NSArray *)groupInfos;
- (NSArray *)sortedGroupInfos;

- (NSArray *)groupNames;
- (DSInformation *)groupInfoForName:(NSString *)groupName;

- (NSArray *)allInfosWithTag:(NSString *)tagName;
- (NSArray *)allInfosWithTags:(NSArray *)tagNames;

- (void)outputVerboseInformation;

- (NSString *)setupRubyScriptForType:(DSTemplateType)type baseInfo:(DSInformation *)baseInfo;

@end




