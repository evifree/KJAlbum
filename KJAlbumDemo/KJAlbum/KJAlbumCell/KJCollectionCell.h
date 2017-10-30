//
//  KJCollectionCell.h
//  PhotoBrowse
//
//  Created by JOIN iOS on 2017/7/13.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJUtility.h"

typedef void(^imgTapBlock)();
typedef void(^imgLongPressBlock)(id cell);

@interface KJCollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
+ (void)regisCellFor:(UICollectionView *)collectionView;
+ (KJCollectionCell *)dequeueCellFor:(UICollectionView *)collectionView with:(NSIndexPath *)indexPath;




@property (copy, nonatomic) imgTapBlock tapBlock;
@property (copy, nonatomic) imgLongPressBlock longBlock;

@property (strong, nonatomic) UIImage *kj_image;

@end
