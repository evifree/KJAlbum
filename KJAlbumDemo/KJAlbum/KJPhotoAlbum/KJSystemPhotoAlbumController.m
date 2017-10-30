//
//  KJSystemPhotoAlbumController.m
//  Join
//
//  Created by JOIN iOS on 2017/8/28.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import "KJSystemPhotoAlbumController.h"
#import <Masonry.h>
#import <Photos/Photos.h>
#import "KJAlbumModel.h"
#import "KJPHAsset.h"
#import "KJShortPhotoAlbumCell.h"
#import "KJAlbumListCell.h"
#import "KJAlbumBrowsController.h"

@interface KJSystemPhotoAlbumController ()<UITableViewDelegate,UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, KJShortPhotoAlbumCellDelegate, KJAlbumBrowsDelegate>
//显示相册内的图片
@property (strong, nonatomic) UICollectionView *collectionView;
//显示相册列表
@property (strong, nonatomic) UITableView *tableView;
//相册列变的背景view
@property (strong, nonatomic) UIView *tab_bgView;
//PHImageManager
@property (strong, nonatomic) PHImageManager *kj_DefaultManager;
//相册列表数据
@property (strong, nonatomic) NSMutableArray *kj_phAssetArray;
//选中的相册model
@property (strong, nonatomic) KJAlbumModel *kj_albumModel;
//导航栏
@property (strong, nonatomic)UIView *bgView;
@property (strong, nonatomic)UIButton *btnLeft;
@property (strong, nonatomic)UIButton *btnRight;
@property (strong, nonatomic)UIButton *btnCenter;

@property (strong, nonatomic) NSMutableArray *kj_selectImgs;


@end

@implementation KJSystemPhotoAlbumController

- (void)dealloc {
    self.kj_DefaultManager = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    self.kj_phAssetArray = [NSMutableArray arrayWithCapacity:0];
    self.kj_selectImgs = [NSMutableArray arrayWithArray:self.kj_selectArray];
    
    [self cunstomNavc];
    [self customPhotoListForCollectionView];
    //授权
    WS(weakSelf)
    [KJUtility kj_photoLibraryAuthorizationStatus:self completeBlock:^(BOOL allowAccess) {
        if (allowAccess) {
            [weakSelf getSystemPhotoAlbumList];
            [weakSelf.collectionView reloadData];
        }
    }];
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
    [self showSelectedCount];
    self.btnRight.titleLabel.font = [UIFont systemFontOfSize:13.0f];
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
    [self showAlbumTItle:@"相机胶卷"];
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

- (void)showSelectedCount {
    NSString *title = [NSString stringWithFormat:@"完成"];
    if (self.kj_selectImgs.count > 0) {
        title = [NSString stringWithFormat:@"完成(%d)",(int)self.kj_selectImgs.count];
    }
    [self.btnRight setTitle:title forState:UIControlStateNormal];
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

//创建相册图片列表collectionView
- (void)customPhotoListForCollectionView {
    WS(weakSelf)
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc]init];
    layout.minimumInteritemSpacing = 5.0f;
    layout.minimumLineSpacing = 5.0f;
    layout.itemSize = CGSizeMake((SCREEN_WIDTH-5.0*3)/4.0, (SCREEN_WIDTH-5.0*3)/4.0);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.bgView.mas_bottom).offset(0);
        make.bottom.equalTo(weakSelf.view.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
    }];
    [KJShortPhotoAlbumCell regisCellForCollectionView:self.collectionView];
}

#pragma mark - 导航栏上按钮的点击事件
//左按钮，取消
- (void)onCancelAction:(UIButton *)sender {
    if (self.kj_photoAlbumDelegate && [self.kj_photoAlbumDelegate respondsToSelector:@selector(kj_SystemPhotoAlbumCancel)]) {
        [self.kj_photoAlbumDelegate kj_SystemPhotoAlbumCancel];
    }
}

//右按钮，确定
- (void)onMakeSureAction:(UIButton *)sender {
    if (self.kj_photoAlbumDelegate && [self.kj_photoAlbumDelegate respondsToSelector:@selector(kj_SystemPhotoAlbumSelectedComplete:)]) {
        [self.kj_photoAlbumDelegate kj_SystemPhotoAlbumSelectedComplete:self.kj_selectImgs];
    }
}

//从相簿中选择其他的相册
- (void)onSelectOtherAlbumAction:(UIButton *)sender {
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

- (void)onCloseAlbumListAction:(UITapGestureRecognizer *)sender {
    [self onSelectOtherAlbumAction:nil];
}

#pragma mark - KJShortPhotoAlbumCellDelegate
- (void)didTapSelectedAction:(KJShortPhotoAlbumCell *)kj_cell {
    
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:kj_cell];
    KJPHAsset *kj_asset = self.kj_albumModel.assets[indexPath.row];
    BOOL isSelect = kj_asset.isSelected;
    if (!isSelect) {
        if (self.kj_selectImgs.count >= self.maxCount) {
            [KJUtility showAllTextDialog:self.view Text:[NSString stringWithFormat:@"最多只能选择%d张图片",self.maxCount]];
            return;
        }
    }
    [self handleSelected:kj_asset];
    [self handleSamePhoto:kj_asset withSelected:!isSelect];
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    
    NSString *title = [NSString stringWithFormat:@"完成"];
    if (self.kj_selectImgs.count > 0) {
        title = [NSString stringWithFormat:@"完成(%d)",(int)self.kj_selectImgs.count];
    }
    [self.btnRight setTitle:title forState:UIControlStateNormal];
}

#pragma mark - UICollectionViewDelegate/UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.kj_albumModel.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    KJShortPhotoAlbumCell *cell = [KJShortPhotoAlbumCell dequeueCellForCollectionView:collectionView withIndex:indexPath];
    KJPHAsset *kj_asset;
    if (collectionView == self.collectionView) {
        cell.delegate = self;
        kj_asset = self.kj_albumModel.assets[indexPath.row];
        cell.btnSelected.hidden = NO;
        cell.btnSelected.selected = kj_asset.isSelected;
    }
    if (kj_asset.localImage) {
        cell.imgView.image = kj_asset.localImage;
    } else {
        [KJUtility kj_requestImageForAsset:kj_asset.asset withSynchronous:NO completion:^(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                kj_asset.localImage = image;
                cell.imgView.image = image;
            });
        }];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.collectionView) {
        KJAlbumBrowsController *ctrl = [[KJAlbumBrowsController alloc] init];
        ctrl.kj_delegate = self;
        ctrl.maxCount = self.maxCount;
        ctrl.kj_albumModel = self.kj_albumModel;
        ctrl.kj_selectArray = self.kj_selectImgs;
        ctrl.showIndex = (int)indexPath.row;
        ctrl.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:ctrl animated:YES completion:nil];
    }
}

#pragma mark - KJAlbumBrowsDelegate
- (void)didSelectedKJPHAsset:(KJPHAsset *)kjAsset {
    BOOL isSelect = kjAsset.isSelected;
    [self handleSelected:kjAsset];
    [self handleSamePhoto:kjAsset withSelected:!isSelect];
}

- (void)didCancelAction {
    [self showSelectedCount];
    [self.collectionView reloadData];
}

- (void)didCompleteAction {
    [self showSelectedCount];
    [self onMakeSureAction:nil];
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
}

#pragma mark - 获取相簿
//获得所有相簿的相册列表
- (void)getSystemPhotoAlbumList {
    WS(weakSelf)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!weakSelf.kj_DefaultManager) {
            weakSelf.kj_DefaultManager = [PHImageManager defaultManager];
        }
        [weakSelf.kj_phAssetArray removeAllObjects];
        
        //获取所有智能相册
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL *stop) {
            //过滤掉视频和最近删除
            if(collection.assetCollectionSubtype != 202 && collection.assetCollectionSubtype < 212){
                NSArray<KJPHAsset *> *assets = [weakSelf getAssetsInAssetCollection:collection ascending:NO];
                if (assets.count > 0) {
                    KJAlbumModel *kj_albumObject = [KJAlbumModel new];
                    kj_albumObject.title = collection.localizedTitle;
                    kj_albumObject.assets = assets;
                    kj_albumObject.assetCollection = collection;
                    kj_albumObject.count = assets.count;
                    //处理上次选择的图片
                    if (weakSelf.kj_selectImgs.count > 0) {
                        for (KJPHAsset *kj_phAsset in weakSelf.kj_selectImgs) {
                            [weakSelf handleSamePhotoForKJModel:kj_albumObject withAsset:kj_phAsset withSelect:YES];
                        }
                    }
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
                //处理上次选择的图片
                if (self.kj_selectImgs.count > 0) {
                    for (KJPHAsset *kj_phAsset in weakSelf.kj_selectImgs) {
                        [weakSelf handleSamePhotoForKJModel:kj_albumObject withAsset:kj_phAsset withSelect:YES];
                    }
                }
                [weakSelf.kj_phAssetArray addObject:kj_albumObject];
            }
        }];
        for (int i = 0; i < weakSelf.kj_phAssetArray.count; i ++) {
            KJAlbumModel *albumModel = weakSelf.kj_phAssetArray[i];
            if ([albumModel.title isEqualToString:@"相机胶卷"]||[albumModel.title isEqualToString:@"所有照片"]) {
                [weakSelf.kj_phAssetArray removeObjectAtIndex:i];
                [weakSelf.kj_phAssetArray insertObject:albumModel atIndex:0];
                break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.kj_phAssetArray.count > 0) {
                weakSelf.kj_albumModel = self.kj_phAssetArray.firstObject;
                [weakSelf showAlbumTItle:self.kj_albumModel.title];
            } else {
                [weakSelf showAlbumTItle:@"相簿没有相册"];
            }
            [weakSelf customAlbumListForTableView];
            [weakSelf.collectionView reloadData];
        });
    });
}

#pragma mark - 获取指定相册内的所有图片
- (NSMutableArray<KJPHAsset *>*)getAssetsInAssetCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending {
    NSMutableArray<KJPHAsset *> *arr = [NSMutableArray array];
    PHFetchResult *result = [self fetchAssetsInAssetCollection:assetCollection ascending:ascending];
    [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (((PHAsset *)obj).mediaType == PHAssetMediaTypeImage) {
            KJPHAsset *kj_obj = [KJPHAsset new];
            kj_obj.asset = obj;
            [arr addObject:kj_obj];
        } else {
            NSLog(@"不属于图片-PHAssetMediaTypeImage");
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


#pragma mark - 处理各相册相同照片

- (void)handleSamePhoto:(KJPHAsset *)kj_phAsset withSelected:(BOOL)isSelect {
    for (KJAlbumModel *kj_albumModel in self.kj_phAssetArray) {
        [self handleSamePhotoForKJModel:kj_albumModel withAsset:kj_phAsset withSelect:isSelect];
    }
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

- (void)handleSelected:(KJPHAsset *)kjAsset {
    if (kjAsset.isSelected) {
        NSString *preStr = [NSString stringWithFormat:@"asset.localIdentifier == '%@'",kjAsset.asset.localIdentifier];
        NSPredicate *pred = [NSPredicate predicateWithFormat:preStr];
        NSArray *preArr = [self.kj_selectImgs filteredArrayUsingPredicate:pred];
        if (preArr.count) {
            for (KJPHAsset *kj_asset in preArr) {
                kj_asset.isSelected = NO;
                [self.kj_selectImgs removeObject:kj_asset];
            }
        }
    } else {
        [self.kj_selectImgs addObject:kjAsset];
    }
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
