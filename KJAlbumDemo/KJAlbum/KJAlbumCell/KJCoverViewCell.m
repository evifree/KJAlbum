//
//  KJCoverViewCell.m
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/10/27.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import "KJCoverViewCell.h"

@implementation KJCoverViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}


- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        self.layer.borderColor = [UIColor yellowColor].CGColor;
        self.layer.borderWidth = 2.0f;
    } else {
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.borderWidth = 0.0f;
    }
}


+ (void)regisCellForCollectionView:(UICollectionView *)collectionView {
    [collectionView registerNib:[UINib nibWithNibName:@"KJCoverViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"KJCoverViewCell"];
}

+ (instancetype)dequeueCellForCollectionView:(UICollectionView *)collectionView withIndex:(NSIndexPath *)indexPath {
    return [collectionView dequeueReusableCellWithReuseIdentifier:@"KJCoverViewCell" forIndexPath:indexPath];
}

@end
