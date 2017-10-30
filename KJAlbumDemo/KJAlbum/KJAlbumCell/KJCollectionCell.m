//
//  KJCollectionCell.m
//  PhotoBrowse
//
//  Created by JOIN iOS on 2017/7/13.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import "KJCollectionCell.h"
#import <Masonry.h>

@interface KJCollectionCell ()

@property (strong, nonatomic) UIImageView *imageView;

@end

#define KJSCREEN_SIZE [UIScreen mainScreen].bounds

#define KJMAXZOOMSCALE 2.0f
#define KJMINZOOMSCALE 1.0f

@implementation KJCollectionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    //缩略设置
    self.scrollView.multipleTouchEnabled = YES;//打开多指触控
    self.scrollView.minimumZoomScale = 1.0f;
    self.scrollView.maximumZoomScale = KJMAXZOOMSCALE;
    self.scrollView.contentSize = CGSizeMake(KJSCREEN_SIZE.size.width, KJSCREEN_SIZE.size.height);
    
    self.imageView = [YYAnimatedImageView new];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
//    self.imageView.userInteractionEnabled = YES;
    [self.scrollView addSubview:self.imageView];
    [self.imageView setCenter:CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)];
    [self.imageView setSize:CGSizeMake(1, 1)];
    //单击手势
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    tapGesture.numberOfTapsRequired=1;
    [self.scrollView addGestureRecognizer:tapGesture];
    
    //双击手势
    UITapGestureRecognizer *doubelGesture=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleGesture:)];
    doubelGesture.numberOfTapsRequired=2;
    [self.scrollView addGestureRecognizer:doubelGesture];
    
    //没有检测到双击或者双击失败时 单击才有效
    [tapGesture requireGestureRecognizerToFail:doubelGesture];
    
    //长按手势
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
    [self.scrollView addGestureRecognizer:longPress];
}

+ (void)regisCellFor:(UICollectionView *)collectionView {
    [collectionView registerNib:[UINib nibWithNibName:@"KJCollectionCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"KJCollectionCell"];
}

+ (KJCollectionCell *)dequeueCellFor:(UICollectionView *)collectionView with:(NSIndexPath *)indexPath {
    return [collectionView dequeueReusableCellWithReuseIdentifier:@"KJCollectionCell" forIndexPath:indexPath];
}

//单击事件
- (void)tapGesture:(UIGestureRecognizer *)sender {
    if (self.tapBlock) {
        self.tapBlock();
    }
}

//双击事件
-(void)doubleGesture:(UIGestureRecognizer *)sender {
    //当前倍数等于最大放大倍数
    //双击默认为缩小到原图
    if (self.scrollView.zoomScale == KJMAXZOOMSCALE) {
        [self.scrollView setZoomScale:KJMINZOOMSCALE animated:YES];
        return;
    }
    //当前等于最小放大倍数
    //双击默认为放大到最大倍数
    if (self.scrollView.zoomScale == KJMINZOOMSCALE) {
        [self.scrollView setZoomScale:KJMAXZOOMSCALE animated:YES];
        return;
    }
    
    CGFloat aveScale = KJMINZOOMSCALE+(KJMAXZOOMSCALE-KJMINZOOMSCALE)/2.0;//中间倍数
    
    //当前倍数大于平均倍数
    //双击默认为放大最大倍数
    if (self.scrollView.zoomScale >= aveScale) {
        [self.scrollView setZoomScale:KJMAXZOOMSCALE animated:YES];
        return;
    }
    
    //当前倍数小于平均倍数
    //双击默认为放大到最小倍数
    if (self.scrollView.zoomScale<aveScale) {
        [self.scrollView setZoomScale:KJMINZOOMSCALE animated:YES];
        return;
    }
}

//长按手势
- (void)onLongPress:(UIGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (self.longBlock) {
            self.longBlock(self);
        }
    }
}

-(void)reloadFrame{
    CGRect frame = _imageView.frame;
    self.scrollView.contentSize = frame.size;
    if(_imageView.frame.size.width>=SCREEN_WIDTH){
        frame.origin.x = 0;
    }else{
        frame.origin.x = SCREEN_WIDTH/2-_imageView.frame.size.width/2;
    }
    
    if(_imageView.frame.size.height>=SCREEN_HEIGHT){
        frame.origin.y = 0;
    }else{
        frame.origin.y = SCREEN_HEIGHT/2 - _imageView.frame.size.height/2;
    }
    [UIView animateWithDuration:0.2 animations:^{
        _imageView.frame = frame;
    } completion:nil];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    [self reloadFrame];
    return self.imageView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view {
    
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale {
    [self reloadFrame];
}

- (void)setKj_image:(UIImage *)kj_image {
    self.imageView.image = kj_image;
    [self updateImgViewFrame:kj_image];
}


- (void)updateImgViewFrame:(UIImage *)image {
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    if (image.size.width > SCREEN_WIDTH) {
        height = height * (SCREEN_WIDTH/width);
        width = SCREEN_WIDTH;
    }
    if (height > SCREEN_HEIGHT) {
        width = width * (SCREEN_HEIGHT/height);
        height = SCREEN_HEIGHT;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.frame = CGRectMake((SCREEN_WIDTH-width)/2, (SCREEN_HEIGHT-height)/2, width, height);
        self.scrollView.contentSize = self.imageView.size;
    });
}

//- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
//
//    CGRect frame = self.imageView.frame;
//
//    frame.origin.y = (self.scrollView.frame.size.height - self.imageView.frame.size.height) > 0 ? (self.scrollView.frame.size.height - self.imageView.frame.size.height) * 0.5 : 0;
//    frame.origin.x = (self.scrollView.frame.size.width - self.imageView.frame.size.width) > 0 ? (self.scrollView.frame.size.width - self.imageView.frame.size.width) * 0.5 : 0;
//    self.imageView.frame = frame;
//    
//    self.scrollView.contentSize = CGSizeMake(self.imageView.frame.size.width + 30, self.imageView.frame.size.height + 30);
//}

@end
