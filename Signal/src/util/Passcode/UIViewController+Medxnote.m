//
//  UIViewController+Medxnote.m
//  Medxnote
//
//  Created by Jan Nemecek on 14/7/17.
//  Copyright © 2017 Open Whisper Systems. All rights reserved.
//

#import "UIViewController+Medxnote.h"
#import "TOPasscodeViewController.h"

@implementation UIViewController (Medxnote)

- (void)showPasscodeAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Please set up an App PIN Lock. If you forget your PIN or enter it incorrectly 10 times, you will have to delete and reinstall the app to restore access to the service" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:true completion:nil];
}

@end
