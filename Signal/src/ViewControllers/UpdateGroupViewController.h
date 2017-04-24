//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSConversationSettingsViewDelegate.h"
#import "TSGroupModel.h"
#import "TSGroupThread.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UpdateGroupViewController : UIViewController

@property (nonatomic, weak) id<OWSConversationSettingsViewDelegate> delegate;

//<
//                                        // UITableViewDelegate,
//                                        //                                                      UITabBarDelegate,
//                                        UINavigationControllerDelegate>

// This view has two modes. It can be used to create a new
// group or update an existing.  If this method is called,
// the latter mode is used.
- (void)configWithThread:(TSGroupThread *)thread;

//@property (nonatomic) IBOutlet UITableView *tableView;
//@property (nonatomic) IBOutlet UITextField *nameGroupTextField;
//@property (nonatomic) IBOutlet UIButton *groupImageButton;
//@property (nonatomic) IBOutlet UIView *tapToDismissView;
//@property (nonatomic) IBOutlet UILabel *addPeopleLabel;

// This property is only set _after_ the dialog dismisses
// and only if the group was created or updated.
//
// TODO:
//@property (nonatomic) TSGroupModel *groupModel;

@property (nonatomic) BOOL shouldEditGroupNameOnAppear;
@property (nonatomic) BOOL shouldEditAvatarOnAppear;

@end

NS_ASSUME_NONNULL_END
