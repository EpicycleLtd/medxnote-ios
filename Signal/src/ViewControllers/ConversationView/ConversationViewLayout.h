//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

typedef NS_ENUM(NSInteger, ConversationViewLayoutAlignment) {
    ConversationViewLayoutAlignment_Left,
    ConversationViewLayoutAlignment_FullWidth,
    ConversationViewLayoutAlignment_Center,
    ConversationViewLayoutAlignment_Right,
};

@protocol ConversationViewLayoutItem <NSObject>

// TODO: Perhaps maxMessageWidth should be an implementation detail of the
//       message cells.
- (CGSize)cellSizeForViewWidth:(int)viewWidth
               maxMessageWidth:(int)maxMessageWidth;

- (ConversationViewLayoutAlignment)layoutAlignment;

@end

#pragma mark -

@protocol ConversationViewLayoutDelegate <NSObject>

- (NSArray<id<ConversationViewLayoutItem>> *)layoutItems;

@end

#pragma mark -

@interface ConversationViewLayout : UICollectionViewLayout

@property (nonatomic, weak) id<ConversationViewLayoutDelegate> delegate;

@end
