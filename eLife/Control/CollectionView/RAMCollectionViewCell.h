//
//  RAMCollectionViewCell.h
//  RAMCollectionViewFlemishBondLayoutDemo
//
//  Created by Rafael Aguilar Martín on 20/10/13.
//  Copyright (c) 2013 Rafael Aguilar Martín. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RAMCollectionViewCell : UICollectionViewCell


- (void)configureCellWithText:(NSString *)text textColor:(UIColor *)textColor;//只显示文字

- (void)configureCellWithIcon:(UIImage *)icon additionView:(UIView *)additionView text:(NSString *)text subText:(NSString *)subText textColor:(UIColor *)textColor;//文字和图片

- (void)startAnimating;

- (void)stopAnimating;

@end
