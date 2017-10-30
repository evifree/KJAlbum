//
//  KJShortVideoPlayer.m
//  Join
//
//  Created by JOIN iOS on 2017/9/4.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import "KJShortVideoPlayer.h"
#import <Masonry.h>

@interface KJShortVideoPlayer ()

//播放器对象
@property (nonatomic,strong) AVPlayer *kj_player;

//播放层
@property (nonatomic, strong)AVPlayerLayer *kj_playerLayer;

//进度条slider
@property (strong, nonatomic) UISlider *kj_slider;

//显示总时间label
@property (strong, nonatomic) UILabel *labelTime_total;

//显示已播放的时间
@property (strong, nonatomic) UILabel *labelTime_current;

//中间的开始按钮
@property (strong, nonatomic) UIButton *btnStart;

@end

@implementation KJShortVideoPlayer

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.kj_player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.kj_player pause];
}

- (instancetype)init {
    if (self = [super init]) {
        [self customUI];
    }
    return self;
}

- (void)customUI {
    WS(weakSelf)
    self.btnStart = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnStart setImage:[UIImage imageNamed:@"kj_video_album_start"] forState:UIControlStateNormal];
    [self.btnStart addTarget:self action:@selector(onStartButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.btnStart];
    [self.btnStart mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf);
    }];
    
    self.kj_slider = [[UISlider alloc] init];
    UIImage *image = [[UIImage imageWithColor:[UIColor whiteColor]] imageScaledToSize:CGSizeMake(20, 20)];
    image = [image imageWithCornerRadius:image.size.height/2.0];
    [self.kj_slider setThumbImage:image forState:UIControlStateNormal];
    [self.kj_slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];// 针对值变化添加响应方法
    [self.kj_slider addTarget:self action:@selector(sliderTouchCancel:) forControlEvents:UIControlEventTouchUpInside];
    [self.kj_slider addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:self.kj_slider];
    [self.kj_slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(weakSelf.mas_bottom).offset(-9.0f);
        make.left.equalTo(weakSelf.mas_left).offset(46.0f);
        make.right.equalTo(weakSelf.mas_right).offset(-46.0f);
    }];
    
    
    self.labelTime_current = [UILabel new];
    self.labelTime_current.textColor = [UIColor colorWithHex:0xffffff];
    self.labelTime_current.font = [UIFont systemFontOfSize:12.0f];
    self.labelTime_current.textAlignment = NSTextAlignmentCenter;
    self.labelTime_current.text = @"00:00";
    [self addSubview:self.labelTime_current];
    [self.labelTime_current mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(weakSelf.mas_left).offset(0);
        make.right.equalTo(weakSelf.kj_slider.mas_left).offset(0);
        make.centerY.equalTo(weakSelf.kj_slider.mas_centerY).offset(0);
    }];
    
    self.labelTime_total = [UILabel new];
    self.labelTime_total.textColor = [UIColor colorWithHex:0xffffff];
    self.labelTime_total.font = [UIFont systemFontOfSize:12.0f];
    self.labelTime_total.textAlignment = NSTextAlignmentCenter;
    self.labelTime_total.text = @"00:00";
    [self addSubview:self.labelTime_total];
    [self.labelTime_total mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(weakSelf.mas_right).offset(0);
        make.left.equalTo(weakSelf.kj_slider.mas_right).offset(0);
        make.centerY.equalTo(weakSelf.kj_slider.mas_centerY).offset(0);
    }];
}

- (void)onStartButtonAction:(UIButton *)sender {
    self.btnStart.hidden = YES;
    
    if (self.kj_slider.value == self.kj_slider.maximumValue) {
        [self.kj_player seekToTime:CMTimeMake(0, self.kj_player.currentItem.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
    [self.kj_player play];
}

- (void)sliderValueChanged:(id)sender {
    //调整进度
    if (self.kj_player) {
        [self.kj_player seekToTime:CMTimeMake(self.kj_slider.value*(self.kj_player.currentItem.duration.timescale), self.kj_player.currentItem.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
    self.labelTime_current.text = [KJUtility getMMSSFromSS:(int)self.kj_slider.value];
}

- (void)sliderTouchCancel:(id)sender {
    self.btnStart.hidden = YES;
    //调整完进度后开始播放
    [self.kj_player play];
}

- (void)sliderTouchDown:(id)sender {
    //调整播放进度前暂停播放
    [self.kj_player pause];
}

- (void)setKj_urlAsset:(AVURLAsset *)kj_urlAsset {
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:kj_urlAsset];
    //播放器处理
    if (!self.kj_player) {
        self.kj_player = [AVPlayer playerWithPlayerItem:item];
    } else {
        //移除上个视频的监听
        [self.kj_player.currentItem removeObserver:self forKeyPath:@"status"];
        //切换前暂停播放
        [self.kj_player pause];
        [self.kj_player replaceCurrentItemWithPlayerItem:item];
    }
    
    //时间处理
    CMTime   time = [kj_urlAsset duration];
    int seconds = ceil(time.value/time.timescale);
    self.kj_slider.minimumValue = 0;
    self.kj_slider.maximumValue = seconds;
    self.labelTime_total.text = [KJUtility getMMSSFromSS:seconds];
    [self.kj_player seekToTime:CMTimeMake(0, time.timescale)];
    
    //播放层处理
    if (!self.kj_playerLayer) {
        self.kj_playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.kj_player];
        self.kj_playerLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH);
        self.kj_playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self.layer insertSublayer:self.kj_playerLayer atIndex:0];
    }
    
    //通知处理
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    self.btnStart.hidden = YES;
    //开始播放
    [self.kj_player play];
}

//播放到结束时间
- (void)playDidPlayToEndTimeNotification:(NSNotification *)ntf {
    self.btnStart.hidden = NO;
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
    [self.kj_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:NULL usingBlock:^(CMTime time) {
        int currentTime = ceil(time.value/time.timescale);
        weakSelf.labelTime_current.text = [NSString stringWithFormat:@"%@",[KJUtility getMMSSFromSS:currentTime]];
        weakSelf.kj_slider.value = 1.0*time.value/time.timescale;
    }];
}

//从外面进行暂停播放
- (void)stopPlayer {
    if (self.kj_player.rate == 1.0) {
        [self.kj_player pause];
        self.btnStart.hidden = NO;
    }
}

//隐藏总时间和当前播放时间的显示
- (void)setTimeHidden {
    self.kj_slider.hidden = YES;
}

//隐藏播放的进度条的显示
- (void)setSliderHidden {
    self.labelTime_total.hidden = YES;
    self.labelTime_current.hidden = YES;
}

@end
