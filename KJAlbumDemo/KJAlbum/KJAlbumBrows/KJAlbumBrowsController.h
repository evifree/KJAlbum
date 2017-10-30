//
//  KJAlbumBrowsController.h
//  Join
//
//  Created by JOIN iOS on 2017/8/29.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJAlbumModel.h"
#import "KJPHAsset.h"
#import "KJUtility.h"

typedef void(^KJ_DismissBlock)();

@protocol KJAlbumBrowsDelegate <NSObject>

- (void)didSelectedKJPHAsset:(KJPHAsset *)kjAsset;

- (void)didCancelAction;

- (void)didCompleteAction;

@end

@interface KJAlbumBrowsController : UIViewController

@property (strong, nonatomic) NSMutableArray *kj_selectArray;

@property (strong, nonatomic) KJAlbumModel *kj_albumModel;

@property (assign, nonatomic) int maxCount;

@property (assign, nonatomic) int showIndex;

@property (weak, nonatomic) id<KJAlbumBrowsDelegate> kj_delegate;

@end
