//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class TSThread;

@interface ConversationViewController : OWSViewController

@property (nonatomic, readonly) TSThread *thread;
@property (nonatomic) BOOL preventDraftSaving;

- (void)configureForThread:(TSThread *)thread
    keyboardOnViewAppearing:(BOOL)keyboardAppearing
        callOnViewAppearing:(BOOL)callOnViewAppearing;

- (void)popKeyBoard;

#pragma mark 3D Touch Methods

- (void)peekSetup;
- (void)popped;

@end

NS_ASSUME_NONNULL_END
