//
//  ExpansiveCell.h
//  eLife
//
//  Created by mac on 14-3-31.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HeaderView.h"
#import "ContentView.h"

@interface ExpansiveCell : UIView

@property (nonatomic,strong) HeaderView *headerView;
@property (nonatomic,strong) UIView *contentView;

@end
