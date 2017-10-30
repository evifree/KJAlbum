//
//  KJEditVideoCell.h
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/10/25.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KJEditVideoCell : UICollectionViewCell

+ (void)regisCellForCollectionView:(UICollectionView *)collectionView;
+ (instancetype)dequeueCellForCollectionView:(UICollectionView *)collectionView withIndex:(NSIndexPath *)indexPath;

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *labTitle;

@end
