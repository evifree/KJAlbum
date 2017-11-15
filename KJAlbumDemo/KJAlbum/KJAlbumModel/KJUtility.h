//
//  KJUtility.h
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/9/5.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "UIKit+BaseExtension.h"
#import <YYWebImage.h>
#import <Masonry.h>
#import <YYAnimatedImageView.h>
#import "GPUImage.h"

@protocol KJCustomCameraDelegate <NSObject>

- (void)kj_didStartTakeAction;

- (void)kj_didResetTakeAction;

- (void)kj_didCompleteAction;

- (void)kj_didCancelAction;

@end

@protocol KJVideoFileDelegate <NSObject>

//这里是不保存到相册，返回录制完后的地址
- (void)kj_videoFileCompleteLocalPath:(NSString *)kj_outPath;

@end

//状态条的高
#define StatusBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height
//得到屏幕bounds
#define SCREEN_SIZE [UIScreen mainScreen].bounds
//得到屏幕height
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
//得到屏幕width
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
//self
#define WS(weakSelf)  __weak typeof (self) weakSelf = self;
//颜色
#define sYellowColor    0xffd700

@interface KJUtility : NSObject

+ (void)showAllTextDialog:(UIView *)view  Text:(NSString *)text;
+ (void)showProgressDialogText:(NSString *)text;
+ (void)hideProgressDialog;

//传入 秒  得到  xx分钟xx秒
+ (NSString *)getMMSSFromSS:(NSInteger)seconds;

/**
  拍摄的图片/视频等存放的路径
  
  @return 文件路径
  */
+ (NSString *)kj_getKJAlbumFilePath;

/**
 视频名
 
 @return 返回视频名
 */
+ (NSString *)kj_getNewFileName;

/**
 根据PHAsset获取图片
 
 @param asset PHAsset
 @param isSynchronous 同步-YES 异步-NO
 @param completion 返回图片
 */
+ (void)kj_requestImageForAsset:(PHAsset *)asset
             withSynchronous:(BOOL)isSynchronous
                  completion:(void (^)(UIImage *image))completion;

/**
 根据PHAsset获取视频
 
 @param kj_asset PHAsset
 @param completion AVURLAsset
 */
+ (void)kj_requestVideoForAsset:(PHAsset *)kj_asset
                  completion:(void (^)(AVURLAsset *asset))completion;

/**
 获取视频的缩略图方法

 @param urlAsset 视频的本地路径
 @param start 开始时间
 @param timescale scale
 @return 视频截图
 */
+ (UIImage *)kj_getScreenShotImageFromVideoPath:(AVURLAsset *)urlAsset
                                   withStart:(CGFloat)start
                               withTimescale:(CGFloat)timescale ;

/**
 图片保存到系统相册
 
 @param image 图片
 @param completionHandler 返回结果
 */
+ (void)kj_savePhotoToLibraryForImage:(UIImage *)image
                   completeHandler:(void(^)(NSString *localIdentifier, BOOL isSuccess))completionHandler;

/**
 视频保存到系统相册
 
 @param path 视频路径
 @param completionHandler 返回结果
 */
+ (void)kj_saveVideoToLibraryForPath:(NSString *)path
                  completeHandler:(void(^)(NSString *localIdentifier, BOOL isSuccess))completionHandler;

/**
 根据相册localid获取PHAsset
 
 @param localIdentifier 相册id
 @param completionHandler 返回PHAsset对象
 */
+ (void)kj_getAssetForLocalIdentifier:(NSString *)localIdentifier
                 completionHandler:(void(^)(PHAsset *kj_object))completionHandler;

/**
 视频转码/压缩
 
 @param asset AVAsset
 @param presetName 视频质量（建议压缩上传使用AVAssetExportPresetMediumQuality根据需求设置）
 @param savePath 保存的路径
 @param completeBlock 返回状态
 */
+ (void)kj_compressedVideoAsset:(AVAsset *)asset
                 withPresetName:(NSString *)presetName
                withNewSavePath:(NSURL *)savePath
              withCompleteBlock:(void(^)(NSError *error))completeBlock;

/**
 相册授权
 
 @param ctrl 当前控制器
 @param completeBlock 返回是否允许访问
 */
+ (void)kj_photoLibraryAuthorizationStatus:(UIViewController *)ctrl
                             completeBlock:(void (^)(BOOL allowAccess))completeBlock;

/**
 相机授权
 
 @param ctrl 当前控制器
 @param completeBlock 返回是否允许访问
 */
+ (void)kj_cameraAuthorizationStatus:(UIViewController *)ctrl
                       completeBlock:(void (^)(BOOL allowAccess))completeBlock;

/**
 麦克风授权
 
 @param ctrl 当前控制器
 @param completeBlock 返回是否允许访问
 */
+ (void)kj_requestRecordPermission:(UIViewController *)ctrl
                     completeBlock:(void (^)(BOOL allowAccess))completeBlock;

/**
 授权提示弹出框(跳转到手机设置-应用权限)
 
 @param ctrl 当前控制器
 @param title 提示语
 */
+ (void)kj_authorizationAlert:(UIViewController *)ctrl
                   tipMessage:(NSString *)title;

/**
 图片加滤镜
 
 @param image 源图
 @param filterName 滤镜名字
 @return 合成滤镜后的图片
 */
+ (UIImage *)kj_imageProcessedUsingGPUImage:(UIImage *)image
                             withFilterName:(NSString *)filterName;

/**
 视频的旋转角度
 
 @param url 视频
 @return 角度
 */
+ (NSUInteger)kj_degressFromVideoFileWithURL:(NSURL *)url;

@end
