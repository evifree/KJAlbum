//
//  KJVideoCameraController.m
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/9/5.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import "KJVideoCameraController.h"
#import "FSKGPUImageBeautyFilter.h"
#import "KJPHAsset.h"
#import "KJAlbumModel.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "KJProgressView.h"

typedef void(^PropertyChangeBlock)(AVCaptureDevice *kj_captureDevice);
@interface KJVideoCameraController ()
{
    GPUImageMovieWriter *kj_movieWriter;
}

//相机layer
@property (strong, nonatomic) UIImageView *imgView;

//topView
@property (strong, nonatomic) UIView *topView;
@property (strong, nonatomic) UIButton *btnCancel;

//bottomView
@property (strong, nonatomic) UIView *bottomView;
@property (strong, nonatomic) UIButton *btnLens;
@property (strong, nonatomic) UIButton *btnFlashlight;
@property (strong, nonatomic) UIButton *btnTake;
@property (strong, nonatomic) UIButton *btnReset;
@property (strong, nonatomic) UIButton *btnComplete;
@property (strong, nonatomic) UIButton *btnBeauty;


@property (assign, nonatomic) CGFloat focalLength;
@property (nonatomic) CGPoint startPoint;

//相机
@property (nonatomic, strong) GPUImageVideoCamera *kj_videoCamera;

@property (nonatomic, strong) GPUImageView *kj_filterView;
//BeautifyFace美颜滤镜（默认开启美颜）
@property (nonatomic, strong) FSKGPUImageBeautyFilter *kj_beautifyFilter;
//裁剪1:1
@property (strong, nonatomic) GPUImageCropFilter *kj_cropFilter;
//@property (strong, nonatomic) GPUImageSaturationFilter *kj_filter;
//视频路径
@property (strong, nonatomic) NSMutableArray *kj_videoArray;
//计时器
@property (strong, nonatomic) NSTimer *kj_timer;
//进度条
@property (strong, nonatomic) KJProgressView *kj_progress;
//显示录制时间
@property (strong, nonatomic) UILabel *kj_currentTime;
//已录制时间
@property (assign, nonatomic) CGFloat currentTime;
//最终的视频路径（合成后）
@property (copy, nonatomic) NSString *kj_outPath;

@end

#define TIMER_INTERVAL  0.05

@implementation KJVideoCameraController

- (void)dealloc {
    [self.kj_videoCamera stopCameraCapture];
    [self.kj_videoCamera removeInputsAndOutputs];
    [self.kj_videoCamera removeAllTargets];
    [self.kj_beautifyFilter removeAllTargets];
    self.kj_videoCamera = nil;
    self.kj_filterView = nil;
    self.kj_beautifyFilter = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //相机授权
    [KJUtility kj_cameraAuthorizationStatus:self completeBlock:^(BOOL allowAccess) {
    }];
    //麦克风
    [KJUtility kj_requestRecordPermission:self completeBlock:^(BOOL allowAccess) {
    }];
    self.kj_videoArray = [NSMutableArray arrayWithCapacity:0];
    self.focalLength = 1;
    if (self.kj_minTime == 0) {
        self.kj_minTime = 1;
    }
    if (self.kj_maxTime < self.kj_minTime) {
        self.kj_maxTime = self.kj_minTime;
    }
    [self customTopView];
    [self customSystemSession];
    [self customBottomView];
    //关闭闪光灯（默认）
    [self setFlashMode:AVCaptureFlashModeOff];
    
    self.imgView.userInteractionEnabled = YES;
    UIPanGestureRecognizer *pinch = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanAction:)];
    [self.imgView addGestureRecognizer:pinch];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//topView
- (void)customTopView {
    WS(weakSelf)
    self.topView = [UIView new];
    self.topView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.topView];
    [self.topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.view.mas_top).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
        make.height.mas_equalTo(44.0f);
    }];
    
    self.btnCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnCancel setTitle:@"取消" forState:UIControlStateNormal];
    [self.btnCancel setTitleColor:[UIColor colorWithHex:0xffffff] forState:UIControlStateNormal];
    self.btnCancel.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [self.btnCancel addTarget:self action:@selector(onCancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:self.btnCancel];
    [self.btnCancel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.topView.mas_top).offset(0);
        make.bottom.equalTo(weakSelf.topView.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.topView.mas_left).offset(0);
        make.width.mas_equalTo(60.0f);
    }];
}

//相机设置
- (void)customSystemSession {
    WS(weakSelf)
    self.imgView = [UIImageView new];
    self.imgView.clipsToBounds = YES;
    [self.view addSubview:self.imgView];
    [self.imgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.topView.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
        make.height.mas_equalTo(SCREEN_WIDTH);
    }];
    
    //美颜相机
    self.kj_videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    self.kj_videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.kj_videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.kj_filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)];
    self.kj_filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    //    self.filterView.center = self.view.center;
    [self.imgView addSubview:self.kj_filterView];
    
    
//    //剪裁滤镜（1:1）
    self.kj_cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, 44/SCREEN_HEIGHT, 1, SCREEN_WIDTH/SCREEN_HEIGHT)];
    //美颜（默认开启美颜）
    self.kj_beautifyFilter = [[FSKGPUImageBeautyFilter alloc] init];
    self.kj_beautifyFilter.beautyLevel = 0.9f;//美颜程度
    self.kj_beautifyFilter.brightLevel = 0.7f;//美白程度
    self.kj_beautifyFilter.toneLevel = 0.9f;//色调强度
    
//    self.kj_filter = [[GPUImageSaturationFilter alloc] init];
//    //滤镜组
//    self.kj_filterGroup = [[GPUImageFilterGroup alloc] init];
//    [self.kj_filterGroup addFilter:self.kj_cropFilter];
//    [self.kj_filterGroup addFilter:self.kj_beautifyFilter];
    
//    [self openBeautify];
    
    [self.kj_videoCamera addAudioInputsAndOutputs];
    [self.kj_videoCamera addTarget:self.kj_cropFilter];
    [self.kj_cropFilter addTarget:self.kj_beautifyFilter];
    [self.kj_beautifyFilter addTarget:self.kj_filterView];
    
    [self.kj_videoCamera startCameraCapture];
}

//bottomView
- (void)customBottomView {
    WS(weakSelf)
    self.bottomView = [UIView new];
    self.bottomView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.imgView.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
        make.bottom.equalTo(weakSelf.view.mas_bottom).offset(0);
    }];
    
    //前后镜头切换
    self.btnLens = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnLens setImage:[UIImage imageNamed:@"switch_camera"] forState:UIControlStateNormal];
    [self.btnLens addTarget:self action:@selector(onSwitchingLens:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.btnLens];
    [self.btnLens mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.bottomView.mas_top).offset(15.0f);
        make.left.equalTo(weakSelf.bottomView.mas_left).offset(0.0f);
        make.size.mas_equalTo(CGSizeMake(44.0, 44.0));
    }];
    
    //闪光灯
    self.btnFlashlight = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnFlashlight setImage:[UIImage imageNamed:@"freshlight_off"] forState:UIControlStateNormal];
    [self.btnFlashlight addTarget:self action:@selector(onFlashlightAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.btnFlashlight];
    [self.btnFlashlight mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(weakSelf.btnLens.mas_centerY).offset(0.0f);
        make.left.equalTo(weakSelf.btnLens.mas_right).offset(0.0f);
        make.size.mas_equalTo(CGSizeMake(44.0, 44.0));
    }];
    
    //美颜
    self.btnBeauty = [UIButton buttonWithType:UIButtonTypeCustom];
    self.btnBeauty.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [self.btnBeauty setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.btnBeauty setTitleColor:[UIColor colorWithHex:0xffd700] forState:UIControlStateSelected];
    [self.btnBeauty setTitle:@"美颜" forState:UIControlStateNormal];
    [self.btnBeauty setTitle:@"美颜" forState:UIControlStateSelected];
    [self.btnBeauty addTarget:self action:@selector(onBeautyButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.btnBeauty];
    [self.btnBeauty mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(weakSelf.btnFlashlight.mas_centerY).offset(0.0f);
        make.left.equalTo(weakSelf.btnFlashlight.mas_right).offset(0.0f);
        make.size.mas_equalTo(CGSizeMake(44.0, 44.0));
    }];
    //默认是开启状态
    self.btnBeauty.selected = YES;
    
    //删除
    self.btnReset = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnReset setImage:[UIImage imageNamed:@"kj_video_album_confirm"] forState:UIControlStateNormal];
    [self.btnReset addTarget:self action:@selector(onDeleteAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.btnReset];
    [self.btnReset mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(weakSelf.bottomView.mas_centerY).offset(0);
        make.centerX.mas_equalTo(-SCREEN_WIDTH/2.0/2.0);
    }];
    
    
    //确定(完成)
    self.btnComplete = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnComplete setImage:[UIImage imageNamed:@"kj_photo_complete"] forState:UIControlStateNormal];
    [self.btnComplete addTarget:self action:@selector(onCompleteAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.btnComplete];
    [self.btnComplete mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(weakSelf.bottomView.mas_centerY).offset(0);
        make.centerX.mas_equalTo(SCREEN_WIDTH/2.0/2.0);
    }];
    
    self.btnComplete.hidden = self.btnReset.hidden = YES;
    
    //拍摄
    self.btnTake = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnTake setImage:[UIImage imageNamed:@"camera_button"] forState:UIControlStateNormal];
    [self.btnTake addTarget:self action:@selector(onTakeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.btnTake];
    [self.btnTake mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf.bottomView);
    }];
    
    
    //进度条
    self.kj_progress = [KJProgressView new];
    self.kj_progress.kj_maxProgress = self.kj_maxTime;
    self.kj_progress.backgroundColor = [UIColor colorWithHex:sYellowColor];
    [self.view addSubview:self.kj_progress];
    [self.kj_progress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(weakSelf.imgView.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.size.mas_equalTo(CGSizeMake(SCREEN_WIDTH, 4));
    }];
    //录制时间的显示
    self.kj_currentTime = [UILabel new];
    self.kj_currentTime.textColor = [UIColor redColor];
    self.kj_currentTime.textAlignment = NSTextAlignmentCenter;
    self.kj_currentTime.font = [UIFont systemFontOfSize:13.0f];
    self.kj_currentTime.text = @"00:00";
    [self.view addSubview:self.kj_currentTime];
    [self.kj_currentTime mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
        make.top.equalTo(weakSelf.imgView.mas_bottom).offset(0);
        make.height.mas_equalTo(44.f);
    }];
}


#pragma mark - 按钮点击事件
//取消
- (void)onCancelAction:(UIButton *)sender {
    [self clearAllVideo];
    if (self.kj_cameraDelegate && [self.kj_cameraDelegate respondsToSelector:@selector(kj_didCancelAction)]) {
        [self.kj_cameraDelegate kj_didCancelAction];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

//前后镜头切换
- (void)onSwitchingLens:(UIButton *)sender {
    AVCaptureDevice *captureDevice = self.kj_videoCamera.inputCamera;
    if ([captureDevice position] == AVCaptureDevicePositionBack) {//只有后置摄像头才有闪光灯
        [self setFlashMode:AVCaptureFlashModeOff];
        [self.btnFlashlight setImage:[UIImage imageNamed:@"freshlight_auto"] forState:UIControlStateNormal];
    }
    [self.kj_videoCamera rotateCamera];
    if ([captureDevice position] == AVCaptureDevicePositionFront) {//从后置摄像头转换到前置
        [self setFlashMode:AVCaptureFlashModeOff];
        [self.btnFlashlight setImage:[UIImage imageNamed:@"freshlight_auto"] forState:UIControlStateNormal];
    }
}

//闪光灯切换
- (void)onFlashlightAction:(UIButton *)sender {
    AVCaptureDevice *captureDevice = self.kj_videoCamera.inputCamera;
    if ([captureDevice position] == AVCaptureDevicePositionBack) {//只有后置摄像头才有闪光灯
        AVCaptureFlashMode flashMode=captureDevice.flashMode;
        switch (flashMode) {
            case AVCaptureFlashModeAuto:
                [self setFlashMode:AVCaptureFlashModeOn];
                [self.btnFlashlight setImage:[UIImage imageNamed:@"freshlight_on"] forState:UIControlStateNormal];
                break;
            case AVCaptureFlashModeOn:
                [self setFlashMode:AVCaptureFlashModeOff];
                [self.btnFlashlight setImage:[UIImage imageNamed:@"freshlight_off"] forState:UIControlStateNormal];
                break;
            case AVCaptureFlashModeOff:
                [self setFlashMode:AVCaptureFlashModeAuto];
                [self.btnFlashlight setImage:[UIImage imageNamed:@"freshlight_auto"] forState:UIControlStateNormal];
                break;
            default:
                break;
        }
    }
}

//美颜
- (void)onBeautyButtonAction:(UIButton *)sender {
    if (self.btnTake.selected) {
        return;
    }
    [self.kj_videoCamera removeAllTargets];
    [self.kj_cropFilter removeAllTargets];
    [self.kj_beautifyFilter removeAllTargets];
    if (self.btnBeauty.selected) {
        //取消美颜
        [self.kj_videoCamera addTarget:self.kj_cropFilter];
        [self.kj_cropFilter addTarget:self.kj_filterView];
    } else {
        //开启美颜
        [self.kj_videoCamera addTarget:self.kj_beautifyFilter];
        [self.kj_beautifyFilter addTarget:self.kj_cropFilter];
        [self.kj_cropFilter addTarget:self.kj_filterView];
    }
    self.btnBeauty.selected = !self.btnBeauty.selected;
}

//拍摄
- (void)onTakeButtonAction:(UIButton *)sender {
    if (self.currentTime >= self.kj_maxTime) {
        //拍摄到最大时间了，不允许继续拍摄了
        return;
    }
    self.btnComplete.hidden = self.btnReset.hidden = !self.btnTake.selected;
    if (self.btnTake.selected) {
        if (self.kj_cameraDelegate && [self.kj_cameraDelegate respondsToSelector:@selector(kj_didResetTakeAction)]) {
            [self.kj_cameraDelegate kj_didResetTakeAction];
        }
        //停止拍摄
        [kj_movieWriter finishRecording];
        self.kj_videoCamera.audioEncodingTarget = nil;
        [self.kj_cropFilter removeTarget:kj_movieWriter];
        if (self.kj_timer) {
            [self.kj_timer invalidate];
            self.kj_timer = nil;
        }
        NSMutableDictionary *dict = self.kj_videoArray.lastObject;
        if (dict) {
            [dict setObject:[NSNumber numberWithFloat:self.currentTime] forKey:@"time"];
        }
        self.btnReset.hidden = self.btnComplete.hidden = !self.kj_videoArray.count;
    } else {
        if (self.kj_cameraDelegate && [self.kj_cameraDelegate respondsToSelector:@selector(kj_didStartTakeAction)]) {
            [self.kj_cameraDelegate kj_didStartTakeAction];
        }
        [self.kj_progress addNodeView];
        //开始拍摄
        NSString *outPath = [self getVideoOutPath];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{@"path":outPath}];
        [self.kj_videoArray addObject:dict];
        unlink([outPath UTF8String]);
        NSURL *videoURL = [NSURL fileURLWithPath:outPath];
        kj_movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:videoURL size:CGSizeMake(SCREEN_WIDTH, SCREEN_WIDTH)];
        kj_movieWriter.encodingLiveVideo = YES;
        kj_movieWriter.shouldPassthroughAudio = YES;
        kj_movieWriter.assetWriter.movieFragmentInterval = kCMTimeInvalid;
        [self.kj_cropFilter addTarget:kj_movieWriter];
        self.kj_videoCamera.audioEncodingTarget = kj_movieWriter;
        [kj_movieWriter startRecording];
        self.kj_timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
                                                   target:self
                                                 selector:@selector(updateTime)
                                                 userInfo:nil
                                                  repeats:YES];
    }
    self.btnTake.selected = !self.btnTake.selected;
}

//删除
- (void)onDeleteAction:(UIButton *)sender {
    if (self.kj_videoArray.count > 0) {
        if (self.kj_progress.kj_isSelected) {
            NSMutableDictionary *dict = self.kj_videoArray.lastObject;
            if ([[NSFileManager defaultManager] fileExistsAtPath:dict[@"path"]]) {
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtPath:dict[@"path"] error:&error];
                if (error) {
                    NSLog(@"删除失败：%@",error);
                } else {
                    if (self.kj_videoArray.count <= 0) {
                        self.currentTime = 0.f;
                    } else {
                        NSLog(@"第%d段删除成功",(int)self.kj_videoArray.count);
                        [self.kj_progress removeLastNode];
                        [self.kj_videoArray removeLastObject];
                        NSMutableDictionary *dict1 = self.kj_videoArray.lastObject;
                        self.currentTime = [dict1[@"time"] floatValue];
                    }
                    [self updateProgress];
                }
            }
        } else {
            [self.kj_progress selectLastNode];
        }
    }
    self.btnReset.hidden = self.btnComplete.hidden = !self.kj_videoArray.count;
}

//确定(完成)
- (void)onCompleteAction:(UIButton *)sender {
    if (self.kj_videoArray.count > 0) {
        if (self.kj_videoArray.count > 1) {
            //需要合并多段视频
            if (!self.kj_outPath) {
                self.kj_outPath = [self getVideoOutPath];//合成后的输出路径
            }
            //判断本地是否已有合成后的视频文件
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.kj_outPath]) {
                //如果存在就删除，重新合成
                [[NSFileManager defaultManager] removeItemAtPath:self.kj_outPath error:nil];
            }
            //音视频合成工具
            AVMutableComposition *kj_composition = [AVMutableComposition composition];
            //音频
            AVMutableCompositionTrack *kj_audioTrack = [kj_composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            //视频
            AVMutableCompositionTrack *kj_videoTrack = [kj_composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            //开始合成
            [KJUtility showProgressDialogText:@"视频处理中..."];
            CMTime kj_totalDuration = kCMTimeZero;
            for (int i = 0; i < self.kj_videoArray.count; i ++) {
                NSDictionary *localDict = self.kj_videoArray[i];
                NSDictionary* options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
                
                AVAsset *kj_asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:localDict[@"path"]] options:options];
                //获取kj_asset中的音频
                NSArray *audioArray = [kj_asset tracksWithMediaType:AVMediaTypeAudio];
                AVAssetTrack *kj_assetAudio = audioArray.firstObject;
                //向kj_audioTrack中加入音频
                NSError *kj_audioError = nil;
                BOOL isComplete_audio = [kj_audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, kj_asset.duration)
                                                               ofTrack:kj_assetAudio
                                                                atTime:kj_totalDuration
                                                                 error:&kj_audioError];
                NSLog(@"加入音频%d  isComplete_audio：%d error：%@", i, isComplete_audio, kj_audioError);
                
                //获取kj_asset中的视频
                NSArray *videoArray = [kj_asset tracksWithMediaType:AVMediaTypeVideo];
                AVAssetTrack *kj_assetVideo = videoArray.firstObject;
                //向kj_videoTrack中加入视频
                NSError *kj_videoError = nil;
                BOOL isComplete_video = [kj_videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, kj_asset.duration)
                                                               ofTrack:kj_assetVideo
                                                                atTime:kj_totalDuration
                                                                 error:&kj_videoError];
                NSLog(@"加入视频%d  isComplete_video：%d error：%@", i, isComplete_video, kj_videoError);
                
                kj_totalDuration = CMTimeAdd(kj_totalDuration, kj_asset.duration);
            }
            //这里可以加水印的，但在这里不做水印处理
            
            //视频导出处理
            AVAssetExportSession *kj_export = [AVAssetExportSession exportSessionWithAsset:kj_composition
                                                                                presetName:AVAssetExportPreset1280x720];
            kj_export.outputURL = [NSURL fileURLWithPath:self.kj_outPath];
            kj_export.outputFileType = AVFileTypeMPEG4;
            kj_export.shouldOptimizeForNetworkUse = YES;
            WS(weakSelf)
            [kj_export exportAsynchronouslyWithCompletionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [KJUtility hideProgressDialog];
                    if (weakSelf.kjFileDelegate && [weakSelf.kjFileDelegate respondsToSelector:@selector(kj_videoFileCompleteLocalPath:)]) {
                        //合成视频成功后，删除小段视频
                        [weakSelf clearAllVideo];
                        NSLog(@"%@",weakSelf.kj_outPath);
                        [weakSelf.kjFileDelegate kj_videoFileCompleteLocalPath:weakSelf.kj_outPath];
                    } else {
                        [weakSelf saveVideoToLibrary];
                    }
                });
            }];
        } else {
            //只有一段视频
            [KJUtility hideProgressDialog];
            NSDictionary *dict = self.kj_videoArray.firstObject;
            self.kj_outPath = dict[@"path"];
            if (self.kjFileDelegate && [self.kjFileDelegate respondsToSelector:@selector(kj_videoFileCompleteLocalPath:)]) {
                [self.kjFileDelegate kj_videoFileCompleteLocalPath:self.kj_outPath];
            } else {
                [self saveVideoToLibrary];
            }
        }
    }
}

//保存到相册
- (void)saveVideoToLibrary {
    WS(weakSelf)
    [KJUtility kj_saveVideoToLibraryForPath:[NSString stringWithFormat:@"file://%@",self.kj_outPath] completeHandler:^(NSString *localIdentifier, BOOL isSuccess) {
        if (isSuccess) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([[NSFileManager defaultManager] fileExistsAtPath:weakSelf.kj_outPath]) {
                    [[NSFileManager defaultManager] removeItemAtPath:weakSelf.kj_outPath error:nil];
                }
                [weakSelf onCancelAction:nil];
            });
        }
    }];
}

//焦距
- (void)onPanAction:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.startPoint = [sender locationInView:self.view];
    } else {
        CGPoint stopLocation = [sender locationInView:self.view];
        CGFloat dy = stopLocation.y - self.startPoint.y;
        if (sender.state == UIGestureRecognizerStateEnded) {
            self.focalLength -= (dy/100.0);
            if (self.focalLength > 3) {
                self.focalLength = 3;
            }
            if (self.focalLength < 1) {
                self.focalLength = 1;
            }
        } else {
            CGFloat focal = self.focalLength-dy/100.0;
            if (focal > 3) {
                focal = 3;
            }
            if (focal < 1) {
                focal = 1;
            }
            [CATransaction begin];
            [CATransaction setAnimationDuration:.025];
            NSError *error;
            if([self.kj_videoCamera.inputCamera lockForConfiguration:&error]){
                [self.kj_videoCamera.inputCamera setVideoZoomFactor:focal];
                [self.kj_videoCamera.inputCamera unlockForConfiguration];
            }
            else {
                NSLog(@"ERROR = %@", error);
            }
            
            [CATransaction commit];
        }
        NSLog(@"Distance: %f", dy);
    }
}

#pragma 相机相关设置
/**
 *  设置闪光灯模式
 *
 *  @param flashMode 闪光灯模式
 */
-(void)setFlashMode:(AVCaptureFlashMode )flashMode{
    [self changeDeviceProperty:^(AVCaptureDevice *kj_captureDevice) {
        if ([kj_captureDevice isFlashModeSupported:flashMode]) {
            [kj_captureDevice setFlashMode:flashMode];
            switch (flashMode) {
                case AVCaptureFlashModeAuto:
                    [kj_captureDevice setTorchMode:AVCaptureTorchModeAuto];
                    break;
                case AVCaptureFlashModeOn:
                    [kj_captureDevice setTorchMode:AVCaptureTorchModeOn];
                    break;
                case AVCaptureFlashModeOff:
                    [kj_captureDevice setTorchMode:AVCaptureTorchModeOff];
                    break;
                default:
                    break;
            }
        }
    }];
}

/**
 *  改变设备属性的统一操作方法
 *
 *  @param propertyChange 属性改变操作
 */
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice= self.kj_videoCamera.inputCamera;
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        //自动对焦
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        //自动曝光
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        //自动白平衡
        if ([captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            [captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        }
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

//停止捕捉
- (void)kj_stopCameraCapture {
    if (self.kj_videoCamera) {
        [self.kj_videoCamera stopCameraCapture];
    }
}

//开启捕捉
- (void)kj_startCameraCapture {
    if (self.kj_videoCamera) {
        [self.kj_videoCamera startCameraCapture];
    }
}

- (NSString *)getVideoOutPath {
    NSString *videoPath = [KJUtility kj_getKJAlbumFilePath];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *fileName = [NSString stringWithFormat:@"%@-%@",[formatter stringFromDate:[NSDate date]], @"kj_video.mp4"];
    videoPath = [videoPath stringByAppendingPathComponent:fileName];

    return videoPath;
}

//显示拍摄进度
- (void)updateTime {
    self.currentTime += TIMER_INTERVAL;
    [self updateProgress];
    if (self.currentTime >= self.kj_maxTime) {
        //拍摄结束
        [kj_movieWriter finishRecording];
        self.kj_videoCamera.audioEncodingTarget = nil;
        [self.kj_cropFilter removeTarget:kj_movieWriter];
        if (self.kj_timer) {
            [self.kj_timer invalidate];
            self.kj_timer = nil;
        }
        self.btnTake.selected = NO;
        self.btnComplete.hidden = self.btnReset.hidden = NO;
    }
}

//更新进度条
- (void)updateProgress {
    self.kj_currentTime.text = [NSString stringWithFormat:@"%.2d:%.2d",(int)self.currentTime/60,(int)self.currentTime];
    self.kj_progress.kj_progress = self.currentTime;
    [self.bottomView layoutIfNeeded];
}

 //清除录制的视频
- (void)clearAllVideo {
    if (self.kj_videoArray.count > 0) {
        for (NSDictionary *dict in self.kj_videoArray) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:dict[@"path"]]) {
                [[NSFileManager defaultManager] removeItemAtPath:dict[@"path"] error:nil];
            }
        }
        [self.kj_videoArray removeAllObjects];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
