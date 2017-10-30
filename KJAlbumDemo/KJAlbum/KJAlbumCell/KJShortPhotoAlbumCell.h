//
//  KJShortPhotoAlbumCell.h
//  Join
//
//  Created by JOIN iOS on 2017/8/29.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KJShortPhotoAlbumCell;

@protocol KJShortPhotoAlbumCellDelegate <NSObject>

- (void)didTapSelectedAction:(KJShortPhotoAlbumCell *)kj_cell;

@end

@interface KJShortPhotoAlbumCell : UICollectionViewCell

+ (void)regisCellForCollectionView:(UICollectionView *)collectionView;
+ (instancetype)dequeueCellForCollectionView:(UICollectionView *)collectionView withIndex:(NSIndexPath *)indexPath;


@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UIButton *btnSelected;

@property (weak, nonatomic) id<KJShortPhotoAlbumCellDelegate> delegate;

@end
