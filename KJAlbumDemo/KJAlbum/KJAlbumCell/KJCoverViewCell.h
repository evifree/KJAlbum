//
//  KJCoverViewCell.h
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/10/27.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KJCoverViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *kj_imgView;

+ (void)regisCellForCollectionView:(UICollectionView *)collectionView;
+ (instancetype)dequeueCellForCollectionView:(UICollectionView *)collectionView withIndex:(NSIndexPath *)indexPath;

@end
