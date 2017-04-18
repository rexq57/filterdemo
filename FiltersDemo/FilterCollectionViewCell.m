//
//  FilterCollectionViewCell.m
//  FiltersDemo
//
//  Created by rexq57 on 2017/4/17.
//  Copyright © 2017年 rexq57. All rights reserved.
//

#import "FilterCollectionViewCell.h"

@interface FilterCollectionViewCell()
{
    IBOutlet UILabel* _nameLabel;
    IBOutlet UIImageView* _imageView;
}

@end

@implementation FilterCollectionViewCell

- (void) setName:(NSString *)name
{
    _name = name;
    
    _nameLabel.text = name;
}

- (void) setImage:(UIImage *)image
{
    _image = image;
    
    _imageView.image = image;
}

@end
