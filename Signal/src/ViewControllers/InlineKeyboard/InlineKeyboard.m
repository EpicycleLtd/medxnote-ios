//
//  InlineKeyboard.m
//  Medxnote
//
//  Created by Jan Nemecek on 13/4/17.
//  Copyright © 2017 Open Whisper Systems. All rights reserved.
//

#import "InlineKeyboard.h"
#import "InlineKeyboardCell.h"
#import "PredefinedAnswers.h"
#import "PredefinedAnswerSection.h"
#import "PredefinedAnswerItem.h"

@interface InlineKeyboard () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property UICollectionView *collectionView;
@property PredefinedAnswers *answers;

@end

@implementation InlineKeyboard
    
- (instancetype)initWithAnswers:(NSDictionary *)answers {
    self = [super init];
    if (self) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
//        layout.estimatedItemSize = CGSizeMake(150, 60);
        layout.sectionInset = UIEdgeInsetsMake(5,10,5,10);
        _collectionView = [[UICollectionView alloc] initWithFrame:[UIScreen mainScreen].bounds collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor colorWithWhite:249/255.0f alpha:1.0f];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerNib:[UINib nibWithNibName:@"InlineKeyboardCell" bundle:nil] forCellWithReuseIdentifier:@"KeyboardCell"];
        self.answers = [[PredefinedAnswers alloc] initWithJson:answers];
    }
    return self;
}

- (UIView *)keyboardView {
    NSInteger sectionCount = self.collectionView.numberOfSections;
    CGFloat bottom = 0.0f;
    if (@available(iOS 11.0, *)) {
        bottom = [UIApplication sharedApplication].keyWindow.rootViewController.view.safeAreaInsets.bottom;
    }
    self.collectionView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, (sectionCount*50.0)+bottom);
    return self.collectionView;
}
    
#pragma mark - Collection View
    
- (PredefinedAnswerItem *)cellAtIndexPath:(NSIndexPath *)indexPath {
    PredefinedAnswerSection *answerSection = self.answers.sections[indexPath.section];
    PredefinedAnswerItem *item = answerSection.items[indexPath.row];
    return item;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return (NSInteger)self.answers.sections.count;
}
    
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    PredefinedAnswerSection *answerSection = self.answers.sections[section];
    return answerSection.items.count;
}
    
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    InlineKeyboardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"KeyboardCell" forIndexPath:indexPath];
    PredefinedAnswerItem *item = [self cellAtIndexPath:indexPath];
    [cell customizeWithItem:item];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PredefinedAnswerItem *item = [self cellAtIndexPath:indexPath];
    [self.delegate tappedInlineKeyboardCell:item];
}
    
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    PredefinedAnswerSection *answerSection = self.answers.sections[indexPath.section];
    PredefinedAnswerItem *item = [self cellAtIndexPath:indexPath];
    CGFloat itemWidth = [UIScreen mainScreen].bounds.size.width/answerSection.items.count;
    if (item.width != 0) {
        itemWidth = item.width;
    }
    return CGSizeMake(itemWidth-20, 40); // 20 is inter-item padding
}

@end
