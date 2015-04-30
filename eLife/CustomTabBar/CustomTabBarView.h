//
//  CustomTabBarView.h
//  eLife
//
//  Created by mac on 14-3-15.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CustomTabBarViewDelegate;


@interface CustomTabBarView : UIView

@property (nonatomic,assign) id<CustomTabBarViewDelegate> delegate;

- (void)setTitleList:(NSArray *)aTitleList
			   iconList:(NSArray *)aIconList
	   selectedIconList:(NSArray *)aSelectedIconList
               bgdImage:(UIImage *)aBgdImage;

- (void)setBadgeValue:(NSString *)aValue
                atIndex:(int)aIndex;

- (void)displayTrackPoint:(BOOL)yesOrNo atIndex:(int)aIndex;

- (void)selectItemAtIndex:(NSInteger)index;

@end

@protocol CustomTabBarViewDelegate <NSObject>

- (void)customTabBar:(CustomTabBarView *)customtabBar selectedItemAtIndex:(NSInteger)aIndex;

@end