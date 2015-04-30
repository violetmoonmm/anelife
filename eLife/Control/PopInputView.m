//
//  PopInputView.m
//  eLife
//
//  Created by 陈杰 on 14/12/18.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "PopInputView.h"

#define WIDTH 260
#define HEIGHT 150

#define BUTTON_HEIGHT 44

@implementation PopInputView
{
    UITextField *inputView;
    
    UIView *contentView;
    UIView *bgdView;
    
    __weak id<PopInputViewDelegate> _delegate;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (id)initWithTitle:(NSString *)title placeholder:(NSString *)placeholder delegate:(id<PopInputViewDelegate>)delegate
{
    if (self = [super initWithFrame:[UIScreen mainScreen].bounds]) {

        _delegate = delegate;
        
        bgdView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        bgdView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        [self addSubview:bgdView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickBgd)];
        [bgdView addGestureRecognizer:tap];
        
        contentView = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(bgdView.bounds)-WIDTH)/2, (CGRectGetHeight(bgdView.bounds)-HEIGHT)/2, WIDTH, HEIGHT)];
        contentView.backgroundColor = [UIColor whiteColor];
        contentView.layer.cornerRadius = 5.0;
        contentView.clipsToBounds = YES;
        [bgdView addSubview:contentView];
        
        UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 220, 30)];
        titleLbl.text = title;
        titleLbl.textAlignment = NSTextAlignmentCenter;
        titleLbl.font = [UIFont systemFontOfSize:18];
        titleLbl.backgroundColor = [UIColor clearColor];
        [contentView addSubview:titleLbl];
        
        NSInteger originX = 12;
        
        inputView = [[UITextField alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(titleLbl.frame)+16, WIDTH-2*originX, 32)];
        inputView.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        inputView.keyboardType = UIKeyboardTypeDefault;
        inputView.placeholder = placeholder;
        inputView.font = [UIFont systemFontOfSize:16];
        inputView.layer.borderWidth = 1;
        inputView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.3].CGColor;
        [contentView addSubview:inputView];
        
        UIView *hSep = [[UIView alloc] initWithFrame:CGRectMake(0, HEIGHT-BUTTON_HEIGHT-1, CGRectGetWidth(contentView.bounds), 1)];
        hSep.backgroundColor = [UIColor grayColor];
        hSep.alpha = 0.3;
        [contentView addSubview:hSep];
        
        
        
        UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelBtn.frame = CGRectMake(0, HEIGHT-BUTTON_HEIGHT, WIDTH/2, BUTTON_HEIGHT);
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [cancelBtn setTitleColor:[UIColor colorWithRed:17/255. green:143/255. blue:252/255. alpha:1] forState:UIControlStateNormal];
        [cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [cancelBtn addTarget:self action:@selector(clickCancel:) forControlEvents:UIControlEventTouchUpInside];
        cancelBtn.adjustsImageWhenHighlighted = YES;
        [contentView addSubview:cancelBtn];
        
        UIView *vSep = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(cancelBtn.frame)+1, HEIGHT-BUTTON_HEIGHT, 1, BUTTON_HEIGHT)];
        vSep.backgroundColor = [UIColor grayColor];
        vSep.alpha = 0.3;
        [contentView addSubview:vSep];
        
        UIButton *okBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        okBtn.frame = CGRectMake(CGRectGetMaxX(vSep.frame), HEIGHT-BUTTON_HEIGHT, WIDTH/2, BUTTON_HEIGHT);
        [okBtn setTitle:@"确定" forState:UIControlStateNormal];
        [okBtn setTitleColor:[UIColor colorWithRed:17/255. green:143/255. blue:252/255. alpha:1] forState:UIControlStateNormal];
        [okBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
         okBtn.adjustsImageWhenHighlighted = YES;
        [okBtn addTarget:self action:@selector(clickOK:) forControlEvents:UIControlEventTouchUpInside];
        [contentView addSubview:okBtn];
    }
    
    
    return self;
}

- (void)show
{
    contentView.transform =  CGAffineTransformMakeScale(1.2f, 1.2f);
    bgdView.alpha = 0;
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    
    [UIView animateWithDuration:0.2 animations:^{
         bgdView.alpha = 1;
        contentView.transform = CGAffineTransformIdentity;
    }completion:NULL];
    
    
}


- (void)dismiss
{
    [UIView animateWithDuration:0.2 animations:^{
        contentView.alpha = 0.1;
        bgdView.alpha = 0.1;
        contentView.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
    }completion:^(BOOL f){
        
        if (f) {
            [self removeFromSuperview];
        }
        
    }];
}

- (void)clickCancel:(id)sender
{
    
    if ([_delegate respondsToSelector:@selector(popInputView:clickCancelButtonWithText:)]) {
        [_delegate popInputView:self clickCancelButtonWithText:inputView.text];
    }
    
    

    [self dismiss];
    
   
}


- (void)clickOK:(id)sender
{
    
    if ([_delegate respondsToSelector:@selector(popInputView:clickOkButtonWithText:)]) {
        [_delegate popInputView:self clickOkButtonWithText:inputView.text];
    }
    
    [self dismiss];
}

- (void)clickBgd
{
    if ([inputView isFirstResponder]) {
        [inputView resignFirstResponder];
    }
}


@end
