//
//  KJShortVideoAlbumCell.m
//  Join
//
//  Created by JOIN iOS on 2017/9/4.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import "KJShortVideoAlbumCell.h"

@interface KJShortVideoAlbumCell ()
@property (weak, nonatomic) IBOutlet UIImageView *bgView;

@end

@implementation KJShortVideoAlbumCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

+ (void)regisCellForCollectionView:(UICollectionView *)collectionView {
    [collectionView registerNib:[UINib nibWithNibName:@"KJShortVideoAlbumCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"KJShortVideoAlbumCell"];
}

+ (instancetype)dequeueCellForCollectionView:(UICollectionView *)collectionView withIndex:(NSIndexPath *)indexPath {
    return [collectionView dequeueReusableCellWithReuseIdentifier:@"KJShortVideoAlbumCell" forIndexPath:indexPath];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        self.layer.borderWidth = 1.0f;
        self.bgView.backgroundColor = [UIColor colorWithHex:0x000000 alpha:0.6];
    } else {
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.borderWidth = 0.0f;
        self.bgView.backgroundColor = [UIColor clearColor];
    }
}

@end
