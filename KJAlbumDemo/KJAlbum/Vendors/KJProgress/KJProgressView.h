//
//  KJProgressView.h
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/10/10.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KJProgressView : UIView

//必须设置  最大进度
@property (assign, nonatomic) CGFloat kj_maxProgress;
//当前进度
@property (assign, nonatomic) CGFloat kj_progress;
//进度条颜色
@property (nonatomic) UIColor *kj_bgColor;
//节点颜色
@property (nonatomic) UIColor *kj_nodeColor;
//节点段选中颜色
@property (nonatomic) UIColor *kj_selectColor;
//是否被选中
@property (assign, nonatomic, readonly) BOOL kj_isSelected;


///增加节点
- (UIView *)addNodeView;
///删除最后一个节点
- (void)removeLastNode;
///选中最后一个节点
- (void)selectLastNode;

@end
