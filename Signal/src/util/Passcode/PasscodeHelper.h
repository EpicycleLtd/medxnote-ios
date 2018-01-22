//
//  PasscodeHelper.h
//  Medxnote
//
//  Created by Jan Nemecek on 6/9/17.
//  Copyright © 2017 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TOPasscodeViewController.h"

#define MedxDefaultTimeout 30*60
#define MedxMinimumPasscodeLength 6
#define MedxAlphanumericPasscode NO

typedef NS_ENUM(NSUInteger, PasscodeHelperAction) {
    PasscodeHelperActionCheckPasscode,
    PasscodeHelperActionEnablePasscode,
    PasscodeHelperActionDisablePasscode,
    PasscodeHelperActionChangePasscode
};

@interface PasscodeHelper : NSObject

@property BOOL cancelDisabled;

- (TOPasscodeViewController *)initiateAction:(PasscodeHelperAction)action from:(UIViewController *)vc completion:(void (^)(void))completion;

@end
