//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "AttachmentSharing.h"
#import "PDFViewerViewController.h"
#import "TSAttachmentStream.h"
#import "UIUtil.h"
#import <SignalServiceKit/Threading.h>

@implementation AttachmentSharing

+ (void)showShareUIForAttachment:(TSAttachmentStream *)stream {
    OWSAssert(stream);

    [self showShareUIForURL:stream.mediaURL];
}

+ (void)showShareUIForURL:(NSURL *)url {
    OWSAssert(url);

    [AttachmentSharing showShareUIForActivityItems:@[
        url,
    ]];
}

+ (void)showShareUIForText:(NSString *)text
{
    OWSAssert(text);
    
    [AttachmentSharing showShareUIForActivityItems:@[
                                                     text,
                                                     ]];
}

+ (void)showShareUIForActivityItems:(NSArray *)activityItems
{
    OWSAssert(activityItems);

    DispatchMainThreadSafe(^{
        // Find the frontmost presented UIViewController from which to present the
        // share view.
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        UIViewController *fromViewController = window.rootViewController;
        while (fromViewController.presentedViewController) {
            fromViewController = fromViewController.presentedViewController;
        }
        OWSAssert(fromViewController);
        
        // show PDF view
        if ([activityItems.firstObject isKindOfClass:[NSURL class]] && [[(NSURL *)activityItems.firstObject lastPathComponent] containsString:@"pdf"]) {
            NSURL *url = (NSURL *)activityItems.firstObject;
            PDFViewerViewController *vc = [UIStoryboard storyboardWithName:@"PDFViewer" bundle:nil].instantiateInitialViewController;
            vc.url = url;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            [fromViewController presentViewController:nav animated:true completion:nil];
            return;
        }
        
        UIActivityViewController *activityViewController =
            [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:@[]];

        [activityViewController setCompletionWithItemsHandler:^(UIActivityType __nullable activityType,
            BOOL completed,
            NSArray *__nullable returnedItems,
            NSError *__nullable activityError) {

            DDLogDebug(@"%@ applying signal appearence", self.logTag);
            [UIUtil applySignalAppearence];

            if (activityError) {
                DDLogInfo(@"%@ Failed to share with activityError: %@", self.logTag, activityError);
            } else if (completed) {
                DDLogInfo(@"%@ Did share with activityType: %@", self.logTag, activityType);
            }
        }];

        [fromViewController presentViewController:activityViewController
                                         animated:YES
                                       completion:^{
                                           DDLogDebug(@"%@ applying default system appearence", self.logTag);
                                           [UIUtil applyDefaultSystemAppearence];
                                       }];
    });
}

@end
