//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

//#import <JSQMessagesViewController/JSQMessagesViewController.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ConversationInputToolbarDelegate <NSObject>

- (void)sendButtonPressed;

- (void)attachmentButtonPressed;

- (void)voiceMemoGestureDidStart;

- (void)voiceMemoGestureDidEnd;

- (void)voiceMemoGestureDidCancel;

- (void)voiceMemoGestureDidChange:(CGFloat)cancelAlpha;

- (void)textViewDidChange;
//- (void)textViewDidBeginEditing;

@end

#pragma mark -

@class ConversationInputTextView;
@protocol ConversationInputTextViewDelegate;

@interface ConversationInputToolbar : UIToolbar

@property (nonatomic, weak) id<ConversationInputToolbarDelegate> inputToolbarDelegate;

//@property (nonatomic, readonly) ConversationInputTextView *inputTextView;

//- (void)endEditing:(BOOL)force;
//- (void)endEditing:(BOOL)force;
- (void)beginEditingTextMessage;
- (void)endEditingTextMessage;

- (void)setInputTextViewDelegate:(id<ConversationInputTextViewDelegate>)value;

- (NSString *)messageText;
- (void)setMessageText:(NSString * _Nullable)value;
- (void)clearTextMessage;

#pragma mark - Voice Memo

- (void)showVoiceMemoUI;

- (void)hideVoiceMemoUI:(BOOL)animated;

- (void)setVoiceMemoUICancelAlpha:(CGFloat)cancelAlpha;

- (void)cancelVoiceMemoIfNecessary;

@end

NS_ASSUME_NONNULL_END
