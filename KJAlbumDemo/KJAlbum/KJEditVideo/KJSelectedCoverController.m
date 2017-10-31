//
//  KJSelectedCoverController.m
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/10/27.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import "KJSelectedCoverController.h"
#import "KJCoverViewCell.h"

@interface KJSelectedCoverController ()<UICollectionViewDelegate, UICollectionViewDataSource>

//封面图数组
@property (strong, nonatomic) NSMutableArray *kj_coverArray;
//视频
@property (strong, nonatomic) AVURLAsset *kj_urlAsset;
//顶部view
@property (nonatomic, strong) UIView *kj_topView;
//完成按钮
@property (nonatomic, strong) UIButton *kj_btnComplete;
//取消
@property (nonatomic, strong) UIButton *kj_btnCancel;
//显示封面图
@property (nonatomic, strong) UICollectionView *kj_collectionView;
//选中的封面
@property (nonatomic, strong) NSIndexPath *kj_indexPath;
@end

#define ItemSpacing 8.0

@implementation KJSelectedCoverController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.kj_urlAsset = [AVURLAsset assetWithURL:self.kj_videoUrl];
    self.kj_coverArray = [NSMutableArray arrayWithCapacity:0];
    //视频的总时间
    CMTime time = [self.kj_urlAsset duration];
    CGFloat second = 1.0*time.value/time.timescale;
    if (second < 0.5) {
        UIImage *cover = [KJUtility kj_getScreenShotImageFromVideoPath:self.kj_urlAsset withStart:0 withTimescale:time.timescale];
        NSDictionary *dict = @{@"time":@"0",@"image":cover};
        [self.kj_coverArray addObject:dict];
    } else {
        CGFloat coverTime = 0.5;
        while (second >= coverTime) {
            NSDictionary *dict = @{@"time":[NSNumber numberWithFloat:coverTime]};
            [self.kj_coverArray addObject:dict];
            coverTime += 0.5;
        }
    }
    WS(weakSelf)
    //顶部导航
    self.kj_topView = [UIView new];
    self.kj_topView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.kj_topView];
    [self.kj_topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.view.mas_top).offset(0);
        make.centerX.equalTo(weakSelf.view.mas_centerX).offset(0);
        make.size.mas_equalTo(CGSizeMake(SCREEN_WIDTH, 44.0f));
    }];
    
    self.kj_btnCancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.kj_btnCancel setTitle:@"取消" forState:UIControlStateNormal];
    [self.kj_btnCancel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.kj_btnCancel.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [self.kj_btnCancel addTarget:self action:@selector(onCancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.kj_topView addSubview:self.kj_btnCancel];
    [self.kj_btnCancel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.kj_topView.mas_top).offset(0);
        make.bottom.equalTo(weakSelf.kj_topView.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.kj_topView.mas_left).offset(0);
        make.width.mas_equalTo(60.0f);
    }];
    
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:15.0f];
    label.textColor = [UIColor whiteColor];
    label.text = @"选择封面图";
    label.textAlignment = NSTextAlignmentCenter;
    [self.kj_topView addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(weakSelf.kj_topView);
    }];
    
    self.kj_btnComplete = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.kj_btnComplete setTitleColor:[UIColor colorWithHex:0x000000] forState:UIControlStateNormal];
    [self.kj_btnComplete setBackgroundColor:[UIColor colorWithHex:sYellowColor]];
    self.kj_btnComplete.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    [self.kj_btnComplete setTitle:@"完成" forState:UIControlStateNormal];
    [self.kj_btnComplete addTarget:self action:@selector(onCompleteButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.kj_topView addSubview:self.kj_btnComplete];
    self.kj_btnComplete.layer.cornerRadius = 2.0f;
    self.kj_btnComplete.layer.masksToBounds = YES;
    [self.kj_btnComplete mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(weakSelf.kj_topView.mas_right).offset(-13);
        make.size.mas_equalTo(CGSizeMake(60.0f, 26.0f));
        make.centerY.equalTo(weakSelf.kj_topView.mas_centerY).offset(0);
    }];
    
    //UICollectionView
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc]init];
    layout.minimumInteritemSpacing = ItemSpacing;
    layout.minimumLineSpacing = ItemSpacing;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.itemSize = CGSizeMake(SCREEN_WIDTH/8.0, SCREEN_WIDTH/8.0);
    self.kj_collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.kj_collectionView.backgroundColor = [UIColor blackColor];
    self.kj_collectionView.delegate = self;
    self.kj_collectionView.dataSource = self;
    self.kj_collectionView.decelerationRate = 0;
    [self.self.view addSubview:self.kj_collectionView];
    [self.kj_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.kj_topView.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
        make.bottom.equalTo(weakSelf.view.mas_bottom).offset(0);
    }];
    [KJCoverViewCell regisCellForCollectionView:self.kj_collectionView];
    //默认选中第一张图
    self.kj_indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.kj_collectionView reloadData];
    [self.kj_collectionView selectItemAtIndexPath:self.kj_indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
}

- (void)onCancelButtonAction:(id)sender {
    NSDictionary *dict =self.kj_coverArray[self.kj_indexPath.row];
    if (self.kj_coverCompleteBlock) {
        self.kj_coverCompleteBlock(dict[@"image"]);
    }
}

- (void)onCompleteButtonAction:(id)sender {
    NSDictionary *dict =self.kj_coverArray[self.kj_indexPath.row];
    if (self.kj_coverCompleteBlock) {
        self.kj_coverCompleteBlock(dict[@"image"]);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.kj_coverArray.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    int itemWidth = (SCREEN_WIDTH-ItemSpacing*3)/2.0;
    return CGSizeMake(itemWidth, itemWidth);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(ItemSpacing, ItemSpacing, ItemSpacing, ItemSpacing);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    KJCoverViewCell *cell = [KJCoverViewCell dequeueCellForCollectionView:collectionView withIndex:indexPath];
    NSDictionary *dict = self.kj_coverArray[indexPath.row];
    if (dict[@"image"]) {
        cell.kj_imgView.image = dict[@"image"];
    } else {
        UIImage *image = [KJUtility kj_getScreenShotImageFromVideoPath:self.kj_urlAsset withStart:[dict[@"time"] floatValue] withTimescale:60];
        cell.kj_imgView.image = image;
        dict = @{@"time":dict[@"time"], @"image":image};
        [self.kj_coverArray replaceObjectAtIndex:indexPath.row withObject:dict];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.kj_indexPath = indexPath;
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
