//
//  KJShortVideoPlayer.h
//  Join
//
//  Created by JOIN iOS on 2017/9/4.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJUtility.h"

@interface KJShortVideoPlayer : UIView

@property (strong, nonatomic) AVURLAsset *kj_urlAsset;

//隐藏总时间和当前播放时间的显示
- (void)setTimeHidden;
//隐藏播放的进度条的显示
- (void)setSliderHidden;

- (void)stopPlayer;

@end
