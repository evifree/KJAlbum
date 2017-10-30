//
//  KJAlbumModel.h
//  Join
//
//  Created by JOIN iOS on 2017/8/29.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>


@interface KJAlbumModel : NSObject

//相册名称
@property (copy, nonatomic) NSString *title;

//相册资源集
@property (strong, nonatomic) NSArray *assets;

//相册集
@property (strong, nonatomic) PHAssetCollection *assetCollection;

//相册内资源数
@property (assign, nonatomic) NSInteger count;

//在该相册中选择了多少张图片
@property (assign, nonatomic) NSInteger selected_count;;

@end
