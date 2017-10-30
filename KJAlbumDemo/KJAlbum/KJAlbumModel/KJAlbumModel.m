//
//  KJAlbumModel.m
//  Join
//
//  Created by JOIN iOS on 2017/8/29.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import "KJAlbumModel.h"
#import "KJPHAsset.h"

@implementation KJAlbumModel

#pragma mark - 获取指定相册内的所有图片
+ (NSMutableArray<KJPHAsset *>*)getAssetsInAssetCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending {
    NSMutableArray<KJPHAsset *> *arr = [NSMutableArray array];
    PHFetchResult *result = [KJAlbumModel fetchAssetsInAssetCollection:assetCollection ascending:ascending];
    [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (((PHAsset *)obj).mediaType == PHAssetMediaTypeImage) {
            KJPHAsset *kj_obj = [KJPHAsset new];
            kj_obj.asset = obj;
            [arr addObject:kj_obj];
        }
    }];
    return arr;
}

+ (PHFetchResult *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending {
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:ascending]];
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:option];
    return result;
}


@end
