//
//  KJProgressView.m
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/10/10.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import "KJProgressView.h"

@interface KJProgressView ()

@property (strong, nonatomic) NSMutableArray *dataArray;

@end

@implementation KJProgressView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setKj_progress:(CGFloat)kj_progress {
    _kj_progress = kj_progress;
    if (self.kj_isSelected) {
        [self cancelSelectedLastNode];
    }
    if (!self.dataArray) {
        self.dataArray = [NSMutableArray arrayWithCapacity:0];
        [self addNodeView];
    }
    
    if (self.dataArray.count > 0) {
        UIView *view = self.dataArray.lastObject;
        CGRect rect = view.frame;
        CGFloat length = (self.frame.size.width/self.kj_maxProgress)*kj_progress;
        rect.size.width = length - rect.origin.x;
        view.frame = rect;
        [self layoutIfNeeded];
    }
}

///增加节点
- (UIView *)addNodeView {
    if (!self.dataArray) {
        self.dataArray = [NSMutableArray arrayWithCapacity:0];
    }
    CGFloat x = 0;
    CGFloat y = 0;
    if (_dataArray.count > 0) {
        UIView *tmpView = self.dataArray.lastObject;
        if (tmpView) {
            x = tmpView.frame.origin.x+tmpView.frame.size.width;
        }
    }
    
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(x, y, 0, self.frame.size.height)];
    bgView.backgroundColor = self.kj_bgColor ? self.kj_bgColor : [UIColor orangeColor];
    bgView.clipsToBounds = YES;
    if (self.dataArray && self.dataArray.count > 0) {
        UIView *nodeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, self.frame.size.height)];
        nodeView.backgroundColor =self.kj_nodeColor ? self.kj_nodeColor : [UIColor whiteColor];
        nodeView.clipsToBounds = YES;
        [bgView addSubview:nodeView];
    }
    
    [self addSubview:bgView];
    [self.dataArray addObject:bgView];
    return bgView;
}

///删除最后一个节点
- (void)removeLastNode {
    if (self.dataArray.count > 0) {
        UIView *view = self.dataArray.lastObject;
        [view removeFromSuperview];
        [self.dataArray removeLastObject];
        [self layoutIfNeeded];
    }
}

///选中最后一个节点
- (void)selectLastNode {
    if (self.dataArray.count > 0) {
        UIView *view = self.dataArray.lastObject;
        view.backgroundColor = self.kj_selectColor ? self.kj_selectColor : [UIColor redColor];
    }
}

///取消选中
- (void)cancelSelectedLastNode {
    //恢复到默认颜色即可
    if (self.dataArray.count > 0) {
        UIView *view = self.dataArray.lastObject;
        view.backgroundColor = self.kj_bgColor ? self.kj_bgColor : [UIColor orangeColor];
    }
}

///判断最后一个节点是否被选中
- (BOOL)kj_isSelected {
    if (self.dataArray.count > 0) {
        UIView *view = self.dataArray.lastObject;
        if (self.kj_selectColor) {
            if (CGColorEqualToColor(self.kj_selectColor.CGColor, view.backgroundColor.CGColor)) {
                return YES;
            } else {
                return NO;
            }
        } else {
            if (CGColorEqualToColor([UIColor redColor].CGColor, view.backgroundColor.CGColor)) {
                return YES;
            } else {
                return NO;
            }
        }
    } else {
        return NO;
    }
}

@end
