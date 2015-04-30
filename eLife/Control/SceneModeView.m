//
//  SceneModeView.m
//  eLife
//
//  Created by 陈杰 on 14/11/26.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "SceneModeView.h"

#import "PublicDefine.h"


#define ICON_SIZE ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 65 : 100)
#define LBL_HEIGHT 22
#define SPACING_Y 4

@interface SceneModeItem : UIView
{
    UIImageView *iconView;
    UILabel *nameLabel;
    
    UIColor *normalColor;
    UIColor *selectedColor;
}


@property (nonatomic,strong) NSString *name;
@property (nonatomic) BOOL selected;
@property (nonatomic,strong) UIImage *normalImage;
@property (nonatomic,strong) UIImage *selectedImage;

@end


@implementation SceneModeItem

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        
        normalColor = [UIColor blackColor];
        selectedColor = [UIColor blackColor];
        
        NSInteger iconViewSize = ICON_SIZE;
        NSInteger originX = (CGRectGetWidth(frame)-iconViewSize)/2;
        NSInteger spacingY = SPACING_Y;
        
        iconView = [[UIImageView alloc] initWithFrame:CGRectMake(originX, (CGRectGetHeight(frame)-iconViewSize)/2, iconViewSize, iconViewSize)];
        iconView.backgroundColor = [UIColor clearColor];
        [self addSubview:iconView];
        
        NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 14 : 16);

        nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(iconView.frame)+spacingY, CGRectGetWidth(frame), LBL_HEIGHT)];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.font = [UIFont systemFontOfSize:fontSize];
        nameLabel.textAlignment = NSTextAlignmentCenter;
        nameLabel.textColor = [UIColor blackColor];
        [self addSubview:nameLabel];
    }
 
    return self;
}


- (void)setName:(NSString *)name
{
    _name = name;
    
    [self setNeedsLayout];
}

- (void)setNormalImage:(UIImage *)normalImage
{
    _normalImage = normalImage;
    
    [self setNeedsLayout];
}


- (void)setSelectedImage:(UIImage *)selectedImage
{
    _selectedImage = selectedImage;
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
     nameLabel.text = _name;
    
    if (_selected) {
//        nameLabel.textColor = selectedColor;
        iconView.image = _selectedImage;
    }
    else {
//        nameLabel.textColor = normalColor;
        iconView.image = _normalImage;
    }
}


- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    [self setNeedsLayout];
}

@end


@implementation SceneModeView
{
    NSMutableArray *items;
//    NSMutableArray *titleArray;
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
//        titleArray = [NSMutableArray arrayWithCapacity:1];
        
        _selectedIndex = INVALID_INDEX;
    }
    
    return self;
}



- (void)selectItem:(UIGestureRecognizer *)gesture
{
    SceneModeItem *item = (SceneModeItem *)[gesture view];
    
    NSInteger index = [items indexOfObject:item];
    
    
    if ([self.delegate respondsToSelector:@selector(sceneModeView:didSelectAtIndex:)]) {
        [self.delegate sceneModeView:self didSelectAtIndex:index];
    }
    
    
    [self setSelectedIndex:index];
    
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    
    if ([items count] > 0 && _selectedIndex != INVALID_INDEX && _selectedIndex < [items count]) {
        
        SceneModeItem *tempItem = [items objectAtIndex:_selectedIndex];
        tempItem.selected = NO;
        
    }
    
    _selectedIndex = selectedIndex;
    
    if ([items count] > 0 && _selectedIndex != INVALID_INDEX && _selectedIndex < [items count]) {
        
        SceneModeItem *selItem = [items objectAtIndex:_selectedIndex];
        selItem.selected = YES;
    }
    
    
}


- (void)reloadData
{
    for (SceneModeItem *item in items)
    {
        [item removeFromSuperview];
    }
    
    [items removeAllObjects];
    
    NSInteger numOfItems = [self.delegate numberOfItemsInSceneModeView:self];

    NSInteger itemSpacingY = 18;
    NSInteger orignY = itemSpacingY;
    
    NSInteger itemWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 80 : 160);
    NSInteger itemHeight = ICON_SIZE + LBL_HEIGHT + SPACING_Y*3;
    
    NSInteger itemSpacingX = (CGRectGetWidth(self.bounds)-self.numOfPerRow*itemWidth)/(self.numOfPerRow+1);
    NSInteger originX = itemSpacingX;
    
  
    
    for (int i = 0; i<numOfItems; i++)
    {
        NSInteger column = (i%self.numOfPerRow);//第几列
        NSInteger row = i/self.numOfPerRow;//第几行
        
        SceneModeItem *item = [[SceneModeItem alloc] initWithFrame:CGRectMake(originX+column*(itemWidth+itemSpacingX), (itemSpacingY+itemHeight)*row+orignY, itemWidth, itemHeight)];
        
        item.name = [self.delegate sceneModeView:self titleAtIndex:i];
        item.normalImage = [self.delegate sceneModeView:self normalImageAtIndex:i];
        item.selectedImage = [self.delegate sceneModeView:self selectedImageAtIndex:i];
        
        UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectItem:)];
        [item addGestureRecognizer:gest];
        
        
        [items addObject:item];
        
        [self addSubview:item];
    }

    
    NSInteger numOfRows = numOfItems/self.numOfPerRow + ((numOfItems%self.numOfPerRow > 0) ? 1 : 0);
    
    CGRect frame = self.frame;
    
    frame.size.height = (itemSpacingY+itemHeight)*numOfRows+2*orignY;
    
    self.frame = frame;
}


@end
