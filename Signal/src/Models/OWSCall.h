//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSMessageData.h"

NS_ASSUME_NONNULL_BEGIN

@class TSCall;

@interface OWSCall : NSObject <OWSMessageData>

#pragma mark - Initialization

- (instancetype)initWithCallRecord:(TSCall *)call;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
