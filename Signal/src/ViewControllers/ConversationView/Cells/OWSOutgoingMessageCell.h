//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSMessageCell.h"
//#import "JSQMessagesCollectionViewCell+OWS.h"
//#import "OWSExpirableMessageView.h"
//#import "OWSMessageMediaAdapter.h"
//#import <JSQMessagesViewController/JSQMessagesCollectionViewCellOutgoing.h>

NS_ASSUME_NONNULL_BEGIN

//@class JSQMediaItem;

@interface OWSOutgoingMessageCell
    : OWSMessageCell

//@property (nonatomic, nullable) id<OWSMessageMediaAdapter> mediaAdapter;

+ (NSString *)cellReuseIdentifier;

@end

NS_ASSUME_NONNULL_END
