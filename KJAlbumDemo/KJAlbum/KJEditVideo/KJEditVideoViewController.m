//
//  KJEditVideoViewController.m
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/10/24.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import "KJEditVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "KJCollectionHeadView.h"
#import "KJEditVideoCell.h"
#import "LFGPUImageEmptyFilter.h"
#import "FSKGPUImageBeautyFilter.h"

#import "KJSelectedCoverController.h"

@interface KJEditVideoViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>
//视频播放
@property (strong, nonatomic)AVPlayer *kj_player;
//音乐播放
@property (strong, nonatomic) AVPlayer *kj_musicPlayer;
//滤镜数组
@property (strong, nonatomic) NSMutableArray *kj_filterArray;
//音乐数组
@property (strong, nonatomic) NSMutableArray *kj_musicArray;
//本地json数据
@property (strong, nonatomic) NSDictionary *kj_filterJson;
//导航topView
@property (strong, nonatomic) UIView *kj_topView;
//取消按钮
@property (strong, nonatomic) UIButton *kj_btnCancel;
//完成按钮
@property (strong, nonatomic) UIButton *kj_btnComplete;
//操作bottomView
@property (strong, nonatomic) UIView *kj_bottomView;
//playerlayer
@property (strong, nonatomic) UIImageView *kj_imgView;
//滤镜展示collectionView
@property (strong, nonatomic) UICollectionView *kj_filterCollectionView;
//滤镜title
@property (strong, nonatomic) UILabel *labelFilterTitle;
//音乐展示collectionView
@property (strong, nonatomic) UICollectionView *kj_musicCollectionView;
//音乐title
@property (strong, nonatomic) UILabel *labelMusicTitle;
//视频URL
@property (strong, nonatomic) NSURL *kj_videoUrl;
//合成的视频路径
@property (strong, nonatomic) NSMutableArray *kj_newVideoPathArray;
//展示选中滤镜的效果
@property (strong, nonatomic) GPUImageView *kj_filterView;
//滤镜效果展示
@property (strong, nonatomic) GPUImageMovie *kj_showMovie;
//选中的滤镜
@property (strong, nonatomic) GPUImageOutput<GPUImageInput> *kj_filter;
//选中的音乐
@property (strong, nonatomic) NSDictionary *kj_selectedMusic;
//选中的滤镜数据
@property (strong, nonatomic) NSDictionary *kj_selectedFilter;
@end

@implementation KJEditVideoViewController
{
    GPUImageMovie *kj_movieComposition;
    GPUImageMovieWriter *kj_movieWriter;
}

- (void)dealloc {
    [self removeNotification];
    [self.kj_player pause];
    self.kj_player = nil;
    [self.kj_showMovie removeAllTargets];
    [self.kj_showMovie endProcessing];
    self.kj_showMovie = nil;
    [self.kj_musicPlayer pause];
    self.kj_musicPlayer = nil;
    self.kj_filter = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kj_didBecomActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kj_willResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    
    self.kj_newVideoPathArray = [NSMutableArray arrayWithCapacity:0];
    //导航栏设置
    [self customNavc];
    //播放器
    [self customAVPlayer];
    //bottomView
    [self customBottomView];
    //滤镜 音乐数据
    [self getFilterDataArray];
    //开始播放
    [self.kj_player play];
    [self.kj_showMovie startProcessing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//导航-取消按钮（左按钮）
- (void)onCancelAction:(id)sender {
    [KJUtility hideProgressDialog];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//导航-完成按钮（右按钮）
- (void)onCompleteAction:(id)sender {
    [KJUtility showProgressDialogText:@"处理中..."];
    if (self.kj_selectedFilter && ![self.kj_selectedFilter[@"filter"] isEqualToString:@"LFGPUImageEmptyFilter"]) {
        //有滤镜需要合成
        GPUImageOutput<GPUImageInput> * filter = [[NSClassFromString(self.kj_selectedFilter[@"filter"]) alloc] init];
        [self filterCompositionForFilter:filter withVideoUrl:self.kj_videoUrl];
    } else if (self.kj_selectedMusic) {
        //合成音乐
        
        [self musicCompositionForMusicInfo:self.kj_selectedMusic withVideoPath:self.kj_videoUrl];
    } else {
        //什么都不需要合成，直接返回成功
        [self compressedVideo:nil];
    }
}

//应用进入前台
- (void)kj_didBecomActiveNotification:(NSNotification *)ntf {
    [self.kj_player seekToTime:kCMTimeZero];
    if (self.kj_selectedMusic) {
        [self.kj_musicPlayer seekToTime:kCMTimeZero];
        [self.kj_musicPlayer play];
    }
    [self.kj_player play];
    [self.kj_showMovie startProcessing];
}

//应用即将进入后台
- (void)kj_willResignActiveNotification:(NSNotification *)ntf {
    [self.kj_player pause];
    if (self.kj_musicPlayer) {
        [self.kj_musicPlayer pause];
    }
    [self.kj_showMovie endProcessing];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    //让其他应用的声音停止
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:YES error:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [KJUtility hideProgressDialog];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self removeNotification];
    //当离开该页面。让其他应用声音恢复
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

- (void)customNavc {
    WS(weakSelf)
    self.kj_topView = [UIView new];
    self.kj_topView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.kj_topView];
    [self.kj_topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.view.mas_top).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
        make.height.mas_equalTo(44.0f);
    }];
    
    self.kj_btnCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.kj_btnCancel setTitle:@"取消" forState:UIControlStateNormal];
    [self.kj_btnCancel setTitleColor:[UIColor colorWithHex:0xffffff] forState:UIControlStateNormal];
    self.kj_btnCancel.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [self.kj_btnCancel addTarget:self action:@selector(onCancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.kj_topView addSubview:self.kj_btnCancel];
    [self.kj_btnCancel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.kj_topView.mas_top).offset(0);
        make.bottom.equalTo(weakSelf.kj_topView.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.kj_topView.mas_left).offset(0);
        make.width.mas_equalTo(60.0f);
    }];
    
    self.kj_btnComplete = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.kj_btnComplete setTitle:@"完成" forState:UIControlStateNormal];
    [self.kj_btnComplete setTitleColor:[UIColor colorWithHex:0x000000] forState:UIControlStateNormal];
    [self.kj_btnComplete setBackgroundColor:[UIColor colorWithHex:sYellowColor]];
    self.kj_btnComplete.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    [self.kj_btnComplete addTarget:self action:@selector(onCompleteAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.kj_topView addSubview:self.kj_btnComplete];
    self.kj_btnComplete.layer.cornerRadius = 2.0f;
    self.kj_btnComplete.layer.masksToBounds = YES;
    [self.kj_btnComplete mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(weakSelf.kj_topView.mas_right).offset(-13);
        make.width.mas_equalTo(60.0f);
        make.height.mas_equalTo(26.0f);
        make.centerY.equalTo(weakSelf.kj_topView.mas_centerY).offset(0);
    }];
}

- (void)customAVPlayer {
    WS(weakSelf)
    self.kj_player = [[AVPlayer alloc] init];
    if (!self.kj_videoUrl) {
        self.kj_videoUrl = [self getLocalVideoPath];
    }
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.kj_videoUrl];
    [self.kj_player replaceCurrentItemWithPlayerItem:playerItem];
    
    
    self.kj_imgView = [UIImageView new];
    [self.view addSubview:self.kj_imgView];
    [self.kj_imgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.kj_topView.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
        make.height.mas_equalTo(SCREEN_WIDTH);
    }];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.kj_player];
    playerLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    playerLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH);
    [self.kj_imgView.layer insertSublayer:playerLayer atIndex:0];
    
    self.kj_showMovie = [[GPUImageMovie alloc] initWithPlayerItem:playerItem];
    self.kj_showMovie.runBenchmark = YES;
    self.kj_showMovie.playAtActualSpeed = YES;//滤镜渲染方式
    self.kj_showMovie.shouldRepeat = YES;//是否循环播放
    
    //正常滤镜
    self.kj_filter = [[LFGPUImageEmptyFilter alloc] init];
    [self.kj_showMovie addTarget:self.kj_filter];
    
    self.kj_filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)];
    [self.kj_imgView addSubview:self.kj_filterView];
    [self.kj_filter addTarget:self.kj_filterView];
    CGAffineTransform rotate = CGAffineTransformMakeRotation([KJUtility kj_degressFromVideoFileWithURL:self.kj_videoUrl] / 180.0 * M_PI );
    _kj_filterView.transform = rotate;
    [self.kj_imgView bringSubviewToFront:self.kj_filterView];
    
    [self addNotification];
}


- (void)customBottomView {
    WS(weakSelf)
    self.kj_bottomView = [UIView new];
    self.kj_bottomView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.kj_bottomView];
    [self.kj_bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.kj_imgView.mas_bottom).offset(0);
        make.bottom.equalTo(weakSelf.view.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
    }];
    
    self.kj_musicCollectionView = [self custonCollectionView];
    [self.kj_bottomView addSubview:self.kj_musicCollectionView];
    [self.kj_musicCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(weakSelf.kj_bottomView.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.kj_bottomView.mas_left).offset(0);
        make.right.equalTo(weakSelf.kj_bottomView.mas_right).offset(0);
        make.top.equalTo(weakSelf.kj_bottomView.mas_centerY).offset(44);
    }];
    
    self.labelMusicTitle = [self customTitleLabel];
    self.labelMusicTitle.text = @"音乐";
    [self.kj_bottomView addSubview:self.labelMusicTitle];
    [self.labelMusicTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(weakSelf.kj_musicCollectionView.mas_top).offset(0);
        make.left.equalTo(weakSelf.kj_bottomView.mas_left).offset(13.f);
        make.right.equalTo(weakSelf.kj_bottomView.mas_right).offset(0);
        make.height.mas_equalTo(44.0f);
    }];
    
    self.kj_filterCollectionView = [self custonCollectionView];
    [self.kj_bottomView addSubview:self.kj_filterCollectionView];
    [self.kj_filterCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(weakSelf.labelMusicTitle.mas_top).offset(0);
        make.left.equalTo(weakSelf.kj_bottomView.mas_left).offset(0);
        make.right.equalTo(weakSelf.kj_bottomView.mas_right).offset(0);
        make.top.equalTo(weakSelf.kj_bottomView.mas_top).offset(44);
    }];
    
    self.labelFilterTitle = [self customTitleLabel];
    self.labelFilterTitle.text = @"滤镜";
    [self.kj_bottomView addSubview:self.labelFilterTitle];
    [self.labelFilterTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(weakSelf.kj_filterCollectionView.mas_top).offset(0);
        make.left.equalTo(weakSelf.kj_bottomView.mas_left).offset(13.f);
        make.right.equalTo(weakSelf.kj_bottomView.mas_right).offset(0);
        make.height.mas_equalTo(44.0f);
    }];
}

- (void)getFilterDataArray {
    if (!self.kj_filterJson) {
        self.kj_filterJson = [self getFilterGeojsonFile];
    }
    if (!self.kj_filterArray) {
        self.kj_filterArray = [NSMutableArray arrayWithCapacity:0];
    }
    if (!self.kj_musicArray) {
        self.kj_musicArray = [NSMutableArray arrayWithCapacity:0];
    }
    [self.kj_filterArray addObjectsFromArray:self.kj_filterJson[@"filters"]];
    [self.kj_musicArray addObjectsFromArray:self.kj_filterJson[@"music"]];
    [self.kj_filterCollectionView reloadData];
    [self.kj_musicCollectionView reloadData];
    
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.kj_filterCollectionView) {
        return self.kj_filterArray.count;
    }
    return self.kj_musicArray.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return CGSizeMake(self.kj_bottomView.height/2-44.0f-20, self.kj_bottomView.height/2-44.0f);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    KJEditVideoCell *cell = [KJEditVideoCell dequeueCellForCollectionView:collectionView withIndex:indexPath];
    if (collectionView == self.kj_filterCollectionView) {
        NSDictionary *dict = self.kj_filterArray[indexPath.row];
        cell.labTitle.text = dict[@"name"];
        cell.imgView.image = [KJUtility kj_imageProcessedUsingGPUImage:[UIImage imageNamed:@"filter_nor"] withFilterName:dict[@"filter"]];
    } else {
        NSDictionary *dict = self.kj_musicArray[indexPath.row];
        cell.labTitle.text = dict[@"name"];
        cell.imgView.image = [dict[@"image"] isEqualToString:@""] ? [UIImage imageNamed:@"filter_nor"] : [UIImage imageNamed:dict[@"image"]];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.kj_filterCollectionView) {
        //滤镜
        [self.kj_showMovie removeAllTargets];
        [self.kj_filter removeAllTargets];
        NSDictionary *dict = self.kj_filterArray[indexPath.row];
        self.kj_selectedFilter = dict;
        self.kj_filter = [[NSClassFromString(dict[@"filter"]) alloc] init];
        if ([dict[@"filter"] isEqualToString:@"GPUImageGammaFilter"]) {
            ((GPUImageGammaFilter *)self.kj_filter).gamma = [dict[@"gamma"] floatValue];
        } else if ([dict[@"filter"] isEqualToString:@"GPUImageSaturationFilter"]) {
            ((GPUImageSaturationFilter *)self.kj_filter).saturation = [dict[@"saturation"] floatValue];
        } else if ([dict[@"filter"] isEqualToString:@"GPUImageContrastFilter"]) {
            ((GPUImageContrastFilter *)self.kj_filter).contrast = [dict[@"contrast"] floatValue];
        } else if ([dict[@"filter"] isEqualToString:@"FSKGPUImageBeautyFilter"]) {
            ((FSKGPUImageBeautyFilter *)self.kj_filter).beautyLevel = [dict[@"beautyLevel"] floatValue];
            ((FSKGPUImageBeautyFilter *)self.kj_filter).brightLevel = [dict[@"brightLevel"] floatValue];
            ((FSKGPUImageBeautyFilter *)self.kj_filter).toneLevel = [dict[@"toneLevel"] floatValue];
        } else if ([dict[@"filter"] isEqualToString:@"GPUImageRGBFilter"]) {
            ((GPUImageRGBFilter *)self.kj_filter).red = [dict[@"red"] floatValue];
            ((GPUImageRGBFilter *)self.kj_filter).blue = [dict[@"blue"] floatValue];
            ((GPUImageRGBFilter *)self.kj_filter).green = [dict[@"green"] floatValue];
        }
        
        [self.kj_showMovie addTarget:self.kj_filter];
        [self.kj_filter addTarget:self.kj_filterView];
    } else {
        //音乐
        if (indexPath.row == 0) {
            //原声
            [self.kj_player setVolume:1];
            [self.kj_player seekToTime:kCMTimeZero];
            self.kj_selectedMusic = nil;
            if (self.kj_musicPlayer) {
                [self.kj_musicPlayer pause];
            }
        } else {
            if (!self.kj_musicPlayer) {
                self.kj_musicPlayer = [[AVPlayer alloc] init];
            }
            NSDictionary *dict = self.kj_musicArray[indexPath.row];
            NSString *path = [[NSBundle mainBundle] pathForResource:dict[@"music"] ofType:@"mp3"];
            AVPlayerItem *item = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:path]];
            [self.kj_musicPlayer replaceCurrentItemWithPlayerItem:item];
            self.kj_selectedMusic = dict;
            [self.kj_player setVolume:0];
            [self.kj_player seekToTime:kCMTimeZero];
            [self.kj_musicPlayer play];
            [self.kj_player play];
        }
    }
}

//合成滤镜
- (void)filterCompositionForFilter:(GPUImageOutput<GPUImageInput> *)filter withVideoUrl:(NSURL *)videoUrl {
    if (videoUrl) {
        WS(weakSelf)
        NSUInteger a = [KJUtility kj_degressFromVideoFileWithURL:videoUrl];
        CGAffineTransform rotate = CGAffineTransformMakeRotation(a / 180.0 * M_PI );
        
        GPUImageOutput<GPUImageInput> *tmpFilter = filter;
        kj_movieComposition = [[GPUImageMovie alloc] initWithURL:videoUrl];
        kj_movieComposition.runBenchmark = YES;
        kj_movieComposition.playAtActualSpeed = NO;

        [kj_movieComposition addTarget:tmpFilter];
        //合成后的视频路径
        NSString *newPath = [KJUtility kj_getKJAlbumFilePath];
        newPath = [newPath stringByAppendingPathComponent:[KJUtility kj_getNewFileName]];
        unlink([newPath UTF8String]);
        NSLog(@"%f,%f",self.kj_player.currentItem.presentationSize.height,self.kj_player.currentItem.presentationSize.width);
        CGSize videoSize = self.kj_player.currentItem.presentationSize;
        if (a == 90 || a == 270) {
            videoSize = CGSizeMake(videoSize.height, videoSize.width);
        }
        
        NSURL *tmpUrl = [NSURL fileURLWithPath:newPath];
        [self.kj_newVideoPathArray addObject:tmpUrl];
        kj_movieWriter  = [[GPUImageMovieWriter alloc] initWithMovieURL:tmpUrl size:videoSize];
        kj_movieWriter.transform = rotate;
        kj_movieWriter.shouldPassthroughAudio = YES;
        kj_movieComposition.audioEncodingTarget = kj_movieWriter;
        [tmpFilter addTarget:kj_movieWriter];
        [kj_movieComposition enableSynchronizedEncodingUsingMovieWriter:kj_movieWriter];

        [kj_movieWriter startRecording];
        [kj_movieComposition startProcessing];

        __weak GPUImageMovieWriter *weakmovieWriter = kj_movieWriter;
        [kj_movieWriter setCompletionBlock:^{
            NSLog(@"滤镜添加成功");
            [tmpFilter removeTarget:weakmovieWriter];
            [weakmovieWriter finishRecording];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.kj_selectedMusic) {
                    //合成音乐
                    [weakSelf musicCompositionForMusicInfo:weakSelf.kj_selectedMusic withVideoPath:weakSelf.kj_newVideoPathArray.lastObject];
                } else {
                    [weakSelf saveVideoToLib];
                }
            });
        }];
        [kj_movieWriter setFailureBlock:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"滤镜添加失败：%@", error);
                if ([[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
                    NSError *delError = nil;
                    [[NSFileManager defaultManager] removeItemAtPath:newPath error:&delError];
                    if (delError) {
                        NSLog(@"删除沙盒路径失败：%@", delError);
                    }
                }
                [weakSelf.kj_newVideoPathArray removeLastObject];
                [KJUtility hideProgressDialog];
            });
        }];
    }
}

//合成音乐
- (void)musicCompositionForMusicInfo:(NSDictionary *)musicInfo withVideoPath:(NSURL *)videoUrl {
    if (musicInfo && videoUrl) {
        //音乐
        NSString *audioPath = [[NSBundle mainBundle] pathForResource:musicInfo[@"music"] ofType:@"mp3"];
        NSURL *audioUrl = [NSURL fileURLWithPath:audioPath];
        
        //合成后的视频输出路径
        NSString *newPath = [KJUtility kj_getKJAlbumFilePath];
        newPath = [newPath stringByAppendingPathComponent:[KJUtility kj_getNewFileName]];
        unlink([newPath UTF8String]);
        NSURL *newVideoPath = [NSURL fileURLWithPath:newPath];
        
        //合成工具
        AVMutableComposition *kj_composition = [AVMutableComposition composition];
        //音频
        AVMutableCompositionTrack *kj_audioTrack = [kj_composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        //视频
        AVMutableCompositionTrack *kj_videoTrack = [kj_composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        NSDictionary* kj_options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
        //视频AVAsset
        AVURLAsset *kj_videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:kj_options];
        //视频时间范围（合成的音乐不能超过这个时间范围）
        CMTimeRange kj_videoTimeRange = CMTimeRangeMake(kCMTimeZero, kj_videoAsset.duration);
        //采集kj_videoAsset中的视频
        NSArray *videoArray = [kj_videoAsset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *kj_assetVideo = videoArray.firstObject;
        [kj_videoTrack setPreferredTransform:kj_assetVideo.preferredTransform];
        //采集的视频加入到视频通道kj_videoTrack
        NSError *kj_videoError = nil;
        BOOL isComplete_video = [kj_videoTrack insertTimeRange:kj_videoTimeRange
                                                       ofTrack:kj_assetVideo
                                                        atTime:kCMTimeZero
                                                         error:&kj_videoError];
        NSLog(@"加入视频isComplete_video：%d error：%@",isComplete_video, kj_videoError);
        //音频AVAsset
        AVURLAsset *kj_audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:kj_options];
        //采集kj_audioAsset中的音频
        NSArray *audioArray = [kj_audioAsset tracksWithMediaType:AVMediaTypeAudio];
        AVAssetTrack *kj_assetAudio = audioArray.firstObject;
        //音频的范围
        CMTimeRange kj_audioTimeRange = CMTimeRangeMake(kCMTimeZero, kj_audioAsset.duration);
        if (CMTimeCompare(kj_audioAsset.duration, kj_videoAsset.duration)) {//当视频时间小于音频时间
            kj_audioTimeRange = CMTimeRangeMake(kCMTimeZero, kj_videoAsset.duration);
        }
        //采集的音频加入到音频通道kj_audioTrack
        NSError *kj_audioError = nil;
        BOOL isComplete_audio = [kj_audioTrack insertTimeRange:kj_audioTimeRange
                                                       ofTrack:kj_assetAudio
                                                        atTime:kCMTimeZero
                                                         error:&kj_audioError];
        NSLog(@"加入音频isComplete_audio：%d error：%@",isComplete_audio, kj_audioError);
        
        //因为要保存相册，所以设置高质量, 这里可以根据实际情况进行更改
        WS(weakSelf)
        [KJUtility kj_compressedVideoAsset:kj_composition withPresetName:AVAssetExportPresetHighestQuality withNewSavePath:newVideoPath withCompleteBlock:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    NSLog(@"转码失败：%@", error);
                    [KJUtility hideProgressDialog];
                } else {
                    [weakSelf.kj_newVideoPathArray addObject:newVideoPath];
                    [weakSelf saveVideoToLib];
                }
            });
        }];
    }
}

//压缩视频
- (void)compressedVideo:(NSString *)localIdentifier {
    //准备压缩的视频路径
    NSURL *kj_comUrl = self.kj_videoUrl;
    if (self.kj_newVideoPathArray.count > 0) {
        kj_comUrl = self.kj_newVideoPathArray.lastObject;
    }
    NSDictionary *kj_options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
    AVURLAsset* kj_comAsset = [AVURLAsset URLAssetWithURL:kj_comUrl options:kj_options];
    
    //压缩后的视频存放路径
    NSString *kj_newPath = [KJUtility kj_getKJAlbumFilePath];
    kj_newPath = [kj_newPath stringByAppendingPathComponent:[KJUtility kj_getNewFileName]];
    unlink([kj_newPath UTF8String]);
    WS(weakSelf)
    [KJUtility kj_compressedVideoAsset:kj_comAsset withPresetName:AVAssetExportPresetMediumQuality withNewSavePath:[NSURL fileURLWithPath:kj_newPath] withCompleteBlock:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"转码失败：%@", error);
                [KJUtility hideProgressDialog];
            } else {
                if (weakSelf.kj_isSelectCover) {
                    [weakSelf pushCover:[NSURL fileURLWithPath:kj_newPath] identifier:localIdentifier];
                } else {
                    if (weakSelf.editCompleteBlock) {
                        weakSelf.editCompleteBlock([NSURL fileURLWithPath:kj_newPath], localIdentifier, nil);
                    }
                    [weakSelf onCancelAction:nil];
                }
            }
        });
    }];
}

//保存到相册
- (void)saveVideoToLib {
    WS(weakSelf)
    NSURL *url = self.kj_newVideoPathArray.lastObject;
    [KJUtility kj_saveVideoToLibraryForPath:url.path completeHandler:^(NSString *localIdentifier, BOOL isSuccess) {
        if (isSuccess) {
            NSLog(@"保存到相册成功,接下来转码低质量视频用于上传");
            //发送服务器的需要压缩低质量
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf compressedVideo:localIdentifier];
            });
        } else {
            NSLog(@"保存到相册失败");
        }
    }];
}

//处理从外面传进来的视频路径
- (NSURL *)getLocalVideoPath {
    NSURL *url;
    if ([self.kj_localVideo isKindOfClass:[NSString class]]) {
        NSString *localStr = self.kj_localVideo;
        if ([localStr hasPrefix:@"file"]) {
            url = [NSURL URLWithString:self.kj_localVideo];
        } else {
            url = [NSURL fileURLWithPath:self.kj_localVideo];
        }
    } else if ([self.kj_localVideo isKindOfClass:[AVURLAsset class]]) {
        AVURLAsset *urlAsset = self.kj_localVideo;
        url = urlAsset.URL;
    } else if ([self.kj_localVideo isKindOfClass:[NSURL class]]) {
        url = self.kj_localVideo;
    } else {
        NSLog(@"不支持%@类型(支持的类型有NSString、AVURLAsset、NSURL)",NSStringFromClass([self.kj_localVideo class]));
    }
    return url;
}

//解析本地json获取滤镜相关数据
- (NSDictionary *)getFilterGeojsonFile {
    NSDictionary *json_dict;
    NSString *strPath = [[NSBundle mainBundle] pathForResource:@"KJFilter" ofType:@"geojson"];
    if (strPath) {
        NSString *parseJson = [[NSString alloc] initWithContentsOfFile:strPath encoding:NSUTF8StringEncoding error:nil];
        //去除空格
        parseJson = [parseJson stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
        parseJson = [parseJson stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        parseJson = [parseJson stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        NSData *jsonData = [parseJson dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        json_dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    }
    return json_dict;
}


//添加播放器通知
-(void)addNotification{
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.kj_player.currentItem];
}

//移除通知
-(void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//播放完成通知
-(void)playbackFinished:(NSNotification *)notification{
    NSLog(@"视频播放完成,重新播放");
    // 播放完成后重复播放
    // 跳到最新的时间点开始播放
    [self.kj_player seekToTime:kCMTimeZero];
    if (self.kj_selectedMusic) {
        [self.kj_musicPlayer seekToTime:kCMTimeZero];
        [self.kj_musicPlayer play];
    }
    [self.kj_player play];
    [self.kj_showMovie startProcessing];
}

//创建UICollectionView
- (UICollectionView *)custonCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 5.f;
    UICollectionView *colectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    colectionView.delegate = self;
    colectionView.dataSource = self;
    [KJEditVideoCell regisCellForCollectionView:colectionView];
    return colectionView;
}


//创建label
- (UILabel *)customTitleLabel {
    UILabel *label = [UILabel new];
    label.font = [UIFont systemFontOfSize:15.0f];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    return label;
}


- (void)pushCover:(NSURL *)url identifier:(NSString *)identifier {
    KJSelectedCoverController *ctrl = [[KJSelectedCoverController alloc] init];
    ctrl.kj_videoUrl = url;
    WS(weakSelf)
    ctrl.kj_coverCompleteBlock = ^(UIImage *kj_cover) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.editCompleteBlock) {
                weakSelf.editCompleteBlock(url, identifier, kj_cover);
            }
            [weakSelf onCancelAction:nil];
        });
    };
    [self.navigationController pushViewController:ctrl animated:YES];
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
