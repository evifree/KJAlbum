//
//  KJShortPhotoAlbumCell.m
//  Join
//
//  Created by JOIN iOS on 2017/8/29.
//  Copyright © 2017年 huangkejin. All rights reserved.
//

#import "KJShortPhotoAlbumCell.h"

#import "KJAlbumBrowsController.h"

@implementation KJShortPhotoAlbumCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

+ (void)regisCellForCollectionView:(UICollectionView *)collectionView {
    [collectionView registerNib:[UINib nibWithNibName:@"KJShortPhotoAlbumCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"KJShortPhotoAlbumCell"];
}

+ (instancetype)dequeueCellForCollectionView:(UICollectionView *)collectionView withIndex:(NSIndexPath *)indexPath {
    return [collectionView dequeueReusableCellWithReuseIdentifier:@"KJShortPhotoAlbumCell" forIndexPath:indexPath];
}

- (IBAction)onSelectButtonAction:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didTapSelectedAction:)]) {
        [self.delegate didTapSelectedAction:self];
    }
}

@end
