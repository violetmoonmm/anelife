//
//  RoomView.h
//  eLife
//
//  Created by mac on 14-4-17.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RoomView : UIView

@property (nonatomic) BOOL selected;

- (void)buildIcon:(UIImage *)image selectedIcon:(UIImage *)sIcon title:(NSString *)title subtitle:(NSString *)subtitle backgroundImage:(UIImage *)bgdImage;

@end
