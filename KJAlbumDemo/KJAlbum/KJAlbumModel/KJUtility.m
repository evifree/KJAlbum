//
//  KJUtility.m
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/9/5.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import "KJUtility.h"
#import <MBProgressHUD.h>
#import "DLHDActivityIndicator.h"


@implementation KJUtility

+ (void)showAllTextDialog:(UIView *)view  Text:(NSString *)text {
    if (!view) {
        return;
    }
    if ([view isKindOfClass:[UITableView class]]) {
        view = view.superview;
    }
    MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:view];
    [view addSubview:HUD];
    HUD.margin = 12.f;
    HUD.detailsLabelText = text;
    HUD.detailsLabelFont = [UIFont systemFontOfSize:14.0f];
    HUD.mode = MBProgressHUDModeText;
    
    //指定距离中心点的X轴和Y轴的偏移量，如果不指定则在屏幕中间显示
    //    HUD.yOffset = 150.0f;
    //    HUD.xOffset = 100.0f;
    
    [HUD showAnimated:YES whileExecutingBlock:^{
        sleep(1.5);
    } completionBlock:^{
        [HUD removeFromSuperview];
    }];
}

+ (void)showProgressDialogText:(NSString *)text {
    DLHDActivityIndicator *indicator = [DLHDActivityIndicator shared];
    [indicator showWithLabelText:text];
}

+ (void)hideProgressDialog {
    
    [DLHDActivityIndicator hideActivityIndicator];
}

//传入 秒  得到  xx分钟xx秒
+ (NSString *)getMMSSFromSS:(NSInteger)seconds {
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%02ld",seconds/60];
    //format of second
    NSString *str_second = [NSString stringWithFormat:@"%02ld",seconds%60];
    //format of time
    NSString *format_time = [NSString stringWithFormat:@"%@:%@",str_minute,str_second];
    
    return format_time;
    
}


/**
 拍摄的图片/视频等存放的路径

 @return 文件路径
 */
+ (NSString *)kj_getKJAlbumFilePath {
    NSString *filePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    filePath = [filePath stringByAppendingPathComponent:@"kj_album"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return filePath;
}


/**
 视频名

 @return 返回视频名
 */
+ (NSString *)kj_getNewFileName {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *fileName = [NSString stringWithFormat:@"%@-%@",[formatter stringFromDate:[NSDate date]], @"kj_video.mp4"];
    return fileName;
}

/**
 根据PHAsset获取图片
 
 @param asset PHAsset
 @param isSynchronous 同步-YES 异步-NO
 @param completion 返回图片
 */
+ (void)kj_requestImageForAsset:(PHAsset *)asset
             withSynchronous:(BOOL)isSynchronous
                  completion:(void (^)(UIImage *image))completion {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeExact;//控制照片尺寸
    option.networkAccessAllowed = YES;
    option.synchronous = isSynchronous;
    CGFloat width  = (CGFloat)asset.pixelWidth;
    CGFloat height = (CGFloat)asset.pixelHeight;
    CGFloat scale = width/height;
    CGSize size = CGSizeMake(SCREEN_HEIGHT*scale, SCREEN_HEIGHT);
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeDefault options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (isSynchronous) {
            if ([info[@"PHImageResultIsDegradedKey"] boolValue] == NO) {
                completion(result);
            }
        } else {
            completion(result);
        }
    }];
}


/**
 根据PHAsset获取视频
 
 @param kj_asset PHAsset
 @param completion AVURLAsset
 */
+ (void)kj_requestVideoForAsset:(PHAsset *)kj_asset
                  completion:(void (^)(AVURLAsset *asset))completion {
    PHVideoRequestOptions *option = [[PHVideoRequestOptions alloc] init];
    option.version = PHVideoRequestOptionsVersionCurrent;
    option.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    option.networkAccessAllowed = YES;
    [[PHImageManager defaultManager] requestAVAssetForVideo:kj_asset
                                                    options:option
                                              resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        AVURLAsset *url_asset = (AVURLAsset *)asset;
        completion(url_asset);
    }];
}

/**
 获取视频的缩略图方法
 
 @param urlAsset 视频的本地路径
 @param start 开始时间
 @param timescale scale
 @return 视频截图
 */
+ (UIImage *)kj_getScreenShotImageFromVideoPath:(AVURLAsset *)urlAsset
                                   withStart:(CGFloat)start
                               withTimescale:(CGFloat)timescale  {
    if (timescale == 0) {
        timescale = [urlAsset duration].timescale;
    }
    UIImage *shotImage;
    
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:urlAsset];
    
    gen.appliesPreferredTrackTransform = YES;
    
    CMTime time = CMTimeMakeWithSeconds(start, timescale);
    
    NSError *error = nil;
    
    CMTime actualTime;
    
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    
    shotImage = [[UIImage alloc] initWithCGImage:image];
    
    CGImageRelease(image);
    
    return shotImage;
    
}



/**
 图片保存到系统相册

 @param image 图片
 @param completionHandler 返回结果
 */
+ (void)kj_savePhotoToLibraryForImage:(UIImage *)image
                   completeHandler:(void(^)(NSString *localIdentifier, BOOL isSuccess))completionHandler {
    __block NSString *localIdentifier;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        localIdentifier = req.placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"success = %d, error = %@", success, error);
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(localIdentifier, success);
            });
        }
    }];
}


/**
 视频保存到系统相册

 @param path 视频路径
 @param completionHandler 返回结果
 */
+ (void)kj_saveVideoToLibraryForPath:(NSString *)path
                  completeHandler:(void(^)(NSString *localIdentifier, BOOL isSuccess))completionHandler {
    __block NSString *localIdentifier;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL URLWithString:path]];
        localIdentifier = req.placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"success = %d, error = %@", success, error);
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(localIdentifier, success);
        });
    }];
}

/**
 根据相册localid获取PHAsset

 @param localIdentifier 相册id
 @param completionHandler 返回PHAsset对象
 */
+ (void)kj_getAssetForLocalIdentifier:(NSString *)localIdentifier
                 completionHandler:(void(^)(PHAsset *kj_object))completionHandler {
    PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
    [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (obj) {
                completionHandler(obj);
            }
        });
        *stop = YES;
    }];
}


/**
 视频转码/压缩

 @param asset AVAsset
 @param presetName 视频质量（建议压缩使用AVAssetExportPresetMediumQuality，存相册AVAssetExportPreset1920x1080，根据需求设置）
 @param savePath 保存的路径
 @param completeBlock 返回状态
 */
+ (void)kj_compressedVideoAsset:(AVAsset *)asset
                 withPresetName:(NSString *)presetName
                withNewSavePath:(NSURL *)savePath
              withCompleteBlock:(void(^)(NSError *error))completeBlock {
    AVAssetExportSession *kj_export = [AVAssetExportSession exportSessionWithAsset:asset
                                                                        presetName:presetName];
    kj_export.outputURL = savePath;
    kj_export.outputFileType = AVFileTypeMPEG4;
    kj_export.shouldOptimizeForNetworkUse = YES;
    [kj_export exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (kj_export.status == AVAssetExportSessionStatusCompleted) {
                if (completeBlock) {
                    completeBlock(nil);
                }
            } else if (kj_export.status == AVAssetExportSessionStatusFailed) {
                if (completeBlock) {
                    completeBlock(kj_export.error);
                }
            } else {
                NSLog(@"当前压缩进度:%f",kj_export.progress);
            }
        });
    }];
}


/**
 相册授权

 @param ctrl 当前控制器
 @param completeBlock 返回是否允许访问
 */
+ (void)kj_photoLibraryAuthorizationStatus:(UIViewController *)ctrl
                          completeBlock:(void (^)(BOOL allowAccess))completeBlock {
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    if (authStatus == PHAuthorizationStatusNotDetermined) {//没授权- 开始授权
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completeBlock) {
                    completeBlock(status == PHAuthorizationStatusAuthorized);
                }
            });
        }];
    }else {
        if (completeBlock) {
            completeBlock(authStatus == PHAuthorizationStatusAuthorized);
        }
        if (authStatus != PHAuthorizationStatusAuthorized) {
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            NSString *app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
            NSString *alertTitle;
            if (authStatus == 1) {
                alertTitle = @"未知原因导致相册不允许访问";
            } else {
                alertTitle = [NSString stringWithFormat:@"你拒绝了%@访问相册，请到设置-%@中打开相册访问权限",app_Name,app_Name];
            }
            [KJUtility kj_authorizationAlert:ctrl tipMessage:alertTitle];
        }
    }
}

/**
 相机授权

 @param ctrl 当前控制器
 @param completeBlock 返回是否允许访问
 */
+ (void)kj_cameraAuthorizationStatus:(UIViewController *)ctrl
                       completeBlock:(void (^)(BOOL allowAccess))completeBlock {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completeBlock) {
                    completeBlock(granted);
                }
            });
        }];
    } else {
        if (completeBlock) {
            completeBlock(authStatus == AVAuthorizationStatusAuthorized);
        }
        if (authStatus != AVAuthorizationStatusAuthorized) {
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            NSString *app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
            NSString *alertTitle;
            if (authStatus == 1) {
                alertTitle = @"未知原因导致相机不允许访问";
            } else {
                alertTitle = [NSString stringWithFormat:@"你拒绝了%@访问相机，请到设置-%@中打开相机访问权限",app_Name,app_Name];
            }
            [KJUtility kj_authorizationAlert:ctrl tipMessage:alertTitle];
        }
    }
}

/**
 麦克风授权
 
 @param ctrl 当前控制器
 @param completeBlock 返回是否允许访问
 */
+ (void)kj_requestRecordPermission:(UIViewController *)ctrl
                     completeBlock:(void (^)(BOOL allowAccess))completeBlock {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completeBlock) {
                    completeBlock(granted);
                }
                if (granted) {
                    NSLog(@"接受麦克风授权");
                } else {
                    NSLog(@"拒绝麦克风授权");
                    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
                    NSString *app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
                    NSString *alertTitle = [NSString stringWithFormat:@"你拒绝了%@访问麦克风，请到设置-%@中打开麦克风访问权限",app_Name,app_Name];
                    [KJUtility kj_authorizationAlert:ctrl tipMessage:alertTitle];
                }
            });
        }];
    }
}

/**
 授权提示弹出框
 
 @param ctrl 当前控制器
 @param title 提示语
 */
+ (void)kj_authorizationAlert:(UIViewController *)ctrl
                   tipMessage:(NSString *)title {
    __block UIViewController *currentCtrl = ctrl;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:title preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *set = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        });
    }];
    [alert addAction:set];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (currentCtrl.presentingViewController) {
                [currentCtrl dismissViewControllerAnimated:YES completion:nil];
            } else {
                [currentCtrl.navigationController popViewControllerAnimated:YES];
            }
        });
    }];
    [alert addAction:cancel];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [ctrl presentViewController:alert animated:YES completion:nil];
    });
}


/**
 图片加滤镜

 @param image 源图
 @param filterName 滤镜名字 GPUImageOutput<GPUImageInput>
 @return 合成滤镜后的图片
 */
+ (UIImage *)kj_imageProcessedUsingGPUImage:(UIImage *)image
                             withFilterName:(NSString *)filterName {
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:image];
    GPUImageOutput<GPUImageInput> *stillImageFilter = [[NSClassFromString(filterName) alloc] init];
    [stillImageSource addTarget:stillImageFilter];
    [stillImageFilter useNextFrameForImageCapture];
    [stillImageSource processImage];
    UIImage *newImage = [stillImageFilter imageFromCurrentFramebuffer];
    return newImage;
}


/**
 视频的旋转角度

 @param url 视频
 @return 角度
 */
+ (NSUInteger)kj_degressFromVideoFileWithURL:(NSURL *)url {
    NSUInteger degress = 0;
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }
    return degress;
}

@end
