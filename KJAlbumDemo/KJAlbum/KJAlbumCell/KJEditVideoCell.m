//
//  KJEditVideoCell.m
//  KJAlbumDemo
//
//  Created by JOIN iOS on 2017/10/25.
//  Copyright © 2017年 Kegem. All rights reserved.
//

#import "KJEditVideoCell.h"

@implementation KJEditVideoCell

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
    [collectionView registerNib:[UINib nibWithNibName:@"KJEditVideoCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"KJEditVideoCell"];
}

+ (instancetype)dequeueCellForCollectionView:(UICollectionView *)collectionView withIndex:(NSIndexPath *)indexPath {
    return [collectionView dequeueReusableCellWithReuseIdentifier:@"KJEditVideoCell" forIndexPath:indexPath];
}

@end
