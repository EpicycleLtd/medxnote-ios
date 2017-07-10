//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef DEBUG
#define SHOW_DEBUG_UI
#else
#ifdef SIGNAL_INTERNAL
#define SHOW_DEBUG_UI
#else
#endif
#endif


@class TSThread;

@interface DebugUITableViewController : OWSTableViewController

+ (void)presentDebugUIFromViewController:(UIViewController *)fromViewController;

+ (void)presentDebugUIForThread:(TSThread *)thread fromViewController:(UIViewController *)fromViewController;

@end

NS_ASSUME_NONNULL_END
