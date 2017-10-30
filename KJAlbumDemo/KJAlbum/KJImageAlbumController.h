//
//  KJImageAlbumController.h
//  Join
//
//  Created by JOIN iOS on 2017/9/2.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJUtility.h"

@interface KJImageAlbumController : UIViewController

@property (assign, nonatomic) int kj_maxCount;

@property (strong, nonatomic) NSMutableArray *kj_selectArray;


/**
 kj_photoArray-图片
 kj_ModelArray-asset
 */
@property (copy, nonatomic) void (^completeBlock)(NSMutableArray *kj_photoArray, NSMutableArray *kj_ModelArray);

@end
