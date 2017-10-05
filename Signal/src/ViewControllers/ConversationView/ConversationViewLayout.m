//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "ConversationViewLayout.h"
#import "UIView+OWS.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConversationViewLayout ()

@property (nonatomic) CGSize contentSize;
@property (nonatomic, readonly) NSMutableDictionary<NSNumber *, UICollectionViewLayoutAttributes *> *itemAttributesMap;

@end

#pragma mark -

@implementation ConversationViewLayout

- (instancetype)init
{
    if (self = [super init]) {
        _itemAttributesMap = [NSMutableDictionary new];
    }

    return self;
}

- (void)invalidateLayout
{
    [super invalidateLayout];

    [self clearState];
}

- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context
{
    [super invalidateLayoutWithContext:context];

    [self clearState];
}

- (void)clearState
{
    self.contentSize = CGSizeZero;
    [self.itemAttributesMap removeAllObjects];
}

- (void)prepareLayout
{
    [super prepareLayout];

    id<ConversationViewLayoutDelegate> delegate = self.delegate;
    if (!delegate) {
        OWSFail(@"%@ Missing delegate", self.tag);
        [self clearState];
        return;
    }

    const int vInset = 5;
    const int hInset = 5;
    const int vSpacing = 3;
    const int viewWidth = (int)floor(self.collectionView.bounds.size.width);
    const int maxMessageWidth = (int)floor((viewWidth - 2 * hInset) * 0.7f);

    NSArray<id<ConversationViewLayoutItem>> *layoutItems = self.delegate.layoutItems;

    CGFloat y = vInset;
    CGFloat contentBottom = y;
    BOOL isRTL = self.collectionView.isRTL;
    
    NSInteger row = 0;
    for (id<ConversationViewLayoutItem> layoutItem in layoutItems) {
        CGSize layoutSize = [layoutItem cellSizeForViewWidth:viewWidth
                                             maxMessageWidth:maxMessageWidth];

        layoutSize.width = MIN(maxMessageWidth, floor(layoutSize.width));
        layoutSize.height = floor(layoutSize.height);
        CGRect itemFrame;
        switch (layoutItem.layoutAlignment) {
            case ConversationViewLayoutAlignment_Incoming:
            case ConversationViewLayoutAlignment_Outgoing:
            {
                BOOL isLeft = ((layoutItem.layoutAlignment == ConversationViewLayoutAlignment_Incoming && !isRTL) ||
                               (layoutItem.layoutAlignment == ConversationViewLayoutAlignment_Outgoing && isRTL));
                if (isLeft) {
                    itemFrame = CGRectMake(hInset, y, layoutSize.width, layoutSize.height);
                } else {
                    itemFrame = CGRectMake(viewWidth - (hInset + layoutSize.width), y, layoutSize.width, layoutSize.height);
                }
                break;
            }
            case ConversationViewLayoutAlignment_FullWidth:
                itemFrame = CGRectMake(hInset, y, maxMessageWidth, layoutSize.height);
                break;
            case ConversationViewLayoutAlignment_Center:
                itemFrame = CGRectMake(
                    hInset + round((viewWidth - layoutSize.width) * 0.5f), y, layoutSize.width, layoutSize.height);
                break;
        }

        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        UICollectionViewLayoutAttributes *itemAttributes =
            [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        itemAttributes.frame = itemFrame;
        self.itemAttributesMap[@(row)] = itemAttributes;

        contentBottom = itemFrame.origin.y + itemFrame.size.height;
        y = contentBottom + vSpacing;
        row++;
    }

    contentBottom += vInset;
    self.contentSize = CGSizeMake(viewWidth, contentBottom);
}

- (nullable NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray<UICollectionViewLayoutAttributes *> *result = [NSMutableArray new];
    for (UICollectionViewLayoutAttributes *itemAttributes in self.itemAttributesMap.allValues) {
        if (CGRectIntersectsRect(rect, itemAttributes.frame)) {
            [result addObject:itemAttributes];
        }
    }
    return result;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.itemAttributesMap[@(indexPath.row)];
}

- (CGSize)collectionViewContentSize
{
    return self.contentSize;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return self.collectionView.bounds.size.width != newBounds.size.width;
}

#pragma mark - Logging

+ (NSString *)tag
{
    return [NSString stringWithFormat:@"[%@]", self.class];
}

- (NSString *)tag
{
    return self.class.tag;
}

@end

NS_ASSUME_NONNULL_END
