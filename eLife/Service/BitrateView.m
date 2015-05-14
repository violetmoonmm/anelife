//
//  BitrateView.m
//  eLife
//
//  Created by 陈杰 on 15/5/13.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "BitrateView.h"

@interface BitrateItem : UIView

@property (nonatomic,strong) NSString *text;

@property (nonatomic,assign) BOOL selected;


@end

@implementation BitrateItem

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        //
        
        
    }
    
    return self;
}


- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIFont *font = [UIFont systemFontOfSize:16];
    
    UIColor *color = _selected ? [UIColor colorWithRed:84/255. green:193/255. blue:12/255. alpha:1] : [UIColor whiteColor];
    
    CGContextSetFillColorWithColor(context, [color  CGColor]);
    
    CGSize constraint = rect.size;
    CGSize displaySize = [self.text sizeWithFont:font constrainedToSize:constraint];
    CGRect displayRect = CGRectMake((rect.size.width - displaySize.width) / 2 , (rect.size.height - displaySize.height)/2, displaySize.width, displaySize.height);
    [self.text drawInRect:displayRect withFont:font lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentCenter];

    CGFloat radius = 2;
    CGContextAddArc(context, (rect.size.width - displaySize.width) / 2-radius-2, (rect.size.height - radius)/2, radius, 0, 2*M_PI, 0); //添加一个圆
    CGContextDrawPath(context, kCGPathFill);//绘制填充
    
    
}

@end

#define ITEM_H 40
#define ITEM_W 80


@interface BitrateView ()
{
    NSMutableArray *_itemArray;
   
}

@end

@implementation BitrateView

- (id)initWithText:(NSArray *)textArray
{
    CGFloat height = [textArray count]*ITEM_H;
    if (self = [super initWithFrame:CGRectMake(0, 0, ITEM_W, height)]) {
        
        [self setupSubviews:textArray];
    }
    
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    
}

- (void)setupSubviews:(NSArray *)textArray
{
    _itemArray = [NSMutableArray arrayWithCapacity:1];
    
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor colorWithRed:127/255. green:127/255. blue:127/255. alpha:1].CGColor;
    self.layer.cornerRadius = 5;
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
    
    for (int i = 0; i < [textArray count]; i++) {
        BitrateItem *item = [[BitrateItem alloc] initWithFrame:CGRectMake(0, i*ITEM_H, ITEM_W, ITEM_H)];
        item.text = [textArray objectAtIndex:i];
        
        [_itemArray addObject:item];
        
        [self addSubview:item];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [item addGestureRecognizer:tap];
        
        //不是最后一个,添加分割线
        if (i != [textArray count]) {
            UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, i*ITEM_H, ITEM_W, 1)];
            v.backgroundColor = [UIColor colorWithRed:127/255. green:127/255. blue:127/255. alpha:1];
            [self addSubview:v];;
            
        }
    }
    
}

- (void)handleTap:(UITapGestureRecognizer *)tap
{
    BitrateItem *oldSelectedView = [_itemArray objectAtIndex:_selectedIndex];
    oldSelectedView.selected = NO;
    
    BitrateItem *tapView = (BitrateItem *)tap.view;
    tapView.selected = YES;
    
     NSInteger index = [_itemArray indexOfObject:tapView];
    _selectedIndex = index;
    
    if ([self.delegate respondsToSelector:@selector(bitrateView:didSelectAtIndex:)]) {
        
       
        [self.delegate bitrateView:self didSelectAtIndex:index];
    }
}


- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    
    BitrateItem *oldSelectedView = [_itemArray objectAtIndex:_selectedIndex];
    oldSelectedView.selected = NO;
    
    _selectedIndex = selectedIndex;
    
    BitrateItem *selectedView = [_itemArray objectAtIndex:_selectedIndex];
    selectedView.selected = YES;
}

@end
