//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "UIView+OWS.h"
#import "UIViewController+OWS.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIViewController (OWS)

- (UIBarButtonItem *)createOWSBackButton
{
    return [self createOWSBackButtonWithTarget:self selector:@selector(backButtonPressed:)];
}

- (UIBarButtonItem *)createOWSBackButtonWithTarget:(id)target selector:(SEL)selector
{
    OWSAssert(target);
    OWSAssert(selector);

    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    BOOL isRTL = [backButton isRTL];
    // TODO:
    //    BOOL isRTL = [[UIView new] isRTL];
    //
    //    // Nudge closer to the left edge to match default back button item.
    //    const CGFloat kExtraLeftPadding = isRTL ? +0 : -8;
    //
    //    // Give some extra hit area to the back button. This is a little smaller
    //    // than the default back button, but makes sense for our left aligned title
    //    // view in the MessagesViewController
    //    const CGFloat kExtraRightPadding = isRTL ? -0 : +10;
    //
    //    // Extra hit area above/below
    //    const CGFloat kExtraHeightPadding = 4;

    // Matching the default backbutton placement is tricky.
    // We can't just adjust the imageEdgeInsets on a UIBarButtonItem directly,
    // so we adjust the imageEdgeInsets on a UIButton, then wrap that
    // in a UIBarButtonItem.
    //    [backButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];

    UIImage *backArrowImage = [UIImage imageNamed:(isRTL ? @"NavBarBackRTL" : @"NavBarBack")];
    OWSAssert(backArrowImage);
    UIImage *backImage = [self createBackButtonWithText:@"3" iconImage:backArrowImage isRTL:isRTL];
    OWSAssert(backImage);

    //    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    [backButton setImage:backImage forState:UIControlStateNormal];
    CGRect buttonFrame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
    backButton.frame = buttonFrame;
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    backItem.width = buttonFrame.size.width;
    return backItem;
    //
    ////    [backButton setImage:backImage forState:UIControlStateNormal];
    ////
    ////    backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    ////
    ////    // Default back button is 1.5 pixel lower than our extracted image.
    ////    const CGFloat kTopInsetPadding = 1.5;
    ////    backButton.imageEdgeInsets = UIEdgeInsetsMake(kTopInsetPadding, kExtraLeftPadding, 0, 0);
    ////
    ////    CGRect buttonFrame
    ////        = CGRectMake(0, 0, backImage.size.width + kExtraRightPadding, backImage.size.height +
    ///kExtraHeightPadding); /    backButton.frame = buttonFrame;
    //
    ////    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(11, 1)) {
    //        // In iOS 11.1 beta, the hot area of custom bar button items is _only_
    //        // the bounds of the custom view, making them very hard to hit.
    //        //
    //        // TODO: Remove this hack if the bug is fixed in iOS 11.1 by the time
    //        //       it goes to production (or in a later release),
    //        //       since it has two negative side effects: 1) the layout of the
    //        //       back button isn't consistent with the iOS default back buttons
    //        //       2) we can't add the unread count badge to the back button
    //        //       with this hack.
    //            return [[UIBarButtonItem alloc] initWithImage:backImage
    //                                                    style:UIBarButtonItemStylePlain
    //                                                   target:target
    //                                                   action:selector];
    ////    }
    ////
    ////    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    ////    backItem.width = buttonFrame.size.width;
    ////
    ////    return backItem;
}

- (UIImage *)createBackButtonWithText:(NSString *_Nullable)badgeText iconImage:(UIImage *)iconImage isRTL:(BOOL)isRTL
{
    UIFont *font = [UIFont systemFontOfSize:12.f];
    CGFloat badgeSize = ceil(font.lineHeight + 0.f);
    CGFloat hSpacing = badgeSize * -0.2f;
    CGFloat badgeHMargin = badgeSize * +0.2f;
    // The distance from the top to the top of the icon.
    CGFloat topMargin = badgeSize * +0.5f;
    // The distance from the bottom to the bottom of the icon.
    CGFloat bottomMargin = badgeSize * +0.5f;

    CGFloat width = ceil(iconImage.size.width + badgeSize + hSpacing + badgeHMargin);
    CGFloat height = round(iconImage.size.height + topMargin + bottomMargin);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, 0.f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

    CGRect iconImageRect = CGRectZero;
    iconImageRect.size = iconImage.size;
    if (isRTL) {
        iconImageRect.origin.x = width - iconImageRect.size.width;
    } else {
        iconImageRect.origin.x = 0;
    }
    iconImageRect.origin.y = height - (iconImageRect.size.height + bottomMargin);
    [iconImage drawInRect:iconImageRect];

    if (badgeText.length > 0) {
        CGRect badgeRect = CGRectZero;
        badgeRect.size.width = badgeSize;
        badgeRect.size.height = badgeSize;
        if (isRTL) {
            badgeRect.origin.x = badgeHMargin;
        } else {
            badgeRect.origin.x = width - (badgeHMargin + badgeRect.size.width);
        }
        badgeRect.origin.y = 0.f;
        [UIColor.redColor setFill];
        CGContextFillEllipseInRect(context, badgeRect);

        [UIColor.greenColor setStroke];
        CGContextStrokeRect(context, CGRectMake(0, 0, width, height));

        NSDictionary<NSAttributedStringKey, id> *textAttributes = @{
            NSFontAttributeName : font,
            NSForegroundColorAttributeName : [UIColor whiteColor],
        };

        CGRect textRect = CGRectZero;
        textRect.size = [badgeText sizeWithAttributes:textAttributes];
        // Center the text inside the badge.
        textRect.origin.x = badgeRect.origin.x + (badgeRect.size.width - textRect.size.width) * 0.5f;
        textRect.origin.y = badgeRect.origin.y + (badgeRect.size.height - textRect.size.height) * 0.5f;
        [badgeText drawInRect:textRect withAttributes:textAttributes];
    }

    UIImage *dstImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return dstImage;
}

#pragma mark - Event Handling

- (void)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end

NS_ASSUME_NONNULL_END
