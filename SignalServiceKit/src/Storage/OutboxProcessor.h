//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

//@class Environment;

NS_ASSUME_NONNULL_BEGIN

@class OWSStorage;

@interface OutboxProcessor : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)sharedManager;

+ (void)asyncRegisterPrimaryDatabaseExtensions:(OWSStorage *)storage;
+ (void)asyncRegisterOutboxDatabaseExtensions:(OWSStorage *)storage;

@end

NS_ASSUME_NONNULL_END
