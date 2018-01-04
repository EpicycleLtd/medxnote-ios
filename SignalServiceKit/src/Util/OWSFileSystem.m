//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSFileSystem.h"
#import "TSConstants.h"

NS_ASSUME_NONNULL_BEGIN

@implementation OWSFileSystem

+ (void)protectFileOrFolderAtPath:(NSString *)path
{
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) {
        return;
    }

    NSError *error;
    NSDictionary *fileProtection = @{ NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication };
    [[NSFileManager defaultManager] setAttributes:fileProtection ofItemAtPath:path error:&error];

    NSDictionary *resourcesAttrs = @{ NSURLIsExcludedFromBackupKey : @YES };

    NSURL *ressourceURL = [NSURL fileURLWithPath:path];
    BOOL success = [ressourceURL setResourceValues:resourcesAttrs error:&error];

    if (error || !success) {
        OWSProdCritical([OWSAnalyticsEvents storageErrorFileProtection]);
    }
}

+ (NSString *)appDocumentDirectoryPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentDirectoryURL =
        [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [documentDirectoryURL path];
}

+ (NSString *)appSharedDataDirectoryPath
{
    NSURL *groupContainerDirectoryURL =
        [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:SignalApplicationGroup];
    return [groupContainerDirectoryURL path];
}

+ (NSString *)cachesDirectoryPath
{
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    OWSAssert(paths.count >= 1);
    return paths[0];
}

+ (void)moveAppFilePath:(NSString *)oldFilePath
     sharedDataFilePath:(NSString *)newFilePath
          exceptionName:(NSString *)exceptionName
{
    DDLogInfo(@"%@ Moving file or directory from: %@ to: %@", self.logTag, oldFilePath, newFilePath);

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:oldFilePath]) {
        return;
    }
    if ([fileManager fileExistsAtPath:newFilePath]) {
        OWSFail(@"%@ Can't move file or directory from: %@ to: %@; destination already exists.",
            self.logTag,
            oldFilePath,
            newFilePath);
        return;
    }
    
    NSDate *startDate = [NSDate new];
    
    NSError *_Nullable error;
    BOOL success = [fileManager moveItemAtPath:oldFilePath toPath:newFilePath error:&error];
    if (!success || error) {
        NSString *errorDescription =
            [NSString stringWithFormat:@"%@ Could not move file or directory from: %@ to: %@, error: %@",
                      self.logTag,
                      oldFilePath,
                      newFilePath,
                      error];
        OWSFail(@"%@", errorDescription);
        [NSException raise:exceptionName format:@"%@", errorDescription];
    }

    DDLogInfo(@"%@ Moved file or directory from: %@ to: %@ in: %f",
        self.logTag,
        oldFilePath,
        newFilePath,
        fabs([startDate timeIntervalSinceNow]));
}

+ (BOOL)ensureDirectoryExists:(NSString *)dirPath
{
    BOOL isDirectory;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDirectory];
    if (exists) {
        OWSAssert(isDirectory);

        return YES;
    } else {
        DDLogInfo(@"%@ Creating directory at: %@", self.logTag, dirPath);

        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            OWSFail(@"%@ Failed to create directory: %@, error: %@", self.logTag, dirPath, error);
            return NO;
        }
        return YES;
    }
}

+ (void)deleteFile:(NSString *)filePath
{
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    if (error) {
        DDLogError(@"%@ Failed to delete file: %@", self.logTag, error.description);
    }
}

+ (void)deleteFileIfExists:(NSString *)filePath
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [self deleteFile:filePath];
    }
}

@end

NS_ASSUME_NONNULL_END
