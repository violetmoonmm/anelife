//
//  VideoChannelView.m
//  eLife
//
//  Created by 陈杰 on 14/11/27.
//  Copyright (c) 2014年 mac. All rights reserved.
//


#import "VideoChannelView.h"
#import "PublicDefine.h"

#define UNDERLINE_HEIGHT 2 //下划线高
#define TITLE_FONT_SIZE 14

@interface VideoChannelItem : UIView
{
    UILabel *_titleLabel;
    UIImageView *_imageView;
    UIView *_bgdView;
}

@property (nonatomic,strong) NSString *title;
//@property (nonatomic,strong) UIImage *image;
@property (nonatomic,assign) BOOL selected;
@property (nonatomic,strong) UIView *contentView;

@end

@implementation VideoChannelItem

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        NSInteger iconWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 35 : 35);
        NSInteger iconHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 19 : 19);
        
        NSInteger labelHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 20 : 20);
        NSInteger labelSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 12 : 14);
        
        NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 2 : 2);
        
        NSInteger originX = 0;
        NSInteger sapcingX = originX;
        NSInteger bgdH = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 50 : 60);
        
        NSInteger originY = (CGRectGetHeight(frame) - bgdH - labelHeight - spacingY)/2;
        

        //黑色背景
        _bgdView = [[UIView alloc] initWithFrame:CGRectMake(originX, originY, CGRectGetWidth(frame), bgdH)];
        _bgdView.backgroundColor = [UIColor blackColor];
        _bgdView.userInteractionEnabled = YES;
        [self addSubview:_bgdView];
        
//        //摄像头
//        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(_bgdView.frame)-iconWidth)/2, (CGRectGetHeight(_bgdView.frame)-iconHeight)/2, iconWidth, iconHeight)];
//        _imageView.backgroundColor = [UIColor clearColor];
//        _imageView.userInteractionEnabled = YES;
//        [_bgdView addSubview:_imageView];
        
//        UIView *lblBgdView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_bgdView.frame)+spacingY, CGRectGetWidth(frame), labelHeight)];
//        lblBgdView.backgroundColor = [UIColor colorWithRed:232/255. green:232/255. blue:232/255. alpha:1];
//        [self addSubview:lblBgdView];
        
        _titleLabel  = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_bgdView.frame), CGRectGetMaxY(_bgdView.frame)+spacingY, CGRectGetWidth(_bgdView.frame), labelHeight)];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:labelSize];
        _titleLabel.backgroundColor = [UIColor clearColor];
        [self addSubview: _titleLabel];
        

        //self.backgroundColor = [UIColor clearColor];
        
    }
    return self;
}




- (void)setTitle:(NSString *)title
{
    _title = title;
    
    [self setNeedsLayout];
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    [self setNeedsLayout];
}

//- (void)setImage:(UIImage *)image
//{
//    _image = image;
//    [self setNeedsLayout];
//}

- (void)setContentView:(UIView *)contentView
{
    [_contentView removeFromSuperview];
    
    _contentView = contentView;
    
//    CGRect bounds = _contentView.bounds;
    
    CGRect frame = CGRectMake((CGRectGetWidth(_bgdView.bounds)-CGRectGetWidth(_contentView.bounds))/2, (CGRectGetHeight(_bgdView.bounds)-CGRectGetHeight(_contentView.bounds))/2, CGRectGetWidth(_contentView.bounds), CGRectGetHeight(_contentView.bounds));
    _contentView.frame = frame;
    
    [_bgdView addSubview:_contentView];
}


- (void)layoutSubviews
{
    
    _titleLabel.text = _title;
    
    
//    _imageView.image =  self.image;
    
    
    if (self.selected) {
        _bgdView.layer.borderColor = [UIColor colorWithRed:255/255. green:126/255. blue:0/255. alpha:1].CGColor;
        _bgdView.layer.borderWidth = 1.5;
    }
    else {
        _bgdView.layer.borderWidth = 0.0;
    }
    
}

@end


#define MAX_VISIBLE_ITEM 3

@implementation VideoChannelView
{
    
    UIScrollView *_scrlView;
    NSMutableArray *_items;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        _selectedIndex = INVALID_INDEX;
        
        _items = [NSMutableArray arrayWithCapacity:1];
        
        
        _scrlView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
        _scrlView.showsHorizontalScrollIndicator = NO;
        _scrlView.backgroundColor = [UIColor clearColor];
        [self addSubview:_scrlView];
        
        
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


- (void)awakeFromNib
{
    _selectedIndex = INVALID_INDEX;
    
    _items = [NSMutableArray arrayWithCapacity:1];
    
    
    _scrlView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
    _scrlView.showsHorizontalScrollIndicator = NO;
    _scrlView.backgroundColor = [UIColor clearColor];
    [self addSubview:_scrlView];
    
    
    self.backgroundColor = [UIColor clearColor];
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */


- (void)reloadData
{
    CGFloat itemWidth = 98;
    NSInteger visibleCount = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 3 : 5);
    NSInteger spacingX = (CGRectGetWidth(self.bounds) - visibleCount*itemWidth)/(visibleCount+1);
    NSInteger itemCount = [self.delegate numberOfItemsInVideoChannelView:self];
    
    for (int i = 0; i<itemCount; i++) {
        VideoChannelItem *item = [[VideoChannelItem alloc] initWithFrame:CGRectMake(spacingX+(itemWidth+spacingX)*i, 0, itemWidth, CGRectGetHeight(_scrlView.frame))];
        
        NSString *title = [self.delegate channelView:self titleAtIndex:i];
        [item setTitle:title];
        
//        UIImage *image = [self.delegate channelView:self imageAtIndex:i];
//        
//        [item setImage:image];
        
        UIView *contentView = [self.delegate channelView:self contentViewAtIndex:i];
        [item setContentView:contentView];
        
        UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectItem:)];
        [item addGestureRecognizer:gest];
        
        [_scrlView addSubview:item];
        
        [_items addObject:item];
        
    }
    
    _scrlView.contentSize = CGSizeMake(itemCount*(itemWidth+spacingX)+spacingX, CGRectGetHeight(self.bounds));
}

- (void)reloadItemAtIndex:(NSInteger)index
{
    if (index <= [_items count]) {
        VideoChannelItem *item = [_items objectAtIndex:index];
        
        NSString *title = [self.delegate channelView:self titleAtIndex:index];
        [item setTitle:title];

        UIView *contentView = [self.delegate channelView:self contentViewAtIndex:index];
        [item setContentView:contentView];
    }
    
}

- (void)selectItem:(UIGestureRecognizer *)gesture
{
    VideoChannelItem *item = (VideoChannelItem *)[gesture view];
    
    NSInteger index = [_items indexOfObject:item];
    
    
    [self setSelectedIndex:index];
    
    if ([self.delegate respondsToSelector:@selector(channelView:didSelectAtIndex:)]) {
        [self.delegate channelView:self didSelectAtIndex:index];
    }

    
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    if ([_items count] > 0 && _selectedIndex != INVALID_INDEX && _selectedIndex < [_items count]) {
        
        VideoChannelItem *tempItem = [_items objectAtIndex:_selectedIndex];
        tempItem.selected = NO;
        
    }
    
    _selectedIndex = selectedIndex;
    
    if ([_items count] > 0 && _selectedIndex != INVALID_INDEX && _selectedIndex < [_items count]) {
        
        VideoChannelItem *selItem = [_items objectAtIndex:_selectedIndex];
        selItem.selected = YES;
    }
    
    
}

- (void)layoutSubviews
{
    //    CGRect scrlViewFrame = _scrlView.frame;
    //    
    
    
}

@end

