//
//  KJSystemVideoAlbumController.h
//  Join
//
//  Created by JOIN iOS on 2017/9/4.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJUtility.h"

@protocol KJSystemVideoAlbumDelegate <NSObject>

@optional

- (void)kj_videoAlbumComplete:(AVAsset *)kj_avasset withPath:(NSString *)path;

@end

@interface KJSystemVideoAlbumController : UIViewController

@property (assign, nonatomic)CGFloat kj_minTime;
@property (assign, nonatomic)CGFloat kj_maxTime;
@property (weak, nonatomic) id<KJVideoFileDelegate>kj_fileDelegate;


//停止播放
- (void)stopPlayer;

@end
