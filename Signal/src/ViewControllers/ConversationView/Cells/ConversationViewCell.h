//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

// TODO: Move this back to OWSMessageCell.
typedef NS_ENUM(NSInteger, OWSMessageCellType) {
    OWSMessageCellType_TextMessage,
    OWSMessageCellType_OversizeTextMessage,
    OWSMessageCellType_StillImage,
    OWSMessageCellType_AnimatedImage,
    OWSMessageCellType_Audio,
    OWSMessageCellType_Video,
    OWSMessageCellType_GenericAttachment,
    OWSMessageCellType_DownloadingAttachment,
    // Treat invalid messages as empty text messages.
    OWSMessageCellType_Unknown = OWSMessageCellType_TextMessage,
};

@class ConversationViewItem;
@class TSInteraction;
@class ConversationViewCell;
@class OWSContactOffersInteraction;
@class TSAttachmentStream;
@class TSAttachmentPointer;
@class TSOutgoingMessage;
@class TSMessage;

@protocol ConversationViewCellDelegate <NSObject>

// TODO: Consider removing this method.
- (void)didTapViewItem:(ConversationViewItem *)viewItem
              cellType:(OWSMessageCellType)cellType;
// TODO: Consider removing this method.
- (void)didLongPressViewItem:(ConversationViewItem *)viewItem
                    cellType:(OWSMessageCellType)cellType;

- (void)didTapImageViewItem:(ConversationViewItem *)viewItem
           attachmentStream:(TSAttachmentStream *)attachmentStream
                  imageView:(UIView *)imageView;
- (void)didTapVideoViewItem:(ConversationViewItem *)viewItem
           attachmentStream:(TSAttachmentStream *)attachmentStream;
- (void)didTapAudioViewItem:(ConversationViewItem *)viewItem
           attachmentStream:(TSAttachmentStream *)attachmentStream;
//- (void)didTapGenericAttachment:(ConversationViewItem *)viewItem
//               attachmentStream:(TSAttachmentStream *)attachmentStream;
- (void)didTapOversizeTextMessage:(NSString *)displayableText
                 attachmentStream:(TSAttachmentStream *)attachmentStream;
- (void)didTapFailedIncomingAttachment:(ConversationViewItem *)viewItem
                     attachmentPointer:(TSAttachmentPointer *)attachmentPointer;
- (void)didTapFailedOutgoingMessage:(TSOutgoingMessage *)message;

- (void)showMetadataViewForMessage:(TSMessage *)message;

//- (void)showShareUIForAttachment:(ConversationViewItem *)viewItem
//                attachmentStream:(TSAttachmentStream *)attachmentStream;

#pragma mark - System Cell

// TODO: We might want to decompose this method.
- (void)didTapSystemMessageWithInteraction:(TSInteraction *)interaction;
- (void)didLongPressSystemMessageCell:(ConversationViewCell *)systemMessageCell
                             fromView:(UIView *)fromView;

#pragma mark - Offers

- (void)tappedUnknownContactBlockOfferMessage:(OWSContactOffersInteraction *)interaction;
- (void)tappedAddToContactsOfferMessage:(OWSContactOffersInteraction *)interaction;
- (void)tappedAddToProfileWhitelistOfferMessage:(OWSContactOffersInteraction *)interaction;

@end

#pragma mark -

@interface ConversationViewCell : UICollectionViewCell

@property (nonatomic, nullable, weak) id<ConversationViewCellDelegate> delegate;

@property (nonatomic, nullable) ConversationViewItem * viewItem;

@property (nonatomic) BOOL isCellVisible;

// If this is non-null, we should show the message date header.
@property (nonatomic, nullable) NSAttributedString * messageDateHeaderText;

- (void)loadForDisplay;

- (CGSize)cellSizeForViewWidth:(int)viewWidth
               maxMessageWidth:(int)maxMessageWidth;

@end

NS_ASSUME_NONNULL_END
