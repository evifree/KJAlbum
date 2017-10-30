//
//  KJVideoAlbumController.m
//  Join
//
//  Created by JOIN iOS on 2017/9/5.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import "KJVideoAlbumController.h"
#import "KJSystemVideoAlbumController.h"
#import "SGSegmentedControl.h"
#import "UIView+SGExtension.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "KJSystemVideoAlbumController.h"
#import "KJVideoCameraController.h"

@interface KJVideoAlbumController ()<UIScrollViewDelegate,SGSegmentedControlStaticDelegate, KJVideoFileDelegate, KJCustomCameraDelegate>

///加载页面的滚动视图
@property (nonatomic, strong) SGSegmentedControlStatic *bottomSView;

@property (nonatomic, strong) SGSegmentedControlBottomView *topView;

@property (strong, nonatomic) KJVideoCameraController *recordViewController;
@property (strong, nonatomic) KJSystemVideoAlbumController *videoViewController;
@end

@implementation KJVideoAlbumController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    //让其他应用的声音停止
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:YES error:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.videoViewController = [[KJSystemVideoAlbumController alloc] init];
    self.videoViewController.kj_minTime = 2.0;
    self.videoViewController.kj_maxTime = 15.0f;
    self.videoViewController.kj_fileDelegate = self;
    [self addChildViewController:self.videoViewController];
    
    self.recordViewController = [[KJVideoCameraController alloc] init];
    self.recordViewController.kj_maxTime = 15.0;
    self.recordViewController.kj_minTime = 2.0;
    self.recordViewController.kj_cameraDelegate = self;
    self.recordViewController.kjFileDelegate = self;
    [self addChildViewController:self.recordViewController];
    
    self.topView = [[SGSegmentedControlBottomView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-49)];
    self.topView.childViewController = @[self.videoViewController,self.recordViewController];
    self.topView.delegate = self;
    [self.view addSubview:self.topView];
    NSArray *titles = @[@"相册",@"拍摄 "];
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
        [self.recordViewController kj_startCameraCapture];
        [self.videoViewController stopPlayer];
    } else {
        [self.recordViewController kj_stopCameraCapture];
    }
    // 计算滚动的位置
    CGFloat offsetX = index * self.view.frame.size.width;
    self.topView.contentOffset = CGPointMake(offsetX, 0);
    [self.topView showChildVCViewWithIndex:index outsideVC:self];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 计算滚动到哪一页
    NSInteger index = scrollView.contentOffset.x / scrollView.frame.size.width;
    // 2.把对应的标题选中
    [self.bottomSView changeThePositionOfTheSelectedBtnWithScrollView:scrollView scrollViewBool:YES indexRow:index];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 计算滚动到哪一页
    NSInteger index = scrollView.contentOffset.x / scrollView.frame.size.width;
    [self.topView showChildVCViewWithIndex:index outsideVC:self];
    self.bottomSView.indicatorView.SG_x =scrollView.contentOffset.x/[UIScreen mainScreen].bounds.size.width*[UIScreen mainScreen].bounds.size.width/2;
    if (index == 1) {
        [self.recordViewController kj_startCameraCapture];
        [self.videoViewController stopPlayer];
    } else {
        [self.recordViewController kj_stopCameraCapture];
    }
    [self.bottomSView changeThePositionOfTheSelectedBtnWithScrollView:scrollView scrollViewBool:YES indexRow:index];
    [self.bottomSView selectedTitleBtnColorGradualChangeScrollViewDidScroll:scrollView];
}

#pragma mark - KJVideoFileDelegate
- (void)kj_videoFileCompleteLocalPath:(NSString *)kj_outPath{
    NSURL *url;
    if ([kj_outPath hasPrefix:@"file"]) {
        url = [NSURL URLWithString:kj_outPath];
    } else {
        url = [NSURL fileURLWithPath:kj_outPath];
    }
    if (self.kj_complete) {
        self.kj_complete(url);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
//    [self handleCompleteForArray:self.kj_selectArray];
}

- (void)kj_didCancelAction {
    //当离开该页面。让其他应用声音恢复
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
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
