//
//  KJEditVideoViewController.h
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/10/24.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJUtility.h"

@interface KJEditVideoViewController : UIViewController

//本地视频（NSString、AVURLAsset、NSURL）
@property (strong, nonatomic) id kj_localVideo;


/**
 * videoPath压缩后的视频
 * localIdentifier保存到相册的高质量视频(如果没有添加滤镜或音乐，返回nil)
 * kj_cover 封面图
 */
@property (copy, nonatomic) void (^editCompleteBlock)(NSURL *videoPath, NSString *localIdentifier, UIImage *kj_cover);

//是否需要让选择封面
@property (assign, nonatomic) BOOL kj_isSelectCover;

@end
