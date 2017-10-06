//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

//#import "OWSAudioAttachmentPlayer.h"
//#import "OWSMessageEditing.h"
//#import "OWSMessageMediaAdapter.h"
//#import <JSQMessagesViewController/JSQVideoMediaItem.h>
#import "OWSAudioAttachmentPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@class TSAttachmentStream;
@class ConversationViewItem;

@interface OWSAudioMessageView : UIView
//    : JSQVideoMediaItem <OWSMessageEditing, OWSMessageMediaAdapter, OWSAudioAttachmentPlayerDelegate>
//
//@property NSString *attachmentId;
//@property (nonatomic, strong) NSString *contentType;

- (instancetype)initWithAttachment:(TSAttachmentStream *)attachmentStream
                        isIncoming:(BOOL)isIncoming
                          viewItem:(ConversationViewItem *)viewItem;

- (void)createContentsForSize:(CGSize)viewSize;

+ (CGFloat)bubbleHeight;

- (void)updateContents;

//
//- (instancetype)initWithAttachment:(TSAttachmentStream *)attachment incoming:(BOOL)incoming;
//
//- (BOOL)isAudio;
//- (BOOL)isVideo;

@end

NS_ASSUME_NONNULL_END
