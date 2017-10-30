//
//  KJSystemPhotoAlbumController.h
//  Join
//
//  Created by JOIN iOS on 2017/8/28.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJUtility.h"

@protocol  KJSystemPhotoAlbumDelegate <NSObject>

- (void)kj_SystemPhotoAlbumSelectedComplete:(NSMutableArray *)selectedItems;

- (void)kj_SystemPhotoAlbumCancel;

@end

@interface KJSystemPhotoAlbumController : UIViewController

//选中的图片（外面传进来的）
@property (strong, nonatomic) NSMutableArray *kj_selectArray;

@property (assign, nonatomic) int maxCount;

@property (weak, nonatomic) id<KJSystemPhotoAlbumDelegate> kj_photoAlbumDelegate;

@end
