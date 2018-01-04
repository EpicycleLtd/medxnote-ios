//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OWSFileSystem : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (void)protectFileOrFolderAtPath:(NSString *)path;

+ (NSString *)appDocumentDirectoryPath;

+ (NSString *)appSharedDataDirectoryPath;

+ (NSString *)cachesDirectoryPath;

+ (void)moveAppFilePath:(NSString *)oldFilePath
     sharedDataFilePath:(NSString *)newFilePath
          exceptionName:(NSString *)exceptionName;

// Returns NO IFF the directory does not exist and could not be created.
+ (BOOL)ensureDirectoryExists:(NSString *)dirPath;

+ (void)deleteFile:(NSString *)filePath;

+ (void)deleteFileIfExists:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
