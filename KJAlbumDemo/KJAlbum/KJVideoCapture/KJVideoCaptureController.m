//
//  KJVideoCaptureController.m
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/9/7.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import "KJVideoCaptureController.h"
#import "KJShortVideoPlayer.h"
#import "KJShortPhotoAlbumCell.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface KJVideoCaptureController ()<UICollectionViewDelegate, UICollectionViewDataSource>


//顶部view
@property (nonatomic, strong) UIView *kj_top_bgView;
//完成按钮
@property (nonatomic, strong) UIButton *btn_complete;
//取消
@property (nonatomic, strong) UIButton *btn_cancel;

//播放区域
@property (nonatomic, strong) UIView *kj_center_bgView;
//播放器对象
@property (nonatomic,strong) AVPlayer *kj_player;
//播放层
@property (nonatomic, strong)AVPlayerLayer *kj_playerLayer;

//选择裁剪区域
@property (nonatomic, strong) UIView *kj_bottom_bgView;
@property (nonatomic, strong) UIButton *btnStart;//左侧滑块
@property (nonatomic, strong) UIButton *btnEnd;//右侧滑块
@property (nonatomic, strong) UIView *leftView;//左侧蒙板
@property (nonatomic, strong) UIView *rightView;//右侧蒙板
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *kj_dataArray;
@property (nonatomic, strong) UIView *kj_slider;//播放进度
@property (nonatomic, strong) UILabel *labelTime;//当前截取的时间

@property (nonatomic, strong) AVURLAsset *kj_urlAsset;

@property (assign, nonatomic) CGFloat pixel_time;
@property (assign, nonatomic) int rowCount;

@end

@implementation KJVideoCaptureController

- (void)dealloc {
    [self.kj_player pause];
    [self.kj_player.currentItem removeObserver:self forKeyPath:@"status"];
    self.kj_player = nil;
    self.kj_playerLayer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (self.kj_minTime <= 0) {
        self.kj_minTime = 0;
    }
    self.kj_dataArray = [NSMutableArray arrayWithCapacity:0];
    
    WS(weakSelf)
    //顶部导航
    self.kj_top_bgView = [UIView new];
    self.kj_top_bgView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.kj_top_bgView];
    [self.kj_top_bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.view.mas_top).offset(0);
        make.centerX.equalTo(weakSelf.view.mas_centerX).offset(0);
        make.size.mas_equalTo(CGSizeMake(SCREEN_WIDTH, 44.0f));
    }];
    
    self.btn_cancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btn_cancel setTitle:@"取消" forState:UIControlStateNormal];
    [self.btn_cancel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.btn_cancel.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [self.btn_cancel addTarget:self action:@selector(onCancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.kj_top_bgView addSubview:self.btn_cancel];
    [self.btn_cancel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.kj_top_bgView.mas_top).offset(0);
        make.bottom.equalTo(weakSelf.kj_top_bgView.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.kj_top_bgView.mas_left).offset(0);
        make.width.mas_equalTo(60.0f);
    }];
    
    self.btn_complete = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btn_complete setTitleColor:[UIColor colorWithHex:0x000000] forState:UIControlStateNormal];
    [self.btn_complete setBackgroundColor:[UIColor colorWithHex:sYellowColor]];
    self.btn_complete.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    [self.btn_complete setTitle:@"完成" forState:UIControlStateNormal];
    [self.btn_complete addTarget:self action:@selector(onCompleteButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.kj_top_bgView addSubview:self.btn_complete];
    self.btn_complete.layer.cornerRadius = 2.0f;
    self.btn_complete.layer.masksToBounds = YES;
    [self.btn_complete mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(weakSelf.kj_top_bgView.mas_right).offset(-13);
        make.size.mas_equalTo(CGSizeMake(60.0f, 26.0f));
        make.centerY.equalTo(weakSelf.kj_top_bgView.mas_centerY).offset(0);
    }];
    
    //中间播放层
    self.kj_center_bgView = [UIView new];
    [self.view addSubview:self.kj_center_bgView];
    [self.kj_center_bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.kj_top_bgView.mas_bottom).offset(0);
        make.centerX.equalTo(weakSelf.view.mas_centerX).offset(0);
        make.size.mas_equalTo(CGSizeMake(SCREEN_WIDTH, SCREEN_WIDTH));
    }];
    
    if ([self.kj_videoObject isKindOfClass:[NSString class]]) {
        self.kj_urlAsset = [AVURLAsset assetWithURL:[NSURL URLWithString:self.kj_videoObject]];
    } else if ([self.kj_videoObject isKindOfClass:[NSURL class]]) {
        self.kj_urlAsset = [AVURLAsset assetWithURL:self.kj_videoObject];
    } else {
        self.kj_urlAsset = self.kj_videoObject;
    }
    AVPlayerItem *videoItem = [AVPlayerItem playerItemWithAsset:self.kj_urlAsset];
    self.kj_player = [AVPlayer playerWithPlayerItem:videoItem];
    self.kj_playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.kj_player];
    self.kj_playerLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH);
    self.kj_playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.kj_center_bgView.layer insertSublayer:self.kj_playerLayer atIndex:0];
    [videoItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //底部调整区间层
    self.kj_bottom_bgView = [UIView new];
    self.kj_bottom_bgView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.kj_bottom_bgView];
    [self.kj_bottom_bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.kj_center_bgView.mas_bottom).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.bottom.equalTo(weakSelf.view.mas_bottom).offset(0);
    }];

    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc]init];
    layout.minimumInteritemSpacing = 0.0f;
    layout.minimumLineSpacing = 0.0f;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(SCREEN_WIDTH/8.0, SCREEN_WIDTH/8.0);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor blackColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.decelerationRate = 0;
    [self.kj_bottom_bgView addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(SCREEN_WIDTH, SCREEN_WIDTH/8.0));
        make.center.equalTo(weakSelf.kj_bottom_bgView);
    }];
    [KJShortPhotoAlbumCell regisCellForCollectionView:self.collectionView];
    
    self.btnStart = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnStart setBackgroundColor:[UIColor colorWithHex:sYellowColor]];
    [self.kj_bottom_bgView addSubview:self.btnStart];
    [self.btnStart mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(weakSelf.kj_bottom_bgView.mas_left).offset(0);
        make.centerY.equalTo(weakSelf.collectionView);
        make.size.mas_equalTo(CGSizeMake(20, SCREEN_WIDTH/8.0));
    }];

    self.leftView = [UIView new];
    self.leftView.backgroundColor = [UIColor colorWithHex:0x888888 alpha:0.8];
    [self.kj_bottom_bgView addSubview:self.leftView];
    [self.leftView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(weakSelf.kj_bottom_bgView.mas_left).offset(0);
        make.right.equalTo(weakSelf.btnStart.mas_left).offset(0);
        make.height.mas_equalTo(SCREEN_WIDTH/8.0);
        make.centerY.equalTo(weakSelf.collectionView);
    }];
    
    self.btnEnd = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnEnd setBackgroundColor:[UIColor redColor]];
    [self.kj_bottom_bgView addSubview:self.btnEnd];
    [self.btnEnd mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(weakSelf.kj_bottom_bgView.mas_right).offset(0);
        make.centerY.equalTo(weakSelf.collectionView);
        make.size.mas_equalTo(CGSizeMake(20, SCREEN_WIDTH/8.0));
    }];
    
    self.rightView = [UIView new];
    self.rightView.backgroundColor = [UIColor colorWithHex:0x888888 alpha:0.8];
    [self.kj_bottom_bgView addSubview:self.rightView];
    [self.rightView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(weakSelf.kj_bottom_bgView.mas_right).offset(0);
        make.left.equalTo(weakSelf.btnEnd.mas_right).offset(0);
        make.height.mas_equalTo(SCREEN_WIDTH/8.0);
        make.centerY.equalTo(weakSelf.collectionView);
    }];
    
    UIPanGestureRecognizer *leftPanGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(leftPanGestureAction:)];
    [self.btnStart addGestureRecognizer:leftPanGes];
    UIPanGestureRecognizer *rightPanGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rightPanGestureAction:)];
    [self.btnEnd addGestureRecognizer:rightPanGes];
    
    self.kj_slider = [UIView new];
    self.kj_slider.backgroundColor = [UIColor blueColor];
    [self.kj_bottom_bgView addSubview:self.kj_slider];
    [self.kj_slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(weakSelf.collectionView);
        make.size.mas_equalTo(CGSizeMake(1.0, SCREEN_WIDTH/8.0));
        make.left.equalTo(weakSelf.btnStart.mas_left).offset(0);
    }];
    
    self.labelTime = [UILabel new];
    self.labelTime.font = [UIFont systemFontOfSize:13.0f];
    self.labelTime.textColor = [UIColor redColor];
    self.labelTime.textAlignment = NSTextAlignmentCenter;
    [self.kj_bottom_bgView addSubview:self.labelTime];
    [self.labelTime mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(weakSelf.kj_bottom_bgView);
        make.bottom.equalTo(weakSelf.collectionView.mas_top).offset(-10.0f);
    }];
    
    //处理截取视频图片
    CMTime time = [self.kj_urlAsset duration];
    CGFloat seconds = 1.0*time.value/time.timescale;
    
    if (self.kj_minTime >= seconds) {//如果最小时间大于视频的长度，那么最小时间就为视频的长度
        self.kj_minTime = seconds;
    }
    if (self.kj_maxTime <= self.kj_minTime) {//如果最大时间比最小时间小，那么最大时间就为最小时间
        self.kj_maxTime = self.kj_minTime;
    }
    if (self.kj_maxTime >= seconds) {//如果最大时间超过视频的长度，那么最大时间就为视频的总时长
        self.kj_maxTime = seconds;
    }
    
    self.labelTime.text = [NSString stringWithFormat:@"%.2f",self.kj_maxTime];
    self.pixel_time = 1.0*self.kj_maxTime/SCREEN_WIDTH;
    self.rowCount = seconds/(self.pixel_time*(SCREEN_WIDTH/8.0));
    while (self.rowCount > 0) {
        [weakSelf.kj_dataArray insertObject:[NSNumber numberWithFloat:self.rowCount*self.pixel_time*(SCREEN_WIDTH/8.0)] atIndex:0];
        self.rowCount --;
    }
    [self.kj_player play];
    [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    if (!self.navigationController.navigationBarHidden) {
        self.navigationController.navigationBarHidden = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.kj_player pause];
}

- (void)onCancelButtonAction:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onCompleteButtonAction:(UIButton *)sender {
    
    //开始剪裁
    [self.kj_player pause];
    //开始时间
    CMTime startTime = CMTimeMakeWithSeconds((self.collectionView.contentOffset.x+self.btnStart.frame.origin.x)*self.pixel_time, self.kj_player.currentItem.duration.timescale);
    //长度
    CGFloat length = (self.btnEnd.frame.origin.x+self.btnEnd.frame.size.width-self.btnStart.frame.origin.x)*self.pixel_time;
    CMTime time_total = [self.kj_player.currentItem duration];
    if (length == 1.0*time_total.value/time_total.timescale) {
        if (self.kj_videoCapturedelegate && [self.kj_videoCapturedelegate respondsToSelector:@selector(kj_didCaptureCompleteForPath:)]) {
            AVURLAsset *urlAsset = (AVURLAsset *)self.kj_player.currentItem.asset;
            [self.kj_videoCapturedelegate kj_didCaptureCompleteForPath:urlAsset.URL.path];
        } else {
            [self onCancelButtonAction:nil];
        }
        return;
    }
    
    [KJUtility showProgressDialogText:@"开始处理"];
    if (length > self.kj_maxTime) {
        length = self.kj_maxTime;
    }
    CMTime videoLenth = CMTimeMakeWithSeconds(length, self.kj_player.currentItem.duration.timescale);
    
    CMTimeRange videoTimeRange = CMTimeRangeMake(startTime, videoLenth);
    AVAssetExportSession * exportSession = [[AVAssetExportSession alloc] initWithAsset:self.kj_player.currentItem.asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.timeRange = videoTimeRange;
    NSString *path = [KJUtility kj_getKJAlbumFilePath];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *fileName = [NSString stringWithFormat:@"%@-%@",[formatter stringFromDate:[NSDate date]], @"kj_video.mp4"];
    path = [path stringByAppendingPathComponent:fileName];
    exportSession.outputURL = [NSURL fileURLWithPath:path];
    exportSession.outputFileType = AVFileTypeMPEG4;
    __block BOOL completeOK = NO;
    WS(weakSelf)
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exportSession.status) {
            case AVAssetExportSessionStatusUnknown:
                break;
            case AVAssetExportSessionStatusWaiting:
                break;
            case AVAssetExportSessionStatusExporting:
                break;
            case AVAssetExportSessionStatusCompleted:
                completeOK = YES;
                break;
            case AVAssetExportSessionStatusFailed:
                break;
            case AVAssetExportSessionStatusCancelled:
                break;
        };
        
        if (completeOK) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [KJUtility showAllTextDialog:weakSelf.view Text:@"视频截取成功"];
                if (weakSelf.kj_videoCapturedelegate && [weakSelf.kj_videoCapturedelegate respondsToSelector:@selector(kj_didCaptureCompleteForPath:)]) {
                    [KJUtility hideProgressDialog];
                    [weakSelf.kj_videoCapturedelegate kj_didCaptureCompleteForPath:path];
                } else {
                    //保存到相册
                    [KJUtility kj_saveVideoToLibraryForPath:path completeHandler:^(NSString *localIdentifier, BOOL isSuccess) {
                        if (isSuccess) {
                            NSFileManager *fileManger = [[NSFileManager alloc] init];
                            [fileManger removeItemAtPath:path error:nil];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [KJUtility hideProgressDialog];
                            [weakSelf onCancelButtonAction:nil];
                        });
                    }];
                }
            });
        } else {
            [KJUtility showAllTextDialog:weakSelf.view Text:@"视频截取失败"];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [KJUtility hideProgressDialog];
        });
    }];
}

- (void)leftPanGestureAction:(UIPanGestureRecognizer *)sender {
    WS(weakSelf)
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self.kj_player pause];
    }
    CGFloat currentLength = (self.btnEnd.frame.origin.x+self.btnEnd.frame.size.width-self.btnStart.frame.origin.x)*self.pixel_time;
    if (currentLength >= self.kj_minTime) {//不能小于最小时间
        CGPoint stopLocation = [sender locationInView:self.kj_bottom_bgView];
        CGFloat dx = stopLocation.x;
        if (dx >= self.btnEnd.frame.origin.x-20) {
            dx = self.btnEnd.frame.origin.x-20;
        }
        if (dx <= 2) {
            dx = 0;
        }
        [self.btnStart mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(weakSelf.kj_bottom_bgView.mas_left).offset(dx);
            make.centerY.equalTo(weakSelf.collectionView);
        }];
        self.labelTime.text = [NSString stringWithFormat:@"%.2f",currentLength];
        [self.kj_bottom_bgView layoutIfNeeded];
    }
    if (sender.state > 2) {
        [self startPlay];
    }
}

- (void)rightPanGestureAction:(UIPanGestureRecognizer *)sender {
    WS(weakSelf)
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self.kj_player pause];
    }
    CGFloat currentLength = (self.btnEnd.frame.origin.x+self.btnEnd.frame.size.width-self.btnStart.frame.origin.x)*self.pixel_time;
    if (currentLength >= self.kj_minTime) {//不能小于最小时间
        CGPoint stopLocation = [sender locationInView:self.kj_bottom_bgView];
        CGFloat dx = stopLocation.x;
        if (dx <= self.btnStart.frame.origin.x+40) {
            dx = self.btnStart.frame.origin.x+40;
        }
        if (dx >= SCREEN_WIDTH -2) {
            dx = SCREEN_WIDTH;
        }
        [self.btnEnd mas_updateConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(weakSelf.kj_bottom_bgView.mas_right).offset(-(SCREEN_WIDTH-dx));
            make.centerY.equalTo(weakSelf.collectionView);
        }];
        
        self.labelTime.text = [NSString stringWithFormat:@"%.2f",currentLength];
        [self.kj_bottom_bgView layoutIfNeeded];
    }
    if (sender.state > 2) {
        [self startPlay];
    }
}

//重新开始播放
- (void)startPlay {
    //先获取collectionView的contentOffset
    CGFloat cx = [self.collectionView contentOffset].x;
    CGFloat startTime = cx * self.pixel_time + self.btnStart.frame.origin.x * self.pixel_time;
    [self.kj_player seekToTime:CMTimeMake(startTime*self.kj_player.currentItem.duration.timescale, self.kj_player.currentItem.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    if (self.kj_player.rate == 0) {
        [self.kj_player play];
    }
}

//监听播放状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {//开始播放
            [self monitoringPlayback:playerItem];
        }
    }
}

//监听当前播放的进度
- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    WS(weakSelf)
    [self.kj_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 100) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentTime = 1.0*time.value/time.timescale;
        //计算出播放结束的时间
        CGFloat endTime = (weakSelf.btnEnd.frame.origin.x + self.btnEnd.frame.size.width)*weakSelf.pixel_time + weakSelf.collectionView.contentOffset.x*weakSelf.pixel_time;
        if (currentTime >= endTime) {
            if (weakSelf.kj_player.rate == 1) {
                [weakSelf.kj_player pause];
            }
            [weakSelf startPlay];
        } else {
            CGFloat slider_x = 1.0*currentTime/weakSelf.pixel_time - weakSelf.collectionView.contentOffset.x - weakSelf.btnStart.frame.origin.x;
            [weakSelf.kj_slider mas_updateConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(weakSelf.collectionView);
                make.size.mas_equalTo(CGSizeMake(1.0, SCREEN_WIDTH/8.0));
                make.left.equalTo(weakSelf.btnStart.mas_left).offset(slider_x);
            }];
            [weakSelf.kj_bottom_bgView layoutIfNeeded];
        }
    }];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.kj_player.rate == 1) {
        [self.kj_player pause];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (self.kj_player.rate == 0) {
        [self startPlay];
    }
}

#pragma mark - UICollectionViewDelegate/UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.kj_dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    KJShortPhotoAlbumCell *cell = [KJShortPhotoAlbumCell dequeueCellForCollectionView:collectionView withIndex:indexPath];
    if ([self.kj_dataArray[indexPath.row] isKindOfClass:[NSNumber class]]) {
        CGFloat startTime = [self.kj_dataArray[indexPath.row] floatValue];
        UIImage *image = [KJUtility kj_getScreenShotImageFromVideoPath:self.kj_urlAsset withStart:startTime withTimescale:10];
//        [self.kj_dataArray replaceObjectAtIndex:indexPath.row withObject:image];
        cell.imgView.image = image;
    } else {
        cell.imgView.image = self.kj_dataArray[indexPath.row];
    }
    cell.btnSelected.hidden = YES;
    return cell;
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
//    NSNumber *second = self.kj_dataArray[indexPath.row];
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
