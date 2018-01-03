//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface OWSSharedStorage : OWSStorage

+ (void)protectFiles;

// NOTE: Do not cache references to this connection elsewhere.
//
// OWSSharedStorage will close the database when the app is in the background,
// which will invalidate thise connection.
- (YapDatabaseConnection *)dbConnection;

- (void)addClient;
- (void)removeClient;

@end

NS_ASSUME_NONNULL_END
