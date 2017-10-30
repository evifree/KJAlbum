//
//  KJVideoAlbumController.h
//  Join
//
//  Created by JOIN iOS on 2017/9/5.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJUtility.h"

@interface KJVideoAlbumController : UIViewController

@property (assign, nonatomic)CGFloat kj_minTime;
@property (assign, nonatomic)CGFloat kj_maxTime;

@property (copy, nonatomic) void (^kj_complete)(NSURL *outPath);

@end
