//
//  KJImageAlbumController.m
//  Join
//
//  Created by JOIN iOS on 2017/9/2.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import "KJImageAlbumController.h"
#import "KJUtility.h"
#import "KJSystemPhotoAlbumController.h"
#import "KJCustomCameraController.h"

#import "SGSegmentedControl.h"
#import "UIView+SGExtension.h"

#import "KJPHAsset.h"

@interface KJImageAlbumController ()<UIScrollViewDelegate,SGSegmentedControlStaticDelegate, KJCustomCameraDelegate, KJSystemPhotoAlbumDelegate>

///加载页面的滚动视图
@property (nonatomic, strong) SGSegmentedControlStatic *bottomSView;

@property (nonatomic, strong) SGSegmentedControlBottomView *topView;

@property (nonatomic, strong) KJCustomCameraController *cameraCtrl;

@end

@implementation KJImageAlbumController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (!self.kj_selectArray) {
        self.kj_selectArray = [NSMutableArray arrayWithCapacity:0];
    }
    KJSystemPhotoAlbumController *albumCtrl = [[KJSystemPhotoAlbumController alloc] init];
    albumCtrl.maxCount = self.kj_maxCount;
    albumCtrl.kj_selectArray = self.kj_selectArray;
    albumCtrl.kj_photoAlbumDelegate = self;
    [self addChildViewController:albumCtrl];
    self.cameraCtrl = [[KJCustomCameraController alloc] init];
    self.cameraCtrl.maxCount = self.kj_maxCount;
    self.cameraCtrl.kj_selectArray = self.kj_selectArray;
    self.cameraCtrl.kj_cameraDelegate = self;
    [self addChildViewController:self.cameraCtrl];
    
    self.topView = [[SGSegmentedControlBottomView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-49)];
    self.topView.childViewController = @[albumCtrl,self.cameraCtrl];
    self.topView.delegate = self;
    [self.view addSubview:self.topView];
    NSArray *titles = @[@"相册",@"拍照"];
    self.bottomSView = [SGSegmentedControlStatic segmentedControlWithFrame:CGRectMake(0, SCREEN_HEIGHT-49, SCREEN_WIDTH, 49.0) delegate:self childVcTitle:titles homeStyle:@"CAMARE_STYLE"];
    self.bottomSView.backgroundColor=[UIColor blackColor];
    self.bottomSView.titleColorStateNormal=[UIColor whiteColor];
    self.bottomSView.btn_fondOfSize = 16.0f;
    self.bottomSView.titleColorStateSelected=[UIColor colorWithHex:sYellowColor];
    self.bottomSView.indicatorColor=[UIColor colorWithHex:sYellowColor];
    [self.view addSubview:self.bottomSView];
//    for (int i = 0; i < titles.count; i ++) {
//        [self.topView showChildVCViewWithIndex:i outsideVC:self];
//    }
    self.bottomSView.contentOffset = CGPointMake(0, 0);
    [self scrollViewDidScroll:self.topView];
    [self scrollViewDidEndDecelerating:self.topView];
    [self.topView showChildVCViewWithIndex:0 outsideVC:self];
}

- (void)SGSegmentedControlStatic:(SGSegmentedControlStatic *)segmentedControlStatic didSelectTitleAtIndex:(NSInteger)index {
    if (index == 1) {
        [self.cameraCtrl kj_startCameraCapture];
    } else {
        [self.cameraCtrl kj_stopCameraCapture];
    }
    // 计算滚动的位置
    CGFloat offsetX = index * self.view.frame.size.width;
    self.topView.contentOffset = CGPointMake(offsetX, 0);
    [self.topView showChildVCViewWithIndex:index outsideVC:self];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    // 计算滚动到哪一页
    NSInteger index = scrollView.contentOffset.x / scrollView.frame.size.width;
    if (index == 1) {
        [self.cameraCtrl kj_startCameraCapture];
    } else {
        [self.cameraCtrl kj_stopCameraCapture];
    }
    // 2.把对应的标题选中
    [self.bottomSView changeThePositionOfTheSelectedBtnWithScrollView:scrollView scrollViewBool:YES indexRow:index];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 计算滚动到哪一页
    NSInteger index = scrollView.contentOffset.x / scrollView.frame.size.width;
    [self.topView showChildVCViewWithIndex:index outsideVC:self];
    self.bottomSView.indicatorView.SG_x =scrollView.contentOffset.x/[UIScreen mainScreen].bounds.size.width*[UIScreen mainScreen].bounds.size.width/2;
    
    [self.bottomSView changeThePositionOfTheSelectedBtnWithScrollView:scrollView scrollViewBool:YES indexRow:index];
    [self.bottomSView selectedTitleBtnColorGradualChangeScrollViewDidScroll:scrollView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleCompleteForArray:(NSMutableArray *)dataArray {

    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:0];
    for (KJPHAsset *kj_asset in dataArray) {
        if (kj_asset.localImage) {
            [photos addObject:kj_asset.localImage];
        } else {
            [KJUtility kj_requestImageForAsset:kj_asset.asset withSynchronous:YES completion:^(UIImage *image) {
                [photos addObject:image];
            }];
        }
    }
    if (self.completeBlock) {
        self.completeBlock(photos, dataArray);
    }
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
    }];
    
}

#pragma mark - KJSystemPhotoAlbumDelegate
- (void)kj_SystemPhotoAlbumSelectedComplete:(NSMutableArray *)selectedItems {
    [self handleCompleteForArray:selectedItems];
}

- (void)kj_SystemPhotoAlbumCancel {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - KJCustomCameraDelegate
- (void)kj_didResetTakeAction {
    self.bottomSView.hidden = NO;
    self.topView.scrollEnabled = YES;
}

- (void)kj_didStartTakeAction {
    self.bottomSView.hidden = YES;
    self.topView.scrollEnabled = NO;
}

- (void)kj_didCompleteAction {
    [self handleCompleteForArray:self.kj_selectArray];
}

- (void)kj_didCancelAction {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
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
