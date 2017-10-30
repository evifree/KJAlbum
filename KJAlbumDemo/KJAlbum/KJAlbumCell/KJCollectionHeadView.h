//
//  KJCollectionHeadView.h
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/10/24.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KJCollectionHeadView : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UILabel *kj_labelTitle;

+ (void)regisForColectionView:(UICollectionView *)collectionView;
+ (instancetype)dequeueReusableViewForCollectionView:(UICollectionView *)collectionView witnIndexPath:(NSIndexPath *)indexPath;

@end
