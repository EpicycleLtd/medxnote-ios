//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

//#import "TSGroupModel.h"
//#import "TSGroupThread.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TSThread;
//@class TSGroupThread;

@class GroupViewHelper;

@protocol GroupViewHelperDelegate <NSObject>

- (void)groupAvatarDidChange:(UIImage *)image;

- (UIViewController *)fromViewController;

@end

#pragma mark -

@interface GroupViewHelper : NSObject

@property (nonatomic, weak) id<GroupViewHelperDelegate> delegate;

- (void)showChangeGroupAvatarUI;

@end

NS_ASSUME_NONNULL_END
