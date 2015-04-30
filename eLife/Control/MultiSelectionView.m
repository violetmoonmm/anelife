//
//  MultiSelectionView.m
//  eLife
//
//  Created by 陈杰 on 15/1/9.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "MultiSelectionView.h"

@interface MultiSelectionView ()
{
    NSInteger _hlButtonIndex;
    __weak id<MultiSelectionViewDelegate> _delegate;
    NSArray *_buttonTitles;
    
    NSMutableArray *_buttons;
    
    UIView *contentView;
}

@end


@implementation MultiSelectionView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (id)initWithTitles:(NSArray *)buttonTitles hlButtonIndex:(NSInteger)hlButtonIndex delegate:(id<MultiSelectionViewDelegate>)delegate
{
    if (self = [super initWithFrame:CGRectZero]) {
        _buttonTitles = buttonTitles;
        _hlButtonIndex = hlButtonIndex;
        _delegate = delegate;
        
        
        _buttons = [NSMutableArray arrayWithCapacity:1];
        
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMultiSelView)];
//        [self addGestureRecognizer:tap];
    }
    
    
    return self;
}


- (void)show
{
    
    CGRect frame = [UIApplication sharedApplication].keyWindow.bounds;
    
    self.frame = frame;
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    
    NSInteger num = [_buttonTitles count];
    NSInteger btnHeight = 44;
    NSInteger btnWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 120 : 160);
    NSInteger lineSpacing = 10;
    NSInteger rightEdge = 12;
    
    contentView = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(frame)-btnWidth)-rightEdge, 64, btnWidth, btnHeight*num)];
    contentView.backgroundColor = [UIColor whiteColor];
    contentView.layer.borderColor = [UIColor blackColor].CGColor;
    contentView.layer.borderWidth = 1.0;
    contentView.layer.cornerRadius = 5.0;
    contentView.layer.shadowColor = [UIColor blackColor].CGColor;
    contentView.layer.shadowOffset = CGSizeMake(0, 0);
    contentView.layer.shadowOpacity = 0.5;
    contentView.layer.shadowRadius = 5.0;
    [self addSubview:contentView];
    
    for (int i=0; i<num; i++)
    {
        UIColor *normalColor = [UIColor blackColor];
        UIColor *hlColor = [UIColor colorWithRed:220/255. green:70/255. blue:7/255. alpha:1];

        NSString *title = [_buttonTitles objectAtIndex:i];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0, btnHeight*i, CGRectGetWidth(contentView.frame), btnHeight);
        btn.titleLabel.font = [UIFont systemFontOfSize:16];
        [btn setTitle:title forState:UIControlStateNormal];
        [btn setTitleColor:hlColor forState:UIControlStateHighlighted];
        [btn setTitleColor:hlColor forState:UIControlStateSelected];
        [btn setTitleColor:normalColor forState:UIControlStateNormal];
        [btn setAdjustsImageWhenDisabled:YES];
        [btn addTarget:self action:@selector(selectAButton:) forControlEvents:UIControlEventTouchUpInside];
        [contentView addSubview:btn];
        
        if (i == _hlButtonIndex)
        {
            btn.selected = YES;
        }
        else {
           btn.selected = NO;
        }
        
        [_buttons addObject:btn];
        
        //分割线
        if (i < num-1) {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(lineSpacing, CGRectGetMaxY(btn.frame), CGRectGetWidth(contentView.frame)-2*lineSpacing, 1)];
            line.backgroundColor = [UIColor grayColor];
            line.alpha = 0.5;
            [contentView addSubview:line];
        }
        
    }
    
    //动画
    contentView.transform =  CGAffineTransformMakeScale(0.8f, 0.8f);
    contentView.alpha = 0.3;
    [UIView animateWithDuration:0.2 animations:^{

        contentView.alpha = 1.0;
        contentView.transform = CGAffineTransformIdentity;
    }completion:NULL];
}

- (void)selectAButton:(UIButton *)button
{
    for (UIButton *btn in  _buttons)
    {
        btn.selected = NO;
    }
    
    button.selected = YES;
    
    NSInteger selectIndex = [_buttons indexOfObject:button];
    
    if ([_delegate respondsToSelector:@selector(multiSelectionView:didSelectedAtIndex:)]) {
        [_delegate multiSelectionView:self didSelectedAtIndex:selectIndex];
    }
    
    [self dismissMultiSelView];
}


- (void)dismissMultiSelView
{

    [UIView animateWithDuration:0.2 animations:^{
        
        contentView.alpha = 0.1;
        contentView.transform =  CGAffineTransformMakeScale(0.8f, 0.8f);
    }completion:^(BOOL f){
        [self removeFromSuperview];
    }];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    UITouch *touch = [touches anyObject];
    
    CGPoint point = [touch locationInView:self];
    
    if (!CGRectContainsPoint(contentView.frame, point)) {
        [self dismissMultiSelView];
    }
}

@end
