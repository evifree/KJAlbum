//
//  KJCollectionHeadView.m
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/10/24.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import "KJCollectionHeadView.h"

@implementation KJCollectionHeadView

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

+ (void)regisForColectionView:(UICollectionView *)collectionView {
    [collectionView registerNib:[UINib nibWithNibName:@"KJCollectionHeadView" bundle:[NSBundle mainBundle]] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"KJCollectionHeadView"];
}

+ (instancetype)dequeueReusableViewForCollectionView:(UICollectionView *)collectionView witnIndexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"KJCollectionHeadView" forIndexPath:indexPath];
}

@end
