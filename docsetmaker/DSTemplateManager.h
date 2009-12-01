//
//  DSTemplateManager.h
//  docsetmaker
//
//  Created by numata on 09/09/20.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DSTemplate.h"


typedef enum {
    DSTemplateTypeIndex,
    DSTemplateTypeList,
    DSTemplateTypeTOC,
    DSTemplateTypeFunction,
    DSTemplateTypeClass,
    DSTemplateTypeStruct,
    DSTemplateTypeDataType,
} DSTemplateType;


@interface DSTemplateManager : NSObject {
    NSString *mTemplateDirPath;
}

- (id)initWithPath:(NSString *)path;

- (DSTemplate *)templateForType:(DSTemplateType)type;
- (void)copyAdditionalFilesToPath:(NSString *)basePath;

@end
