//
//  KJVideoCaptureController.h
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/9/7.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJUtility.h"

@protocol KJVideoCaptureDelegate <NSObject>

@optional

- (void)kj_didCaptureCompleteForPath:(NSString *)outPath;

@end

@interface KJVideoCaptureController : UIViewController

//可以是nsurl path avasset
@property (strong, nonatomic) id kj_videoObject;

@property (assign, nonatomic) CGFloat kj_minTime;
@property (assign, nonatomic) CGFloat kj_maxTime;

@property (weak, nonatomic) id<KJVideoCaptureDelegate>kj_videoCapturedelegate;

@end
