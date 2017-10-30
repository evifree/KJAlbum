//
//  KJPHAsset.h
//  Join
//
//  Created by JOIN iOS on 2017/8/29.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface KJPHAsset : NSObject

@property (strong, nonatomic) UIImage *localImage;

@property (strong, nonatomic) PHAsset *asset;

@property (assign, nonatomic) BOOL isSelected;;

//用于视频
@property (strong, nonatomic) AVURLAsset *urlAsset;

@end
