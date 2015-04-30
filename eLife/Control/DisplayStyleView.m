//
//  DisplayStyleView.m
//  eLife
//
//  Created by 陈杰 on 14/12/19.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "DisplayStyleView.h"
#import "PublicDefine.h"


#define INDICATOR_WIDTH 70
#define INDICATOR_HEIGHT 3

@implementation DisplayStyleView
{
    NSMutableArray *items;
    
    UIView *indicatorView;
    
    NSInteger itemWidth;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        items = [NSMutableArray arrayWithCapacity:1];
        
        
        _selectedIndex = INVALID_INDEX;
        
        //水平分割线
        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame)-1, CGRectGetWidth([UIScreen mainScreen].bounds), 1)];
        sep.backgroundColor = [UIColor grayColor];
        sep.alpha = 0.3;
        [self addSubview:sep];
    }
    
    return self;
}

- (void)setTitles:(NSArray *)titles
{
    itemWidth = CGRectGetWidth(self.bounds)/([titles count]+1);
    NSInteger height = CGRectGetHeight(self.bounds);
    
    UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, itemWidth, height)];
    nameLbl.text = @"排序方式:";
    nameLbl.font = [UIFont systemFontOfSize:16];
    nameLbl.textAlignment = NSTextAlignmentCenter;
    nameLbl.backgroundColor = [UIColor clearColor];
    [self addSubview:nameLbl];
    
    for (int i = 0; i<[titles count]; i++)
    {
        
        NSString *title = [titles objectAtIndex:i];
        
        UIButton *item = [UIButton buttonWithType:UIButtonTypeCustom];
        item.frame = CGRectMake(CGRectGetMaxX(nameLbl.frame)+i*itemWidth, 0, itemWidth, height);
        [item setTitle:title forState:UIControlStateNormal];
        [item setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [item setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [item.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [item addTarget:self action:@selector(selectItem:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:item];
        [items addObject:item];
        
        if (i == 0) {
            indicatorView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(item.frame)+(itemWidth-INDICATOR_WIDTH)/2, CGRectGetHeight(self.bounds)-6, INDICATOR_WIDTH, INDICATOR_HEIGHT)];
            indicatorView.backgroundColor = [UIColor colorWithRed:17/255. green:143/255. blue:252/255. alpha:1];
            [self addSubview:indicatorView];
//            indicatorView.hidden = NO;
        }
    }
    
}


- (void)selectItem:(UIButton *)sender
{
    NSInteger indx = [items indexOfObject:sender];
    
    if ([self.delegate respondsToSelector:@selector(displayStyleView:didSelectItemAtIndex:)]) {
        [self.delegate displayStyleView:self didSelectItemAtIndex:indx];
    }
    
    
    [self setSelectedIndex:indx animated:YES];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{

    [self setSelectedIndex:selectedIndex animated:NO];
    
}


- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated
{
    if ([items count] > 0 && _selectedIndex != INVALID_INDEX && _selectedIndex < [items count]) {
        
        UIButton *tempItem = [items objectAtIndex:_selectedIndex];
        tempItem.selected = NO;
        
    }
    
    _selectedIndex = selectedIndex;
    
    UIButton *selItem = nil;
    
    if ([items count] > 0 && _selectedIndex != INVALID_INDEX && _selectedIndex < [items count]) {
        
        selItem = [items objectAtIndex:_selectedIndex];
        selItem.selected = YES;
    }
    
    
    CGRect frame = indicatorView.frame;
    frame.origin.x = CGRectGetMinX(selItem.frame)+(itemWidth-INDICATOR_WIDTH)/2;
    
    if (animated) {
        [UIView animateWithDuration:0.15 animations:^{
            indicatorView.frame = frame;
        }];
    }
    else {
         indicatorView.frame = frame;
    }
}

@end
