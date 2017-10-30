//
//  KJCustomCameraController.h
//  Join
//
//  Created by JOIN iOS on 2017/9/1.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJUtility.h"

@interface KJCustomCameraController : UIViewController

@property (assign, nonatomic) int maxCount;
@property (strong, nonatomic) NSMutableArray *kj_selectArray;

@property (weak, nonatomic) id<KJCustomCameraDelegate>kj_cameraDelegate;

- (void)kj_stopCameraCapture;
- (void)kj_startCameraCapture;

@end
