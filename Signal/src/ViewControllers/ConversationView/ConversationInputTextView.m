//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "ConversationInputTextView.h"
#import "Signal-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@implementation ConversationInputTextView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.font = [UIFont ows_dynamicTypeBodyFont];
    }
    
    return self;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL becameFirstResponder = [super becomeFirstResponder];
    if (becameFirstResponder) {
        // Intercept to scroll to bottom when text view is tapped.
        [self.inputTextViewDelegate inputTextViewDidBecomeFirstResponder];
    }
    return becameFirstResponder;
}

- (BOOL)pasteboardHasPossibleAttachment
{
    // We don't want to load/convert images more than once so we
    // only do a cursory validation pass at this time.
    return ([SignalAttachment pasteboardHasPossibleAttachment] && ![SignalAttachment pasteboardHasText]);
}

- (BOOL)canPerformAction:(SEL)action withSender:(nullable id)sender
{
    if (action == @selector(paste:)) {
        if ([self pasteboardHasPossibleAttachment]) {
            return YES;
        }
    }
    return [super canPerformAction:action withSender:sender];
}

- (void)paste:(nullable id)sender
{
    if ([self pasteboardHasPossibleAttachment]) {
        SignalAttachment *attachment = [SignalAttachment attachmentFromPasteboard];
        // Note: attachment might be nil or have an error at this point; that's fine.
        [self.inputTextViewDelegate didPasteAttachment:attachment];
        return;
    }

    [super paste:sender];
}

- (void)setFrame:(CGRect)frame
{
    BOOL isNonEmpty = (self.width > 0.f && self.height > 0.f);
    BOOL didChangeSize = !CGSizeEqualToSize(frame.size, self.frame.size);

    [super setFrame:frame];

    if (didChangeSize && isNonEmpty) {
        [self.inputTextViewDelegate textViewDidChangeLayout];
    }
}

- (void)setBounds:(CGRect)bounds
{
    BOOL isNonEmpty = (self.width > 0.f && self.height > 0.f);
    BOOL didChangeSize = !CGSizeEqualToSize(bounds.size, self.bounds.size);

    [super setBounds:bounds];

    if (didChangeSize && isNonEmpty) {
        [self.inputTextViewDelegate textViewDidChangeLayout];
    }
}









//#import <QuartzCore/QuartzCore.h>
//
//#import "NSString+JSQMessages.h"
//
//
//@implementation JSQMessagesComposerTextView
//
//#pragma mark - Initialization
//
//- (void)jsq_configureTextView
//{
//    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
//    
//    CGFloat cornerRadius = 6.0f;
//    
//    self.backgroundColor = [UIColor whiteColor];
//    self.layer.borderWidth = 0.5f;
//    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
//    self.layer.cornerRadius = cornerRadius;
//    
//    self.scrollIndicatorInsets = UIEdgeInsetsMake(cornerRadius, 0.0f, cornerRadius, 0.0f);
//    
//    self.textContainerInset = UIEdgeInsetsMake(4.0f, 2.0f, 4.0f, 2.0f);
//    self.contentInset = UIEdgeInsetsMake(1.0f, 0.0f, 1.0f, 0.0f);
//    
//    self.scrollEnabled = YES;
//    self.scrollsToTop = NO;
//    self.userInteractionEnabled = YES;
//    
//    self.font = [UIFont systemFontOfSize:16.0f];
//    self.textColor = [UIColor blackColor];
//    self.textAlignment = NSTextAlignmentNatural;
//    
//    self.contentMode = UIViewContentModeRedraw;
//    self.dataDetectorTypes = UIDataDetectorTypeNone;
//    self.keyboardAppearance = UIKeyboardAppearanceDefault;
//    self.keyboardType = UIKeyboardTypeDefault;
//    self.returnKeyType = UIReturnKeyDefault;
//    
//    self.text = nil;
//    
//    _placeHolder = nil;
//    _placeHolderTextColor = [UIColor lightGrayColor];
//    
//    [self jsq_addTextViewNotificationObservers];
//}
//
//- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
//{
//    self = [super initWithFrame:frame textContainer:textContainer];
//    if (self) {
//        [self jsq_configureTextView];
//    }
//    return self;
//}
//
//- (void)awakeFromNib
//{
//    [super awakeFromNib];
//    [self jsq_configureTextView];
//}
//
//- (void)dealloc
//{
//    [self jsq_removeTextViewNotificationObservers];
//}
//
//#pragma mark - Composer text view
//
//- (BOOL)hasText
//{
//    return ([[self.text jsq_stringByTrimingWhitespace] length] > 0);
//}
//
//#pragma mark - Setters
//
//- (void)setPlaceHolder:(NSString *)placeHolder
//{
//    if ([placeHolder isEqualToString:_placeHolder]) {
//        return;
//    }
//    
//    _placeHolder = [placeHolder copy];
//    [self setNeedsDisplay];
//}
//
//- (void)setPlaceHolderTextColor:(UIColor *)placeHolderTextColor
//{
//    if ([placeHolderTextColor isEqual:_placeHolderTextColor]) {
//        return;
//    }
//    
//    _placeHolderTextColor = placeHolderTextColor;
//    [self setNeedsDisplay];
//}
//
//#pragma mark - UITextView overrides
//
//- (void)setText:(NSString *)text
//{
//    [super setText:text];
//    [self setNeedsDisplay];
//}
//
//- (void)setAttributedText:(NSAttributedString *)attributedText
//{
//    [super setAttributedText:attributedText];
//    [self setNeedsDisplay];
//}
//
//- (void)setFont:(UIFont *)font
//{
//    [super setFont:font];
//    [self setNeedsDisplay];
//}
//
//- (void)setTextAlignment:(NSTextAlignment)textAlignment
//{
//    [super setTextAlignment:textAlignment];
//    [self setNeedsDisplay];
//}
//
//- (void)paste:(id)sender
//{
//    if (!self.jsqPasteDelegate || [self.jsqPasteDelegate composerTextView:self shouldPasteWithSender:sender]) {
//        [super paste:sender];
//    }
//}
//
//#pragma mark - Drawing
//
//- (void)drawRect:(CGRect)rect
//{
//    [super drawRect:rect];
//    
//    if ([self.text length] == 0 && self.placeHolder) {
//        [self.placeHolderTextColor set];
//        
//        [self.placeHolder drawInRect:CGRectInset(rect, 7.0f, 5.0f)
//                      withAttributes:[self jsq_placeholderTextAttributes]];
//    }
//}
//
//#pragma mark - Notifications
//
//- (void)jsq_addTextViewNotificationObservers
//{
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(jsq_didReceiveTextViewNotification:)
//                                                 name:UITextViewTextDidChangeNotification
//                                               object:self];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(jsq_didReceiveTextViewNotification:)
//                                                 name:UITextViewTextDidBeginEditingNotification
//                                               object:self];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(jsq_didReceiveTextViewNotification:)
//                                                 name:UITextViewTextDidEndEditingNotification
//                                               object:self];
//}
//
//- (void)jsq_removeTextViewNotificationObservers
//{
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:UITextViewTextDidChangeNotification
//                                                  object:self];
//    
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:UITextViewTextDidBeginEditingNotification
//                                                  object:self];
//    
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:UITextViewTextDidEndEditingNotification
//                                                  object:self];
//}
//
//- (void)jsq_didReceiveTextViewNotification:(NSNotification *)notification
//{
//    [self setNeedsDisplay];
//}
//
//#pragma mark - Utilities
//
//- (NSDictionary *)jsq_placeholderTextAttributes
//{
//    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
//    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
//    paragraphStyle.alignment = self.textAlignment;
//    
//    return @{ NSFontAttributeName : self.font,
//              NSForegroundColorAttributeName : self.placeHolderTextColor,
//              NSParagraphStyleAttributeName : paragraphStyle };
//}
//
//#pragma mark - UIMenuController
//
//- (BOOL)canBecomeFirstResponder
//{
//    return [super canBecomeFirstResponder];
//}
//
//- (BOOL)becomeFirstResponder
//{
//    return [super becomeFirstResponder];
//}
//
//- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
//    [UIMenuController sharedMenuController].menuItems = nil;
//    return [super canPerformAction:action withSender:sender];
//}
//@end

@end

NS_ASSUME_NONNULL_END
