//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

//#import "OWSMessageData.h"
#import "OWSViewController.h"
//#import "TSAttachmentStream.h"
//#import "TSInteraction.h"
//#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TSAttachmentStream;
@class ConversationViewItem;

@interface FullImageViewController : OWSViewController

- (instancetype)initWithAttachment:(TSAttachmentStream *)attachmentStream
                          fromRect:(CGRect)rect
                          viewItem:(ConversationViewItem *)viewItem;

- (void)presentFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
