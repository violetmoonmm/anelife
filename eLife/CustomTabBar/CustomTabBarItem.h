//
//  CustomTabBarItem.h
//  eLife
//
//  Created by mac on 14-3-15.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomTabBarItem : UIButton


@property (nonatomic,retain) NSString *badgeValue;

//初始化
- (id)initWithFrame:(CGRect)frame
			  title:(NSString *)aTitle
			  image:(UIImage *)aImage
		 hightedImage:(UIImage *)ahightedImage;

//设置选中状态
- (void)setSelected:(BOOL)b;

- (void)setBadgeValue:(NSString *)aValue;

- (void)displayTrackPoint:(BOOL)yesOrNo;

@end
