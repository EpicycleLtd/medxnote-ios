//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

//#import <JSQMessagesViewController/JSQMessagesViewController.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ConversationInputToolbarDelegate <NSObject>

- (void)didPressSendButton;

- (void)voiceMemoGestureDidStart;

- (void)voiceMemoGestureDidEnd;

- (void)voiceMemoGestureDidCancel;

- (void)voiceMemoGestureDidChange:(CGFloat)cancelAlpha;

@end

#pragma mark -

@class ConversationInputTextView;

//@interface ConversationInputToolbar : JSQMessagesInputToolbar
@interface ConversationInputToolbar : UIToolbar

@property (nonatomic, weak) id<ConversationInputToolbarDelegate> inputToolbarDelegate;

@property (nonatomic, readonly) ConversationInputTextView *inputTextView;

#pragma mark - Voice Memo

- (void)showVoiceMemoUI;

- (void)hideVoiceMemoUI:(BOOL)animated;

- (void)setVoiceMemoUICancelAlpha:(CGFloat)cancelAlpha;

- (void)cancelVoiceMemoIfNecessary;

- (void)endEditing:(BOOL)force;

- (void)ensureContent;

@end

NS_ASSUME_NONNULL_END
