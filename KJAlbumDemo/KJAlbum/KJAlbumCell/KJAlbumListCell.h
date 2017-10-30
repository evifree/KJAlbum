//
//  KJAlbumListCell.h
//  Join
//
//  Created by JOIN iOS on 2017/8/31.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KJUtility.h"

@interface KJAlbumListCell : UITableViewCell


+ (void)regisCellForTableView:(UITableView *)tableView;
+ (instancetype)dequeueCellForTableView:(UITableView *)tableView;

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UIImageView *imgSelected;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelCount;

@end
