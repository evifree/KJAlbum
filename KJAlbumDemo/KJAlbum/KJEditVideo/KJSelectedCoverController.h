//
//  KJSelectedCoverController.h
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/10/27.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJUtility.h"

@interface KJSelectedCoverController : UIViewController

//本地视频Url
@property (strong, nonatomic) NSURL *kj_videoUrl;
//选中的封面图
@property (copy, nonatomic)void (^kj_coverCompleteBlock)(UIImage *kj_cover);

@end
