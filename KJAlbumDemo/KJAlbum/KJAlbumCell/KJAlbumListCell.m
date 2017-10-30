//
//  KJAlbumListCell.m
//  Join
//
//  Created by JOIN iOS on 2017/8/31.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import "KJAlbumListCell.h"

@implementation KJAlbumListCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    if (selected) {
        self.contentView.backgroundColor = [UIColor colorWithHex:0xe2e2e2];
    } else {
        self.contentView.backgroundColor = [UIColor colorWithHex:0xeeeeee];
    }
    // Configure the view for the selected state
}

+ (void)regisCellForTableView:(UITableView *)tableView {
    [tableView registerNib:[UINib nibWithNibName:@"KJAlbumListCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"KJAlbumListCell"];
}

+ (instancetype)dequeueCellForTableView:(UITableView *)tableView {
    return [tableView dequeueReusableCellWithIdentifier:@"KJAlbumListCell"];
}

@end
