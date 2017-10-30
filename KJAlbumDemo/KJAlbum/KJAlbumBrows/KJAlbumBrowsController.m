//
//  KJAlbumBrowsController.m
//  Join
//
//  Created by JOIN iOS on 2017/8/29.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import "KJAlbumBrowsController.h"
#import <Masonry.h>
#import "KJPHAsset.h"
#import "KJCollectionCell.h"
#import "KJShortPhotoAlbumCell.h"

@interface KJAlbumBrowsController ()<UICollectionViewDelegate, UICollectionViewDataSource>
//所有图片展示
@property (strong, nonatomic) UICollectionView *collectionView;

//topView
@property (strong, nonatomic) UIView *bgTopView;
@property (strong, nonatomic) UIButton *btnSure;
@property (strong, nonatomic) UIButton *btnBack;
@property (strong, nonatomic) UIButton *btnSelect;

@end


#define BGVIEWALPHA 0.6

@implementation KJAlbumBrowsController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customAllPhotoBrowForCollectionView];
    [self customTopView];
    [self.collectionView reloadData];
    if (self.showIndex > 0) {
        WS(weakSelf)
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1/*延迟执行时间*/ * NSEC_PER_SEC));
        dispatch_after(delayTime, dispatch_get_main_queue(), ^{
            [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.showIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
            KJPHAsset *kj_asset = self.kj_albumModel.assets[self.showIndex];
            self.btnSelect.selected = kj_asset.isSelected;
        });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}


//创建所有图片展示的collectionView
- (void)customAllPhotoBrowForCollectionView {
    WS(weakSelf)
    UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc]init];
    layout.minimumLineSpacing = 10.0f;
    layout.itemSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 10);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = [UIColor blackColor];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.view.mas_top).offset(0);
        make.bottom.equalTo(weakSelf.view.mas_bottom).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(10.0f);
    }];
    [KJCollectionCell regisCellFor:self.collectionView];
}

//topView
- (void)customTopView {
    WS(weakSelf)
    self.bgTopView = [UIView new];
    self.bgTopView.backgroundColor = [UIColor colorWithWhite:0 alpha:BGVIEWALPHA];
    [self.view addSubview:self.bgTopView];
    [self.bgTopView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.view.mas_top).offset(0);
        make.left.equalTo(weakSelf.view.mas_left).offset(0);
        make.right.equalTo(weakSelf.view.mas_right).offset(0);
        make.height.mas_equalTo(64.0);
    }];
    
    self.btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnBack setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [self.btnBack addTarget:self action:@selector(onBackButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgTopView addSubview:self.btnBack];
    [self.btnBack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(weakSelf.bgTopView.mas_left).offset(0);
        make.centerY.equalTo(weakSelf.bgTopView.mas_centerY).offset(0);
        make.size.mas_equalTo(CGSizeMake(44.0, 40.f));
    }];
    
    self.btnSure = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnSure setTitleColor:[UIColor colorWithHex:0x000000] forState:UIControlStateNormal];
    NSString *title = [NSString stringWithFormat:@"完成(%d)",(int)self.kj_selectArray.count];
    if (self.kj_selectArray.count == 0) {
        title = @"完成";
    }
    self.btnSure.titleLabel.font = [UIFont systemFontOfSize:13.0f];
    [self.btnSure setTitle:title forState:UIControlStateNormal];
    [self.btnSure setBackgroundColor:[UIColor colorWithHex:sYellowColor]];
    self.btnSure.layer.cornerRadius = 2.0;
    self.btnSure.layer.masksToBounds = YES;
    [self.btnSure addTarget:self action:@selector(onCompleteButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bgTopView addSubview:self.btnSure];
    [self.btnSure mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(weakSelf.bgTopView.mas_right).offset(-13.0f);
        make.centerY.equalTo(weakSelf.bgTopView.mas_centerY).offset(0.0f);
        make.size.mas_equalTo(CGSizeMake(60.0f, 26.f));
    }];
    
    self.btnSelect = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnSelect setImage:[UIImage imageNamed:@"kj_album_brows_normal"] forState:UIControlStateNormal];
    [self.btnSelect setImage:[UIImage imageNamed:@"kj_album_brows_selected"] forState:UIControlStateSelected];
    [self.btnSelect addTarget:self action:@selector(onSelectedButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.btnSelect];
    [self.btnSelect mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf.bgTopView.mas_bottom).offset(17.0f);
        make.right.equalTo(weakSelf.bgTopView.mas_right).offset(-27.0f);
    }];
}

#pragma mark - 按钮点击事件
- (void)onCompleteButtonAction:(UIButton *)sender {
    if (self.kj_delegate && [self.kj_delegate respondsToSelector:@selector(didCompleteAction)]) {
        [self.kj_delegate didCompleteAction];
    }
}

- (void)onBackButtonAction:(UIButton *)sender {
    if (self.kj_delegate && [self.kj_delegate respondsToSelector:@selector(didCancelAction)]) {
        [self.kj_delegate didCancelAction];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onSelectedButtonAction:(UIButton *)sender {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x, 0)];
    KJPHAsset *kj_asset = self.kj_albumModel.assets[indexPath.row];
    if (!kj_asset.isSelected && self.kj_selectArray.count >= self.maxCount) {
        [KJUtility showAllTextDialog:self.view Text:[NSString stringWithFormat:@"最多只能选择%d张图片",self.maxCount]];
        return;
    }
    self.btnSelect.selected = !kj_asset.isSelected;
    if (self.kj_delegate && [self.kj_delegate respondsToSelector:@selector(didSelectedKJPHAsset:)]) {
        [self.kj_delegate didSelectedKJPHAsset:kj_asset];
    }
    NSString *title = [NSString stringWithFormat:@"完成(%d)",(int)self.kj_selectArray.count];
    if (self.kj_selectArray.count == 0) {
        title = @"完成";
    }
    [self.btnSure setTitle:title forState:UIControlStateNormal];
}


#pragma mark - UICollectionViewDelegate/UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.kj_albumModel.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    KJCollectionCell *cell = [KJCollectionCell dequeueCellFor:collectionView with:indexPath];
    KJPHAsset *kj_asset = self.kj_albumModel.assets[indexPath.row];
    if (kj_asset.localImage) {
        cell.kj_image = kj_asset.localImage;
    } else {
        [KJUtility kj_requestImageForAsset:kj_asset.asset withSynchronous:NO completion:^(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                kj_asset.localImage = image;
                cell.kj_image = image;
            });
        }];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:CGPointMake(scrollView.contentOffset.x, 0)];
//    KJPHAsset *kj_asset = self.kj_albumModel.assets[indexPath.row];
//    self.btnSelect.selected = kj_asset.isSelected;
//}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSArray *visibleCellIndex = [self.collectionView indexPathsForVisibleItems];
    if (visibleCellIndex.count > 0) {
        NSArray *sortedIndexPaths = [visibleCellIndex sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 compare:obj2];
        }];
        NSIndexPath *indexPath = sortedIndexPaths.firstObject;
        if (indexPath.row >= 0 && indexPath.row < self.kj_albumModel.assets.count) {
            KJPHAsset *kj_asset = self.kj_albumModel.assets[indexPath.row];
            self.btnSelect.selected = kj_asset.isSelected;
        }
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
