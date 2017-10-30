//
//  KJShortVideoAlbumCell.h
//  Join
//
//  Created by JOIN iOS on 2017/9/4.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJUtility.h"

@interface KJShortVideoAlbumCell : UICollectionViewCell

+ (void)regisCellForCollectionView:(UICollectionView *)collectionView;
+ (instancetype)dequeueCellForCollectionView:(UICollectionView *)collectionView withIndex:(NSIndexPath *)indexPath;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *labelTime;

@end
