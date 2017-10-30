//
//  KJVideoCameraController.h
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/9/5.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJUtility.h"

@interface KJVideoCameraController : UIViewController

@property (assign, nonatomic) CGFloat kj_minTime;
@property (assign, nonatomic) CGFloat kj_maxTime;


@property (weak, nonatomic) id<KJCustomCameraDelegate>kj_cameraDelegate;

@property (weak, nonatomic) id<KJVideoFileDelegate> kjFileDelegate;

- (void)kj_stopCameraCapture;
- (void)kj_startCameraCapture;

@end
