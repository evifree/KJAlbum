//
//  SGSegmentedControlStatic.m
//  SGSegmentedControlExample
//
//  Created by apple on 16/11/9.
//  Copyright © 2016年 Sorgle. All rights reserved.
//
//  - - - - - - - - - - - - - - 交流QQ：1357127436 - - - - - - - - - - - - - - //
//
//  - - 如在使用中, 遇到什么问题或者有更好建议者, 请于 kingsic@126.com 邮箱联系 - - - //
//  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//  - - GitHub下载地址 https://github.com/kingsic/SGSegmentedControl.git - - - //
//
//  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //

#import "SGSegmentedControlStatic.h"
#import "UIView+SGExtension.h"
#import "SGImageButton.h"
#import "UIImage+XLExtension.h"
#import "KJUtility.h"
#define indicatorViewColorDefualt [UIColor colorWithHex:0xFFD700]

@interface SGSegmentedControlStatic ()
/** 标题按钮 */
@property (nonatomic, strong) UIButton *title_btn;
/** 带有图片的标题按钮 */
@property (nonatomic, strong) SGImageButton *image_title_btn;
/** 存入所有标题按钮 */
@property (nonatomic, strong) NSMutableArray *storageAlltitleBtn_mArr;
/** 标题数组 */
@property (nonatomic, strong) NSArray *title_Arr;
/** 普通状态下的图片数组 */
@property (nonatomic, strong) NSArray *nomal_image_Arr;
/** 选中状态下的图片数组 */
@property (nonatomic, strong) NSArray *selected_image_Arr;
/** 临时button用来转换button的点击状态 */
@property (nonatomic, strong) UIButton *temp_btn;

//这是商家详情页的必看按钮
@property (nonatomic, strong) UILabel * showView;


@end

@implementation SGSegmentedControlStatic

/** 按钮字体的大小(字号) */
//static CGFloat const btn_fondOfSize = 15;
/** 指示器的高度 */
static CGFloat const indicatorViewHeight = 2;
/** 点击按钮时, 指示器的动画移动时间 */
static CGFloat const indicatorViewTimeOfAnimation = 0.15;

- (NSMutableArray *)storageAlltitleBtn_mArr {
    if (!_storageAlltitleBtn_mArr) {
        _storageAlltitleBtn_mArr = [NSMutableArray array];
    }
    return _storageAlltitleBtn_mArr;
}

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<SGSegmentedControlStaticDelegate>)delegate childVcTitle:(NSArray *)childVcTitle homeStyle:(NSString *)homeStyle{
    
    if (self = [super initWithFrame:frame]) {

        self.showsHorizontalScrollIndicator = NO;
        self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
        
        self.delegate_SG = delegate;
        
        self.title_Arr = childVcTitle;
        self.homeStyle=homeStyle;
        
        [self setupSubviews];
    }
    return self;
}

+ (instancetype)segmentedControlWithFrame:(CGRect)frame delegate:(id<SGSegmentedControlStaticDelegate>)delegate childVcTitle:(NSArray *)childVcTitle homeStyle:(NSString *)homeStyle{
    
       return [[self alloc] initWithFrame:frame delegate:delegate childVcTitle:childVcTitle homeStyle:homeStyle];
}

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<SGSegmentedControlStaticDelegate>)delegate nomalImageArr:(NSArray *)nomalImageArr selectedImageArr:(NSArray *)selectedImageArr childVcTitle:(NSArray *)childVcTitle homeStyle:(NSString *)homeStyle{
    
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
        self.showsHorizontalScrollIndicator = NO;
        self.bounces = NO;
        self.delegate_SG = delegate;
        self.nomal_image_Arr = nomalImageArr;
        self.selected_image_Arr = selectedImageArr;
        self.title_Arr = childVcTitle;
        self.homeStyle=homeStyle;
        [self setupSubviewsWithImage];
    }
    return self;
}

+ (instancetype)segmentedControlWithFrame:(CGRect)frame delegate:(id<SGSegmentedControlStaticDelegate>)delegate nomalImageArr:(NSArray *)nomalImageArr selectedImageArr:(NSArray *)selectedImageArr childVcTitle:(NSArray *)childVcTitle homeStyle:(NSString *)homeStyle{
    
    return [[self alloc] initWithFrame:frame delegate:delegate nomalImageArr:nomalImageArr selectedImageArr:selectedImageArr childVcTitle:childVcTitle homeStyle:homeStyle];
}

- (void)setupSubviews {
    // 计算    的宽度
    CGFloat scrollViewWidth = self.frame.size.width;
    CGFloat button_X = 0;
    CGFloat button_Y = 0;
    CGFloat button_W = scrollViewWidth / _title_Arr.count;
    CGFloat button_H = self.frame.size.height;
    
//    CGSize midSize=[JOINUtility LabelText:@"附近好玩" fontSize:12 widthSize:2000 heightSize:2000];
//    CGSize oneSize=[JOINUtility LabelText:@"热门推荐" fontSize:15 widthSize:2000 heightSize:2000];
//    CGSize twoSize=[JOINUtility LabelText:@"动态" fontSize:15 widthSize:2000 heightSize:2000];
//    CGSize threeSize=[JOINUtility LabelText:@"玩乐攻略" fontSize:15 widthSize:2000 heightSize:2000];
//    CGSize fourSize=[JOINUtility LabelText:@"组局玩" fontSize:15 widthSize:2000 heightSize:2000];
//    CGFloat labelSizeWidth=oneSize.width+twoSize.width+threeSize.width+fourSize.width;
//    CGFloat leftAndRightF=(SCREEN_WIDTH/4-midSize.width)/2;
//    
//    CGFloat midF=(SCREEN_WIDTH-labelSizeWidth-leftAndRightF*2)/3;
    
    for (NSInteger i = 0; i < _title_Arr.count; i++) {
        // 创建静止时的标题button
        self.title_btn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        if (self.btn_fondOfSize == 0) {
            self.btn_fondOfSize = 15;
        }
        _title_btn.titleLabel.font = [UIFont systemFontOfSize:self.btn_fondOfSize];
        _title_btn.tag = i;
        
        // 计算title_btn的x值
        button_X = i * button_W;
     

         _title_btn.frame = CGRectMake(button_X, button_Y, button_W, button_H);
        
        
        [_title_btn setTitle:_title_Arr[i] forState:(UIControlStateNormal)];
        [_title_btn setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
        [_title_btn setTitleColor:[UIColor redColor] forState:(UIControlStateSelected)];
        _title_btn.titleLabel.textAlignment=NSTextAlignmentCenter;
   
        
       
        // 点击事件
        [_title_btn addTarget:self action:@selector(buttonAction:) forControlEvents:(UIControlEventTouchUpInside)];
        
        // 默认选中第0个button
        if (i == 0) {
            [self buttonAction:_title_btn];
        }
        
        
        
        // 存入所有的title_btn
        [self.storageAlltitleBtn_mArr addObject:_title_btn];
        [self addSubview:_title_btn];
    }
    
    
    // 取出第一个子控件
    UIButton *firstButton = self.subviews.firstObject;
    
    // 添加指示器
    self.indicatorView = [[UIView alloc] init];
    _indicatorView.backgroundColor = indicatorViewColorDefualt;
    _indicatorView.SG_height = indicatorViewHeight;
    _indicatorView.SG_y = self.frame.size.height - 2 * indicatorViewHeight+2;
    [self addSubview:_indicatorView];
    
    // 指示器默认在第一个选中位置
    // 计算Titlebutton内容的Size
//    CGSize buttonSize = [self sizeWithText:firstButton.titleLabel.text font:[UIFont systemFontOfSize:self.btn_fondOfSize] maxSize:CGSizeMake(MAXFLOAT, self.frame.size.height)];
    _indicatorView.SG_width = [UIScreen mainScreen].bounds.size.width/_title_Arr.count;
    _indicatorView.SG_x = firstButton.SG_x;
    
    if ([self.homeStyle isEqualToString:@"DYNAMIC_STYLE"]) {
        _indicatorView.SG_width = 51;
        _indicatorView.SG_x =firstButton.SG_x +(246/3-51)/2;
    }else if([self.homeStyle isEqualToString:@"CAMARE_STYLE"])
    {
        
    }else
    {
        
        self.numView=[[UIView alloc]initWithFrame:CGRectMake(0, button_H-0.5, SCREEN_WIDTH, 0.5)];
        self.numView.backgroundColor=[UIColor colorWithHex:0xe1e1e1];
        [self addSubview:self.numView];
    }
    
   
}

/**
 *  计算文字尺寸
 *
 *  @param text    需要计算尺寸的文字
 *  @param font    文字的字体
 *  @param maxSize 文字的最大尺寸
 */
- (CGSize)sizeWithText:(NSString *)text font:(UIFont *)font maxSize:(CGSize)maxSize {
    NSDictionary *attrs = @{NSFontAttributeName : font};
    return [text boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
}

- (void)setupSubviewsWithImage {
    
    // 计算scrollView的宽度
    CGFloat scrollViewWidth = self.frame.size.width;
    CGFloat button_X = 0;
    CGFloat button_Y = 0;
    CGFloat button_W = scrollViewWidth / _title_Arr.count;
    CGFloat button_H = self.frame.size.height;
    
    for (NSInteger i = 0; i < _title_Arr.count; i++) {
        // 创建静止时的标题button
        self.image_title_btn = [[SGImageButton alloc] init];
        if (self.btn_fondOfSize == 0) {
            self.btn_fondOfSize = 15.0f;
        }
        _image_title_btn.titleLabel.font = [UIFont systemFontOfSize:self.btn_fondOfSize];
        _image_title_btn.tag = i;
        
        // 计算title_btn的x值
        button_X = i * button_W;
        _image_title_btn.frame = CGRectMake(button_X, button_Y, button_W, button_H);
        [_image_title_btn setTitle:_title_Arr[i] forState:(UIControlStateNormal)];
        [_image_title_btn setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
        [_image_title_btn setTitleColor:[UIColor redColor] forState:(UIControlStateSelected)];
        [_image_title_btn setImage:[UIImage imageNamed:_nomal_image_Arr[i]] forState:(UIControlStateNormal)];
        [_image_title_btn setImage:[UIImage imageNamed:_selected_image_Arr[i]] forState:(UIControlStateSelected)];
        // 点击事件
        [_image_title_btn addTarget:self action:@selector(buttonAction:) forControlEvents:(UIControlEventTouchUpInside)];
        
        // 默认选中第0个button
        if (i == 0) {
            [self buttonAction:_image_title_btn];
        }
        if ([self.homeStyle isEqualToString:@"DETAILS_STYLE"]==YES) {
            if (i == 0) {
                [_image_title_btn.imageView setTintColor:indicatorViewColorDefualt];
            }else
            {
                [_image_title_btn.imageView setTintColor:[UIColor colorWithHex:0x111111]];
            }
            
            if (i==1) {
                self.showView = [[UILabel alloc] initWithFrame:CGRectMake(_image_title_btn.frame.size.width/2+4, 4, 27, 13)];
                self.showView.backgroundColor = [UIColor colorWithHex:0xFF5C61];
                self.showView.font = [UIFont systemFontOfSize:10];
                self.showView.textColor = [UIColor whiteColor];
                self.showView.text = @"必看";
                self.showView.textAlignment = NSTextAlignmentCenter;
                self.showView.layer.cornerRadius = 2;
                self.showView.layer.masksToBounds = YES;
                [_image_title_btn addSubview:self.showView];
            }
        }
        // 存入所有的title_btn
        [self.storageAlltitleBtn_mArr addObject:_image_title_btn];
        [self addSubview:_image_title_btn];
    }
    
    // 取出第一个子控件
    UIButton *firstButton = self.subviews.firstObject;
    
    // 添加指示器
    self.indicatorView = [[UIView alloc] init];
    _indicatorView.backgroundColor = indicatorViewColorDefualt;
    _indicatorView.SG_height = indicatorViewHeight;
    _indicatorView.SG_y = self.frame.size.height - 2 * indicatorViewHeight+2;
    [self addSubview:_indicatorView];
    
    // 指示器默认在第一个选中位置
    // 计算Titlebutton内容的Size
//    CGSize buttonSize = [self sizeWithText:firstButton.titleLabel.text font:[UIFont systemFontOfSize:self.btn_fondOfSize] maxSize:CGSizeMake(MAXFLOAT, self.frame.size.height)];
    _indicatorView.SG_width = [UIScreen mainScreen].bounds.size.width/_title_Arr.count;
    _indicatorView.SG_x = firstButton.SG_x;
    
    _indicatorView.SG_width = [UIScreen mainScreen].bounds.size.width/_title_Arr.count;
    _indicatorView.SG_x = firstButton.SG_x;
    self.numView=[[UIView alloc]initWithFrame:CGRectMake(0, button_H-0.5, SCREEN_WIDTH, 0.5)];
    self.numView.backgroundColor=[UIColor colorWithHex:0xe1e1e1];
    [self addSubview:self.numView];
}

#pragma mark - - - 按钮的点击事件
- (void)buttonAction:(UIButton *)sender {
    // 1、代理方法实现
    NSInteger index = sender.tag;
    if ([self.delegate_SG respondsToSelector:@selector(SGSegmentedControlStatic:didSelectTitleAtIndex:)]) {
        [self.delegate_SG SGSegmentedControlStatic:self didSelectTitleAtIndex:index];
    }
    
    // 2、改变选中的button的位置
    [self selectedBtnLocation:sender];
}


/** 标题选中颜色改变以及指示器位置变化 */
- (void)selectedBtnLocation:(UIButton *)button {
    
    // 1、选中的button
    if (_temp_btn == nil) {
        button.selected = YES;
        _temp_btn = button;
    }else if (_temp_btn != nil && _temp_btn == button){
        button.selected = YES;
    }else if (_temp_btn != button && _temp_btn != nil){
        _temp_btn.selected = NO;
        button.selected = YES;
        if ([self.homeStyle isEqualToString:@"DETAILS_STYLE"]==YES) {
            if (button.tag == 1) {
                self.showView.backgroundColor = indicatorViewColorDefualt;
            }else
            {
                self.showView.backgroundColor = [UIColor colorWithHex:0xFF5C61];
            }
            [_temp_btn.imageView setTintColor:[UIColor colorWithHex:0x111111]];
            [button.imageView setTintColor:indicatorViewColorDefualt];
            
        }
       _temp_btn = button;
    }
    if (self.btn_fondOfSize == 0) {
        self.btn_fondOfSize = 15.0f;
    }
    
    // 2、改变指示器的位置
    // 改变指示器位置
    if ([self.homeStyle isEqualToString:@"HOME_STYLE"]==YES) {
        [UIView animateWithDuration:indicatorViewTimeOfAnimation animations:^{
            // 计算内容的Size
            CGSize buttonSize = [self sizeWithText:button.titleLabel.text font:[UIFont systemFontOfSize:self.btn_fondOfSize] maxSize:CGSizeMake(MAXFLOAT, self.frame.size.height - indicatorViewHeight)];
            self.indicatorView.SG_width = buttonSize.width+20;
            self.indicatorView.SG_x = button.SG_centerX-buttonSize.width/2-10;
        }];

    }else if ([self.homeStyle isEqualToString:@"DYNAMIC_STYLE"]==YES) {
        [UIView animateWithDuration:indicatorViewTimeOfAnimation animations:^{
            // 计算内容的Size
            //            CGSize buttonSize = [self sizeWithText:button.titleLabel.text font:[UIFont systemFontOfSize:self.btn_fondOfSize] maxSize:CGSizeMake(MAXFLOAT, self.frame.size.height - indicatorViewHeight)];
            self.indicatorView.SG_width = 51;
            self.indicatorView.SG_x = button.SG_x+(246/3-51)/2;
        }];
    }else
    {
        [UIView animateWithDuration:indicatorViewTimeOfAnimation animations:^{
            // 计算内容的Size
            //            CGSize buttonSize = [self sizeWithText:button.titleLabel.text font:[UIFont systemFontOfSize:self.btn_fondOfSize] maxSize:CGSizeMake(MAXFLOAT, self.frame.size.height - indicatorViewHeight)];
            self.indicatorView.SG_width =  [UIScreen mainScreen].bounds.size.width/_title_Arr.count;
            self.indicatorView.SG_x = button.SG_x;
        }];

    }
}

/** 改变选中button的位置以及指示器位置变化（给外界scrollView提供的方法 -> 必须实现） */
- (void)changeThePositionOfTheSelectedBtnWithScrollView:(UIScrollView *)scrollView scrollViewBool:(BOOL)scrollViewBool indexRow:(NSInteger)indexRow{
    if (scrollViewBool) {
        // 1、选中的button
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(indicatorViewTimeOfAnimation * 0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 2、把对应的标题选中
            UIButton *selectedBtn = self.storageAlltitleBtn_mArr[indexRow];
            if (_temp_btn == nil) {
                selectedBtn.selected = YES;
                _temp_btn = selectedBtn;
            }else if (_temp_btn != nil && _temp_btn == selectedBtn){
                selectedBtn.selected = YES;
            }else if (_temp_btn != selectedBtn && _temp_btn != nil){
                _temp_btn.selected = NO;
                selectedBtn.selected = YES; _temp_btn = selectedBtn;
            }
        });

    }else
    {
        // 1、计算滚动到哪一页
        NSInteger index = scrollView.contentOffset.x / scrollView.frame.size.width;
        
        // 2、把对应的标题选中
        UIButton *selectedBtn = self.storageAlltitleBtn_mArr[index];
        
        // 3、滚动时，改变标题选中
        [self selectedBtnLocation:selectedBtn];

      
    }
}
/** 文字渐显、缩放效果的实现（给外界 scrollViewDidScroll 提供的方法 -> 可供选择） */
- (void)selectedTitleBtnColorGradualChangeScrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat curPage = scrollView.contentOffset.x / scrollView.bounds.size.width;
    
    // 左边button角标
    NSInteger leftIndex = curPage;
    // 右边的button角标
    NSInteger rightIndex = leftIndex + 1;
    
    // 获取左边的button
    UIButton *left_btn = self.storageAlltitleBtn_mArr[leftIndex];
    UIImage * leftImage = [UIImage imageNamed:_nomal_image_Arr[leftIndex]];
    // 获取右边的button
    UIButton *right_btn;
    UIImage * rightImage;
    if (rightIndex < self.storageAlltitleBtn_mArr.count) {
        right_btn = self.storageAlltitleBtn_mArr[rightIndex];
        rightImage= [UIImage imageNamed:_selected_image_Arr[rightIndex]];
    }
    
    // 计算下右边缩放比例
    CGFloat rightScale = curPage - leftIndex;
    // 计算下左边缩放比例
    CGFloat leftScale = 1 - rightScale;
    CGFloat normalRed, normalGreen, normalBlue;
    CGFloat selectedRed, selectedGreen, selectedBlue;
    
    [self.titleColorStateNormal getRed:&normalRed green:&normalGreen blue:&normalBlue alpha:nil];
    [self.titleColorStateSelected getRed:&selectedRed green:&selectedGreen blue:&selectedBlue alpha:nil];
    // 获取选中和未选中状态的颜色差值
    CGFloat redDiff = selectedRed - normalRed;
    CGFloat greenDiff = selectedGreen - normalGreen;
    CGFloat blueDiff = selectedBlue - normalBlue;
    
    
//    // 根据颜色值的差值和偏移量，设置tabItem的标题颜色
    left_btn.titleLabel.textColor = [UIColor colorWithRed:leftScale * redDiff + normalRed
                                                    green:leftScale * greenDiff + normalGreen
                                                     blue:leftScale * blueDiff + normalBlue
                                                    alpha:1];
    right_btn.titleLabel.textColor = [UIColor colorWithRed:rightScale * redDiff + normalRed
                                                     green:rightScale * greenDiff + normalGreen
                                                      blue:rightScale * blueDiff + normalBlue
                                                     alpha:1];
    
    [left_btn.imageView setTintColor:[UIColor colorWithRed:leftScale * redDiff + normalRed
                                                     green:leftScale * greenDiff + normalGreen
                                                      blue:leftScale * blueDiff + normalBlue
                                                      alpha:1]];
    
    [right_btn.imageView setTintColor:[UIColor colorWithRed:rightScale * redDiff + normalRed
                                                     green:rightScale * greenDiff + normalGreen
                                                      blue:rightScale * blueDiff + normalBlue
                                                      alpha:1]];
    if ([self.homeStyle isEqualToString:@"DETAILS_STYLE"]==YES) {
        // 计算下右边缩放比例
        CGFloat rightShowScale = curPage - leftIndex;
        
        // 计算下左边缩放比例
        CGFloat leftShowScale = 1 - rightShowScale;
        CGFloat normalShowRed, normalShowGreen, normalShowBlue;
        CGFloat selectedShowRed, selectedShowGreen, selectedShowBlue;
        
        [[UIColor colorWithHex:0xFF5C61] getRed:&normalShowRed green:&normalShowGreen blue:&normalShowBlue alpha:nil];
        [indicatorViewColorDefualt getRed:&selectedShowRed green:&selectedShowGreen blue:&selectedShowBlue alpha:nil];
        // 获取选中和未选中状态的颜色差值
        CGFloat redShowDiff = selectedShowRed - normalShowRed;
        CGFloat greenShowDiff = selectedGreen - normalShowGreen;
        CGFloat blueShowDiff = selectedBlue - normalShowBlue;
        if (leftIndex==0) {
            self.showView.backgroundColor = [UIColor colorWithRed:rightShowScale * redShowDiff + normalShowRed
                                                            green:rightShowScale * greenShowDiff + normalShowGreen
                                                             blue:rightShowScale * blueShowDiff + normalShowBlue
                                                            alpha:1];
            
        }else if (leftIndex == 1)
        {
            self.showView.backgroundColor = [UIColor colorWithRed:leftShowScale * redShowDiff + normalShowRed
                                                            green:leftShowScale * greenShowDiff + normalShowGreen
                                                             blue:leftShowScale * blueShowDiff + normalShowBlue
                                                            alpha:1];
        }

        
    }

}


#pragma mark - - - setter 方法设置属性
- (void)setTitleColorStateNormal:(UIColor *)titleColorStateNormal {
    _titleColorStateNormal = titleColorStateNormal;
    for (UIView *subViews in self.storageAlltitleBtn_mArr) {
        UIButton *button = (UIButton *)subViews;
        [button setTitleColor:titleColorStateNormal forState:(UIControlStateNormal)];
    }
}

- (void)setTitleColorStateSelected:(UIColor *)titleColorStateSelected {
    _titleColorStateSelected = titleColorStateSelected;
    for (UIView *subViews in self.storageAlltitleBtn_mArr) {
        UIButton *button = (UIButton *)subViews;
        [button setTitleColor:titleColorStateSelected forState:(UIControlStateSelected)];
    }
}

- (void)setBtn_fondOfSize:(CGFloat)btn_fondOfSize {
    _btn_fondOfSize = btn_fondOfSize;
    for (UIButton *btn in self.storageAlltitleBtn_mArr) {
        btn.titleLabel.font = [UIFont systemFontOfSize:btn_fondOfSize];
    }
}

- (void)setIndicatorColor:(UIColor *)indicatorColor {
    _indicatorColor = indicatorColor;
    _indicatorView.backgroundColor = indicatorColor;
}


- (void)setShowsBottomScrollIndicator:(BOOL)showsBottomScrollIndicator {
    if (self.showsBottomScrollIndicator == YES) {
        
    } else {
        [self.indicatorView removeFromSuperview];
    }
}



@end


