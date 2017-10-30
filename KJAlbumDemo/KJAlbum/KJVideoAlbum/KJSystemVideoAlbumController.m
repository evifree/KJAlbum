//
//  KJSystemVideoAlbumController.m
//  Join
//
//  Created by JOIN iOS on 2017/9/4.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import "KJSystemVideoAlbumController.h"
#import "KJPHAsset.h"
#import <Masonry.h>
#import "KJAlbumModel.h"
#import "KJAlbumListCell.h"
#import "KJShortVideoAlbumCell.h"
#import "KJShortVideoPlayer.h"
#import "KJVideoCaptureController.h"

@interface KJSystemVideoAlbumController ()<UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource, KJVideoCaptureDelegate>

//PHImageManager
@property (strong, nonatomic) PHImageManager *kj_defaultManager;
@property (strong, nonatomic) KJShortVideoPlayer *kj_videoPlayer;
@property (strong, nonatomic) NSMutableArray *kj_phAssetArray;

//显示相册内的视频
@property (strong, nonatomic) UICollectionView *collectionView;
//显示相册列表
@property (strong, nonatomic) UITableView *tableView;
//相册列变的背景view
@property (strong, nonatomic) UIView *tab_bgView;
//选中的相册model
@property (strong, nonatomic) KJAlbumModel *kj_albumModel;
//导航栏
@property (strong, nonatomic)UIView *bgView;
@property (strong, nonatomic)UIButton *btnLeft;
@property (strong, nonatomic)UIButton *btnRight;
@property (strong, nonatomic)UIButton *btnCenter;

//选中的视频
@property (strong, nonatomic)KJPHAsset *kj_selected_asset;


@end

@implementation KJSystemVideoAlbumController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.kj_phAssetArray = [NSMutableArray arrayWithCapacity:0];
    
    [self cunstomNavc];
    [self customVideoPlayer];
    [self customPhotoListForCollectionView];
    [self customAlbumListForTableView];
    
    //授权
    WS(weakSelf)
    [KJUtility kj_photoLibraryAuthorizationStatus:self completeBlock:^(BOOL allowAccess) {
        if (allowAccess) {
            [weakSelf getSystemVidelAlbum];
            [weakSelf.collectionView reloadData];
            [weakSelf handleSamePhoto:weakSelf.kj_albumModel.assets.firstObject];
            [weakSelf.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
            [weakSelf playerForAsset:weakSelf.kj_albumModel.assets.firstObject];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

///创建自定义导航栏
- (void)cunstomNavc {
    WS(weakSelf)
    self.bgView = [UIView new];
    self.bgView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.bgView];
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.view.mas_top).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
        make.height.mas_equalTo(44.0f);
    }];
    
    self.btnLeft = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnLeft setTitle:@"取消" forState:UIControlStateNormal];
    [self.btnLeft setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.btnLeft.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [self.btnLeft addTarget:self action:@selector(onCancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.btnLeft];
    [self.btnLeft mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.bgView.mas_top).offset(0);
        make.bottom.equalTo(weakSelf.bgView.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.bgView.mas_left).offset(0);
        make.width.mas_equalTo(60.0f);
    }];
    
    self.btnRight = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnRight setTitleColor:[UIColor colorWithHex:0x000000] forState:UIControlStateNormal];
    [self.btnRight setBackgroundColor:[UIColor colorWithHex:sYellowColor]];
    self.btnRight.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    [self.btnRight setTitle:@"继续" forState:UIControlStateNormal];
    [self.btnRight addTarget:self action:@selector(onMakeSureAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.btnRight];
    self.btnRight.layer.cornerRadius = 2.0f;
    self.btnRight.layer.masksToBounds = YES;
    [self.btnRight mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(weakSelf.bgView.mas_right).offset(-13);
        make.width.mas_equalTo(60.0f);
        make.height.mas_equalTo(26.0f);
        make.centerY.equalTo(weakSelf.bgView.mas_centerY).offset(0);
    }];
    
    self.btnCenter = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.btnCenter setTintColor:[UIColor whiteColor]];
    [self.btnCenter setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.btnCenter.titleLabel.font = [UIFont systemFontOfSize:16.0f];
    [self.btnCenter addTarget:self action:@selector(onSelectOtherAlbumAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgView addSubview:self.btnCenter];
    [self.btnCenter mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.bgView.mas_top).offset(0);
        make.bottom.equalTo(weakSelf.bgView.mas_bottom).offset(0);
        make.centerX.equalTo(weakSelf.bgView);
    }];
    if (self.kj_phAssetArray.count > 0) {
        self.kj_albumModel = self.kj_phAssetArray.firstObject;
        [self showAlbumTItle:self.kj_albumModel.title];
    } else {
        [self showAlbumTItle:@"相簿没有相册"];
    }
}

- (void)showAlbumTItle:(NSString *)title {
    UIImage *image = [UIImage imageNamed:@"filter_more"];
    [self.btnCenter setTitle:title forState:UIControlStateNormal];
    [self.btnCenter setImage:image forState:UIControlStateNormal];
    
    CGFloat imgWidth = image.size.width+2;
    CGFloat labWidth = [title sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16.0]}].width+2;
    [self.btnCenter setImageEdgeInsets:UIEdgeInsetsMake(0, labWidth, 0, -labWidth)];
    [self.btnCenter setTitleEdgeInsets:UIEdgeInsetsMake(0, -imgWidth, 0, imgWidth)];
    [self.bgView layoutIfNeeded];
}

//播放器
- (void)customVideoPlayer {
    WS(weakSelf)
    self.kj_videoPlayer = [[KJShortVideoPlayer alloc] init];
    [self.view addSubview:self.kj_videoPlayer];
    [self.kj_videoPlayer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.bgView.mas_bottom).offset(0);
        make.height.mas_equalTo(SCREEN_WIDTH);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
    }];
    [self.kj_videoPlayer layoutIfNeeded];
}

//创建tableView
- (void)customAlbumListForTableView {
    WS(weakSelf)
    self.tab_bgView = [UIView new];
    self.tab_bgView.backgroundColor = [UIColor colorWithHex:1 alpha:0.4];
    [self.view addSubview:self.tab_bgView];
    [self.tab_bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.bgView.mas_bottom).offset(0);
        make.bottom.equalTo(weakSelf.view.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
    }];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor colorWithHex:0xeeeeee];
    [self.tab_bgView addSubview:self.tableView];
    CGFloat tab_height = weakSelf.kj_phAssetArray.count * 62.0f;
    if (tab_height > 373.0) {
        tab_height = 373.0;
    }
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.tab_bgView.mas_top).offset(-tab_height);
        make.left.equalTo(weakSelf.tab_bgView.mas_left).offset(0);
        make.right.equalTo(weakSelf.tab_bgView.mas_right).offset(0);
        make.height.mas_equalTo(tab_height);
    }];
    
    UIButton *btn_close = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn_close addTarget:self action:@selector(onCloseAlbumListAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.tab_bgView addSubview:btn_close];
    [btn_close mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.tableView.mas_bottom).offset(0);
        make.bottom.equalTo(weakSelf.tab_bgView.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.tab_bgView.mas_left).offset(0);
        make.right.equalTo(weakSelf.tab_bgView.mas_right).offset (0);
    }];
    
    self.tableView.clipsToBounds = YES;
    self.tab_bgView.clipsToBounds = YES;
    self.tab_bgView.hidden = YES;
    [KJAlbumListCell regisCellForTableView:self.tableView];
    [self.tableView reloadData];
}

//创建相册视频列表collectionView
- (void)customPhotoListForCollectionView {
    WS(weakSelf)
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc]init];
    layout.minimumInteritemSpacing = 3.0f;
    layout.minimumLineSpacing = 3.0f;
    layout.itemSize = CGSizeMake((SCREEN_WIDTH-3.0*2)/3.0, (SCREEN_WIDTH-3.0*2)/3.0);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor blackColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.kj_videoPlayer.mas_bottom).offset(10);
        make.bottom.equalTo(weakSelf.view.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
    }];
    [KJShortVideoAlbumCell regisCellForCollectionView:self.collectionView];
}

#pragma mark - 点击事件
//取消
- (void)onCancelAction:(id)sender {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}
//继续
- (void)onMakeSureAction:(id)sender {
    [self.kj_videoPlayer stopPlayer];
    KJVideoCaptureController *ctrl = [[KJVideoCaptureController alloc] init];
    ctrl.kj_maxTime = self.kj_maxTime;
    ctrl.kj_minTime = self.kj_minTime;
    NSIndexPath *index = [self.collectionView indexPathsForSelectedItems].firstObject;
    KJPHAsset *kj_asset = self.kj_albumModel.assets[index.row];
    ctrl.kj_videoObject = kj_asset.urlAsset;
    ctrl.kj_videoCapturedelegate = self;
    [self.navigationController pushViewController:ctrl animated:YES];
}

//选择相册
- (void)onSelectOtherAlbumAction:(id)sender {
    UIImage *image = [UIImage imageNamed:@"filter_more"];
    WS(weakSelf)
    if (self.tab_bgView.hidden) {
        [self.tableView reloadData];
        [self.btnCenter setImage:[image yy_imageByRotate180] forState:UIControlStateNormal];
        self.tab_bgView.hidden = NO;
        [self.view bringSubviewToFront:self.tableView];
        [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(weakSelf.tab_bgView.mas_top).offset(0);
        }];
        [UIView animateWithDuration:0.25 animations:^{
            [self.tab_bgView layoutIfNeeded];
        }];
        NSUInteger index = [self.kj_phAssetArray indexOfObject:self.kj_albumModel];
        if (index != NSNotFound) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    } else {
        [self.btnCenter setImage:image forState:UIControlStateNormal];
        CGFloat tab_height = self.kj_phAssetArray.count * 62.0f;
        if (tab_height > 373.0) {
            tab_height = 373.0;
        }
        [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(weakSelf.tab_bgView.mas_top).offset(-tab_height);
        }];
        [UIView animateWithDuration:0.25 animations:^{
            [self.tab_bgView layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.tab_bgView.hidden = YES;
        }];
    }
}

- (void)onCloseAlbumListAction:(id)sender {
    [self onSelectOtherAlbumAction:nil];
}

#pragma mark - KJVideoCaptureDelegate
- (void)kj_didCaptureCompleteForPath:(NSString *)outPath {
    if (self.kj_fileDelegate && [self.kj_fileDelegate respondsToSelector:@selector(kj_videoFileCompleteLocalPath:)]) {
        [self.kj_fileDelegate kj_videoFileCompleteLocalPath:outPath];
    }
}

#pragma mark - UICollectionViewDelegate/UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.kj_albumModel.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    KJShortVideoAlbumCell *cell = [KJShortVideoAlbumCell dequeueCellForCollectionView:collectionView withIndex:indexPath];
    KJPHAsset *kj_asset = self.kj_albumModel.assets[indexPath.row];
    if (kj_asset.localImage && kj_asset.urlAsset) {
        cell.imgView.image = kj_asset.localImage;
        CMTime   time = [kj_asset.urlAsset duration];
        int seconds = ceil(time.value/time.timescale);
        cell.labelTime.text = [NSString stringWithFormat:@"%.2d:%.2d",seconds/60,seconds];
    } else {
        [KJUtility kj_requestVideoForAsset:kj_asset.asset completion:^(AVURLAsset *asset) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage *image = [KJUtility kj_getScreenShotImageFromVideoPath:asset withStart:0.0 withTimescale:60];
                cell.imgView.image = image;
                CMTime   time = [asset duration];
                int seconds = ceil(time.value/time.timescale);
                cell.labelTime.text = [NSString stringWithFormat:@"%.1d:%.2d",seconds/60,seconds];
                kj_asset.urlAsset = asset;
                kj_asset.localImage = image;
            });
        }];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    KJPHAsset *kj_asset = self.kj_albumModel.assets[indexPath.row];
    if (self.kj_selected_asset && ![kj_asset.asset.localIdentifier isEqualToString:self.kj_selected_asset.asset.localIdentifier]) {
        [self handleSamePhoto:kj_asset];
        //默认自动播放
        [self playerForAsset:kj_asset];
    }
}

#pragma mark - UITableViewDelegate/UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.kj_phAssetArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 62.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.001f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.001f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KJAlbumListCell *cell = [KJAlbumListCell dequeueCellForTableView:tableView];
    KJAlbumModel *object = self.kj_phAssetArray[indexPath.row];
    cell.labelCount.text = [NSString stringWithFormat:@"%d",(int)object.count];
    cell.labelTitle.text = object.title;
    cell.imgSelected.hidden = !object.selected_count;
    KJPHAsset *kj_asset = object.assets.firstObject;
    if (kj_asset.localImage) {
        cell.imgView.image = kj_asset.localImage;
    } else {
        [KJUtility kj_requestImageForAsset:kj_asset.asset withSynchronous:NO completion:^(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.imgView.image = image;
                kj_asset.localImage = image;
            });
        }];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.kj_albumModel = self.kj_phAssetArray[indexPath.row];
    [self showAlbumTItle:self.kj_albumModel.title];
    [self.collectionView reloadData];
    [self onSelectOtherAlbumAction:nil];
    if (self.kj_selected_asset) {//处理相册切换时，选中的视频
        NSString *preStr = [NSString stringWithFormat:@"asset.localIdentifier == '%@'",self.kj_selected_asset.asset.localIdentifier];
        NSPredicate *pred = [NSPredicate predicateWithFormat:preStr];
        NSArray *preArr = [self.kj_albumModel.assets filteredArrayUsingPredicate:pred];
        if (preArr.count > 0) {
            KJPHAsset *kj_asset = preArr.firstObject;
            if (kj_asset) {
                [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:[self.kj_albumModel.assets indexOfObject:kj_asset] inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
            }
        }
    }
}

//播放视频
- (void)playerForAsset:(KJPHAsset *)kj_asset {
    if (kj_asset.urlAsset) {
        self.kj_videoPlayer.kj_urlAsset = kj_asset.urlAsset;
    } else {
        WS(weakSelf)
        [KJUtility kj_requestVideoForAsset:kj_asset.asset completion:^(AVURLAsset *asset) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.kj_videoPlayer.kj_urlAsset = asset;
            });
        }];
    }
}

#pragma mark - 获取相簿
- (void)getSystemVidelAlbum {
    WS(weakSelf)
    //获取所有智能相册
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL *stop) {
        NSArray<KJPHAsset *> *assets = [weakSelf getAssetsInAssetCollection:collection ascending:NO];
        //去掉最近删除
        if(collection.assetCollectionSubtype < 212){
            if (assets.count > 0) {
                KJAlbumModel *kj_albumObject = [KJAlbumModel new];
                kj_albumObject.title = collection.localizedTitle;
                kj_albumObject.assets = assets;
                kj_albumObject.assetCollection = collection;
                kj_albumObject.count = assets.count;
                [weakSelf.kj_phAssetArray addObject:kj_albumObject];
            }
        }
    }];
    
    //获取用户创建的相册
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<KJPHAsset *> *assets = [weakSelf getAssetsInAssetCollection:collection ascending:NO];
        if (assets.count > 0) {
            KJAlbumModel *kj_albumObject = [KJAlbumModel new];
            kj_albumObject.title = collection.localizedTitle;
            kj_albumObject.assets = assets;
            kj_albumObject.assetCollection =collection;
            kj_albumObject.count = assets.count;
            [weakSelf.kj_phAssetArray addObject:kj_albumObject];
        }
    }];
    
    if (self.kj_phAssetArray.count > 0) {
        self.kj_albumModel = self.kj_phAssetArray.firstObject;
        [self showAlbumTItle:self.kj_albumModel.title];
    } else {
        [self showAlbumTItle:@"相簿没有相册"];
    }
    
}

#pragma mark - 获取指定相册内的所有视频
- (NSMutableArray<KJPHAsset *>*)getAssetsInAssetCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending {
    NSMutableArray<KJPHAsset *> *arr = [NSMutableArray array];
    PHFetchResult *result = [self fetchAssetsInAssetCollection:assetCollection ascending:ascending];
    [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (((PHAsset *)obj).mediaType == PHAssetMediaTypeVideo) {
            KJPHAsset *kj_obj = [KJPHAsset new];
            kj_obj.asset = obj;
            [arr addObject:kj_obj];
        }
    }];
    return arr;
}

- (PHFetchResult *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending {
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:ascending]];
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:option];
    return result;
}


//选择完视频后，让所有有该资源的相册都标注上选择标识
- (void)handleSamePhoto:(KJPHAsset *)kj_phAsset {
    for (KJAlbumModel *kj_albumModel in self.kj_phAssetArray) {
        //当前选择的
        [self handleSamePhotoForKJModel:kj_albumModel withAsset:kj_phAsset withSelect:YES];
        if (self.kj_selected_asset) {
            //上次选择的
            [self handleSamePhotoForKJModel:kj_albumModel withAsset:self.kj_selected_asset withSelect:NO];
        }
    }
    
    self.kj_selected_asset = kj_phAsset;
}

- (void)handleSamePhotoForKJModel:(KJAlbumModel *)kj_objModel withAsset:(KJPHAsset *)kj_phAsset withSelect:(BOOL)isSelect {
    NSString *preStr = [NSString stringWithFormat:@"asset.localIdentifier == '%@'",kj_phAsset.asset.localIdentifier];
    NSPredicate *pred = [NSPredicate predicateWithFormat:preStr];
    NSArray *preArr = [kj_objModel.assets filteredArrayUsingPredicate:pred];
    if (preArr.count > 0) {
        for (KJPHAsset *kj_asset in preArr) {
            kj_asset.isSelected = isSelect;
            isSelect ? kj_objModel.selected_count++ : kj_objModel.selected_count--;
        }
    }
}


- (void)stopPlayer {
    [self.kj_videoPlayer stopPlayer];
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
