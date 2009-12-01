#import <Foundation/Foundation.h>

#include <unistd.h>

#import "DocumentBuilder.h"
#import "NSString+RelativePath.h"


void setupBuilder(DocumentBuilder *builder, int argc, const char *argv[])
{
    NSString *currentDirPath = [NSString stringWithUTF8String:(const char *)getcwd(NULL, 0)];
    
    [builder setSourceDirPath:currentDirPath];
    [builder setDestDirPath:currentDirPath];
    [builder setUsesDocsetPackage:NO];
    [builder setIsVerbose:NO];
    [builder setSearchesRecursively:NO];
    [builder setUpdatesOuterDocsOnly:NO];

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "-help") == 0) {
            [NSException raise:@"Help" format:@"", nil];
        }
        
        else if (strcmp(argv[i], "-docset") == 0) {
            [builder setUsesDocsetPackage:YES];
        }

        else if (strcmp(argv[i], "-r") == 0) {
            [builder setSearchesRecursively:YES];
        }
        
        else if (strcmp(argv[i], "-verbose") == 0) {
            [builder setIsVerbose:YES];
        }

        else if (strcmp(argv[i], "-d") == 0) {
            i++;
            if (i >= argc) {
                [NSException raise:@"Error" format:@"Option -d requires an argument."];
            }
            const char *cPath = argv[i];
            NSString *path = [NSString stringWithUTF8String:cPath];
            if ([path characterAtIndex:0] != '/') {
                path = [path relativePathToAbsolutePathWithBasePath:currentDirPath];
            }
            [builder setDestDirPath:path];
        }
        
        else if (strcmp(argv[i], "-s") == 0) {
            i++;
            if (i >= argc) {
                [NSException raise:@"Error" format:@"Option -s requires an argument."];
            }
            const char *cPath = argv[i];
            NSString *path = [NSString stringWithUTF8String:cPath];
            if ([path characterAtIndex:0] != '/') {
                path = [path relativePathToAbsolutePathWithBasePath:currentDirPath];
            }
            [builder setSourceDirPath:path];
        }

        else if (strcmp(argv[i], "-t") == 0) {
            i++;
            if (i >= argc) {
                [NSException raise:@"Error" format:@"Option -t requires an argument."];
            }
            const char *cPath = argv[i];
            NSString *path = [NSString stringWithUTF8String:cPath];
            if ([path characterAtIndex:0] != '/') {
                path = [path relativePathToAbsolutePathWithBasePath:currentDirPath];
            }
            [builder setTemplateDirPath:path];
        }
        
        else if (strcmp(argv[i], "-u") == 0) {
            [builder setUpdatesOuterDocsOnly:YES];
        }
        
        else {
            [NSException raise:@"Error" format:@"Invalid flag: %s", argv[i]];
        }
    }
}

void outputHelp()
{
    printf("Usage: docsetmaker [options]\n");
    printf("\n");
    printf("-d <directory>      Destination directory for output files\n");
    printf("-docset             Output files will be put in a DocSet package\n");
    printf("-help               Display command line options and exit\n");
    printf("-r                  Search target header files recursively from spcecified source directory\n");
    printf("-s <directory>      Source directory for target header files\n");
    printf("-t <directory>      Template directory\n");
    printf("-verbose            Output messages about what docsetmaker is doing\n");
}

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];

    BOOL hasSetupError = YES;
    DocumentBuilder *builder = [DocumentBuilder new];
    @try {
        setupBuilder(builder, argc, argv);
        hasSetupError = NO;

        [builder build];
        
        [builder release];
    } @catch(NSException *e) {

        if (![[e name] isEqualToString:@"Help"]) {
            printf("Error: %s\n", [[e reason] cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        
        if (hasSetupError) {
            outputHelp();
        }

        [builder release];
        [pool drain];
        return -1;
    }

    [pool release];

    return 0;
}


