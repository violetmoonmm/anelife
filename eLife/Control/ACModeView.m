//
//  WholeHouseView.m
//  eLife
//
//  Created by mac on 14-7-22.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "ACModeView.h"
#import "PublicDefine.h"

#define UNDERLINE_HEIGHT 2 //下划线高
#define TITLE_FONT_SIZE 14

@interface ModeItem : UIView
{
    UILabel *_titleLabel;
    UIImageView *_imageView;;
}

@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) UIImage *image;
@property (nonatomic,strong) UIImage *selectedImage;
@property (nonatomic,assign) BOOL selected;

@end

@implementation ModeItem

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
   
        
        NSInteger iconWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 32 : 32);
        NSInteger iconHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 32 : 32);
        
        NSInteger labelHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 20 : 20);
        NSInteger labelSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 16 : 16);
        
        NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 2 : 2);
        NSInteger originY = (CGRectGetHeight(frame) - iconHeight - labelHeight - spacingY)/2;
        
        
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(frame)-iconWidth)/2, originY, iconWidth, iconHeight)];
        _imageView.backgroundColor = [UIColor clearColor];
        [self addSubview:_imageView];
        
        _titleLabel  = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_imageView.frame)+spacingY, CGRectGetWidth(frame), labelHeight)];
        _titleLabel.textColor = [UIColor colorWithRed:91/255.0 green:91/255.0 blue:91/255.0 alpha:1];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:labelSize];
        _titleLabel.backgroundColor = [UIColor clearColor];
        [self addSubview: _titleLabel];
        
        //self.backgroundColor = [UIColor grayColor];
        
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

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self setNeedsLayout];
}

- (void)setSelectedImage:(UIImage *)selectedImage
{
    _selectedImage = selectedImage;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    
    
    _titleLabel.text = _title;
    
    
    _imageView.image = _selected ? self.selectedImage : self.image;
    
}

@end


#define MAX_VISIBLE_ITEM 3

@implementation ACModeView
{
    NSMutableArray *_items;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        _items = [NSMutableArray arrayWithCapacity:1];
        

        _selectedIndex = INVALID_INDEX;
        
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)awakeFromNib
{
    _items = [NSMutableArray arrayWithCapacity:1];
    
    
    _selectedIndex = INVALID_INDEX;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

- (void)buildWithTitles:(NSArray *)titles normalImages:(NSArray *)images selectedImages:(NSArray *)selectedImages
{
    
    
    CGFloat itemWidth = 47;
    CGFloat itemHeight = 66;
    NSInteger itemCount = [titles count];
    NSInteger spacing = 1;
    
    for (int i = 0; i<itemCount; i++) {
        ModeItem *item = [[ModeItem alloc] initWithFrame:CGRectMake((itemWidth+spacing)*i, 0, itemWidth, itemHeight)];
        [item setTitle:[titles objectAtIndex:i]];
        [item setImage:[images objectAtIndex:i]];
        [item setSelectedImage:[selectedImages objectAtIndex:i]];
        
        UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectItem:)];
        [item addGestureRecognizer:gest];
        
        [self addSubview:item];
        
        [_items addObject:item];
        
    }

}

- (void)selectItem:(UIGestureRecognizer *)gesture
{
    ModeItem *item = (ModeItem *)[gesture view];
    
    NSInteger index = [_items indexOfObject:item];
    
    
    if ([self.delegate respondsToSelector:@selector(ACModeView:didSelectItemAtIndex:)]) {
        [self.delegate ACModeView:self didSelectItemAtIndex:index];
    }
    
    
    [self setSelectedIndex:index];
    
    
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    
    if ([_items count] > 0 && _selectedIndex != INVALID_INDEX && _selectedIndex < [_items count]) {
        
        ModeItem *tempItem = [_items objectAtIndex:_selectedIndex];
        tempItem.selected = NO;
        
    }
    
    _selectedIndex = selectedIndex;
    
    if ([_items count] > 0 && _selectedIndex != INVALID_INDEX && _selectedIndex < [_items count]) {
        
        ModeItem *selItem = [_items objectAtIndex:_selectedIndex];
        selItem.selected = YES;
    }
    

}

- (void)layoutSubviews
{
    //    CGRect scrlViewFrame = _scrlView.frame;
    //    
    
    
}

@end
