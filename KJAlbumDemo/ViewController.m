//
//  ViewController.m
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/9/5.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import "ViewController.h"

#import "KJImageAlbumController.h"
#import "KJVideoAlbumController.h"
#import "KJEditVideoViewController.h"

@interface ViewController ()

@property (strong, nonatomic) NSMutableArray *kj_modelArray;
@property (strong, nonatomic) NSMutableArray *kj_selectPhotos;

@end


/**
 所有的视频处理，在使用后，最好是删除沙盒文件夹内容，路径可以在KJUtility中获取
 */
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onPhotoButtonAction:(UIButton *)sender {
    KJImageAlbumController *ctrl = [[KJImageAlbumController alloc] init];
    ctrl.kj_selectArray = self.kj_modelArray;//可避免重复选择
    ctrl.kj_maxCount = 6;
    ctrl.completeBlock = ^(NSMutableArray *kj_photoArray, NSMutableArray *kj_ModelArray) {
        
    };
    UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:ctrl];
    navc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:navc animated:YES completion:nil];
}


- (IBAction)onVideoButtonAction:(UIButton *)sender {
    KJVideoAlbumController *ctrl = [[KJVideoAlbumController alloc] init];
    ctrl.kj_minTime = 2.0;
    ctrl.kj_maxTime = 15.0f;
    WS(weakSelf)
    ctrl.kj_complete = ^(NSURL *outPath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf editViewPath:outPath];
        });
    };
    UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:ctrl];
    navc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:navc animated:YES completion:nil];
}

- (void)editVideo:(NSString *)localIdentifier {
    WS(weakSelf)
    [KJUtility kj_getAssetForLocalIdentifier:localIdentifier completionHandler:^(PHAsset *kj_object) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [KJUtility kj_requestVideoForAsset:kj_object completion:^(AVURLAsset *asset) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    KJEditVideoViewController *ctrl = [[KJEditVideoViewController alloc] init];
                    ctrl.kj_localVideo = asset;
                    ctrl.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                    UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:ctrl];
                    [weakSelf presentViewController:navc animated:YES completion:nil];
                });
            }];
        });
    }];
}

- (void)editViewPath:(NSURL *)path {
    KJEditVideoViewController *ctrl = [[KJEditVideoViewController alloc] init];
    ctrl.kj_localVideo = path;
    ctrl.kj_isSelectCover = YES;
    WS(weakSelf)
    ctrl.editCompleteBlock = ^(NSURL *videoPath, NSString *localidentifier, UIImage *kj_cover) {
        [weakSelf saveVideoToLibVideoUrl:videoPath];
    };
    ctrl.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:ctrl];
    [self presentViewController:navc animated:YES completion:nil];
}

//保存到相册
- (void)saveVideoToLibVideoUrl:(NSURL *)url {
    [KJUtility kj_saveVideoToLibraryForPath:url.path completeHandler:^(NSString *localIdentifier, BOOL isSuccess) {
        if (isSuccess) {
            NSLog(@"保存到相册成功");
        } else {
            NSLog(@"保存到相册失败");
        }
    }];
}

@end
