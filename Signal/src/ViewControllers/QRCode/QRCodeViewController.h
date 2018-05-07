//
//  QRCodeViewController.h
//  Medxnote
//
//  Created by Jan Nemecek on 5/5/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol QRCodeViewDelegate <NSObject>

- (void)didFinishScanningQRCodeWithString:(NSString*)string;

@end

@interface QRCodeViewController : UIViewController

@property (weak, nonatomic) id<QRCodeViewDelegate> delegate;

+ (QRCodeViewController *)viewControllerWithDelegate:(id<QRCodeViewDelegate>)delegate;

@end
