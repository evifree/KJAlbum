//
//  KJCustomCameraController.m
//  Join
//
//  Created by JOIN iOS on 2017/9/1.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import "KJCustomCameraController.h"
#import "FSKGPUImageBeautyFilter.h"
#import "KJPHAsset.h"
#import "KJAlbumModel.h"

typedef void(^PropertyChangeBlock)(AVCaptureDevice *kj_captureDevice);
@interface KJCustomCameraController ()

//图片显示
@property (strong, nonatomic) UIImageView *imgView;
@property (strong, nonatomic) UIImageView *showView;
@property (strong, nonatomic) UIImage *kj_image;

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

@property (nonatomic, strong) GPUImageStillCamera *kj_imageCamera;

@property (nonatomic, strong) GPUImageView *kj_filterView;
//BeautifyFace美颜滤镜（默认开启美颜）
@property (nonatomic, strong) FSKGPUImageBeautyFilter *kj_beautifyFilter;
//裁剪1:1
@property (strong, nonatomic) GPUImageCropFilter *kj_cropFilter;
//滤镜组
@property (strong, nonatomic) GPUImageFilterGroup *kj_filterGroup;



@end

@implementation KJCustomCameraController

- (void)dealloc {
    [self.kj_imageCamera stopCameraCapture];
    [self.kj_imageCamera removeInputsAndOutputs];
    [self.kj_imageCamera removeAllTargets];
    [self.kj_beautifyFilter removeAllTargets];
    [self.kj_cropFilter removeAllTargets];
    [self.kj_filterGroup removeAllTargets];
    self.kj_imageCamera = nil;
    self.kj_filterView = nil;
    self.kj_beautifyFilter = nil;
    self.kj_cropFilter = nil;
    self.kj_filterGroup = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //授权
    [KJUtility kj_cameraAuthorizationStatus:self completeBlock:^(BOOL allowAccess) {
    }];
    if (self.maxCount == 0) {
        self.maxCount = 1;
    }
    self.focalLength = 1;
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
    self.kj_imageCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
    self.kj_imageCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.kj_imageCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.kj_filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)];
    self.kj_filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
//    self.filterView.center = self.view.center;
    [self.imgView addSubview:self.kj_filterView];
    
    //剪裁滤镜（1:1）
    self.kj_cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, 44/SCREEN_HEIGHT, 1, SCREEN_WIDTH/SCREEN_HEIGHT)];
    //美颜（默认开启美颜）
    self.kj_beautifyFilter = [[FSKGPUImageBeautyFilter alloc] init];
    self.kj_beautifyFilter.beautyLevel = 0.9f;//美颜程度
    self.kj_beautifyFilter.brightLevel = 0.7f;//美白程度
    self.kj_beautifyFilter.toneLevel = 0.9f;//色调强度
    //滤镜组
    self.kj_filterGroup = [[GPUImageFilterGroup alloc] init];
    [self.kj_filterGroup addFilter:self.kj_cropFilter];
    [self.kj_filterGroup addFilter:self.kj_beautifyFilter];
    
    [self openBeautify];
    [self.kj_imageCamera startCameraCapture];
    
    self.showView = [UIImageView new];
    self.showView.backgroundColor = [UIColor clearColor];
    self.showView.contentMode = UIViewContentModeScaleAspectFill;
    self.showView.clipsToBounds = YES;
    [self.imgView addSubview:self.showView];
    [self.showView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(weakSelf.imgView);
    }];
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
    
    //重新拍摄(重置)
    self.btnReset = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnReset setImage:[UIImage imageNamed:@"kj_photo_reset"] forState:UIControlStateNormal];
    [self.btnReset addTarget:self action:@selector(onResetAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.btnReset];
    [self.btnReset mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf.bottomView);
    }];
    
    
    //确定(完成)
    self.btnComplete = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnComplete setImage:[UIImage imageNamed:@"kj_photo_complete"] forState:UIControlStateNormal];
    [self.btnComplete addTarget:self action:@selector(onCompleteAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.btnComplete];
    [self.btnComplete mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf.bottomView);
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
}


#pragma mark - 按钮点击事件
//取消
- (void)onCancelAction:(UIButton *)sender {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//前后镜头切换
- (void)onSwitchingLens:(UIButton *)sender {
    AVCaptureDevice *captureDevice = self.kj_imageCamera.inputCamera;
    if ([captureDevice position] == AVCaptureDevicePositionBack) {//只有后置摄像头才有闪光灯
        [self setFlashMode:AVCaptureFlashModeOff];
        [self.btnFlashlight setImage:[UIImage imageNamed:@"freshlight_auto"] forState:UIControlStateNormal];
    }
    [self.kj_imageCamera rotateCamera];
    if ([captureDevice position] == AVCaptureDevicePositionFront) {//从后置摄像头转换到前置
        [self setFlashMode:AVCaptureFlashModeOff];
        [self.btnFlashlight setImage:[UIImage imageNamed:@"freshlight_auto"] forState:UIControlStateNormal];
    }
}

//闪光灯切换
- (void)onFlashlightAction:(UIButton *)sender {
    AVCaptureDevice *captureDevice = self.kj_imageCamera.inputCamera;
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
    if (self.btnBeauty.selected) {
        //取消美颜
        [self closeBeautify];
    } else {
        //开启美颜
        [self openBeautify];
    }
    self.btnBeauty.selected = !self.btnBeauty.selected;
}

//拍摄
- (void)onTakeButtonAction:(UIButton *)sender {
    sender.enabled = NO;
    //根据连接取得设备输出的数据
    WS(weakSelf)
    [self.kj_imageCamera capturePhotoAsJPEGProcessedUpToFilter:self.kj_imageCamera.targets.firstObject withCompletionHandler:^(NSData *processedJPEG, NSError *error) {
        if (!error) {
            UIImage *image=[UIImage imageWithData:processedJPEG];
            weakSelf.showView.image = image;
            weakSelf.kj_image = image;
            [weakSelf handleTakeUI];
        } else {
            [KJUtility showAllTextDialog:weakSelf.view Text:@"拍摄失败"];
        }
    }];
}

//拍摄完后UI的设置
- (void)handleTakeUI {
    WS(weakSelf)
    if (self.kj_cameraDelegate && [self.kj_cameraDelegate respondsToSelector:@selector(kj_didStartTakeAction)]) {
        [self.kj_cameraDelegate kj_didStartTakeAction];
    }
    self.btnReset.hidden = NO;
    self.btnComplete.hidden = NO;
    [self.btnReset mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(weakSelf.bottomView.mas_centerY).offset(0);
        make.centerX.mas_equalTo(-SCREEN_WIDTH/2.0/2.0);
    }];
    [self.btnComplete mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(weakSelf.bottomView.mas_centerY).offset(0);
        make.centerX.mas_equalTo(SCREEN_WIDTH/2.0/2.0);
    }];
    [UIView animateWithDuration:0.25 animations:^{
        self.btnTake.hidden = YES;
        [self.bottomView layoutIfNeeded];
    }];
}

//重新拍摄
- (void)onResetAction:(UIButton *)sender {
    WS(weakSelf)
    if (self.kj_cameraDelegate && [self.kj_cameraDelegate respondsToSelector:@selector(kj_didResetTakeAction)]) {
        [self.kj_cameraDelegate kj_didResetTakeAction];
    }
    self.showView.image = nil;
    self.kj_image = nil;
    [self.btnReset mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf.bottomView);
    }];
    [self.btnComplete mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf.bottomView);
    }];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.btnTake.hidden = NO;
        self.btnTake.enabled = YES;
        [self.bottomView layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.btnComplete.hidden = YES;
        self.btnReset.hidden = YES;
    }];
}

//确定(完成)
- (void)onCompleteAction:(UIButton *)sender {
    if (self.kj_selectArray.count >= self.maxCount) {
        [KJUtility showAllTextDialog:self.view Text:[NSString stringWithFormat:@"最多只能选择%d张图片",self.maxCount]];
        return;
    }
    //保存到相册，并获取相册phasset
    [self savePhotoForImage:self.kj_image];
}

//拍摄完后保存图片到相册
- (void)savePhotoForImage:(UIImage *)image {
    WS(weakSelf)
    [KJUtility kj_savePhotoToLibraryForImage:image completeHandler:^(NSString *localIdentifier, BOOL isSuccess) {
        if (isSuccess) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf getAssetForLocalIdentifier:localIdentifier];
            });
        }
    }];
}

//通过localid从相册获取对象
- (void)getAssetForLocalIdentifier:(NSString *)identifier {
    [KJUtility kj_getAssetForLocalIdentifier:identifier completionHandler:^(PHAsset *kj_object) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (kj_object) {
                KJPHAsset *kj_obj = [KJPHAsset new];
                kj_obj.asset = kj_object;
                [self.kj_selectArray addObject:kj_obj];
                if (self.kj_cameraDelegate && [self.kj_cameraDelegate respondsToSelector:@selector(kj_didCompleteAction)]) {
                    [self.kj_cameraDelegate kj_didCompleteAction];
                }
            }
        });
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
            if([self.kj_imageCamera.inputCamera lockForConfiguration:&error]){
                [self.kj_imageCamera.inputCamera setVideoZoomFactor:focal];
                [self.kj_imageCamera.inputCamera unlockForConfiguration];
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
    AVCaptureDevice *captureDevice= self.kj_imageCamera.inputCamera;
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

//开启美颜
- (void)openBeautify {
    [self.kj_filterGroup removeAllTargets];
    [self.kj_imageCamera removeAllTargets];
    [self.kj_beautifyFilter removeAllTargets];
    [self.kj_cropFilter removeAllTargets];
    
    //加上美颜滤镜
    [self.kj_cropFilter addTarget:self.kj_beautifyFilter];
    
    self.kj_filterGroup.initialFilters = @[self.kj_cropFilter];
    self.kj_filterGroup.terminalFilter = self.kj_beautifyFilter;
    
    [self.kj_imageCamera addTarget:self.kj_filterGroup];
    [self.kj_filterGroup addTarget:self.kj_filterView];
}

//关闭美颜
- (void)closeBeautify {
    [self.kj_filterGroup removeAllTargets];
    [self.kj_imageCamera removeAllTargets];
    [self.kj_beautifyFilter removeAllTargets];
    [self.kj_cropFilter removeAllTargets];
    
    self.kj_filterGroup.initialFilters = @[self.kj_cropFilter];
    self.kj_filterGroup.terminalFilter = self.kj_cropFilter;
    
    [self.kj_imageCamera addTarget:self.kj_filterGroup];
    [self.kj_filterGroup addTarget:self.kj_filterView];
}

//停止捕捉
- (void)kj_stopCameraCapture {
    if (self.kj_imageCamera) {
        [self.kj_imageCamera stopCameraCapture];
    }
    
}

//开启捕捉
- (void)kj_startCameraCapture {
    if (self.kj_imageCamera) {
        [self.kj_imageCamera startCameraCapture];
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
