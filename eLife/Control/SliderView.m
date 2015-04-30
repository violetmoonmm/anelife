//
//  WholeHouseView.m
//  eLife
//
//  Created by mac on 14-7-22.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "SliderView.h"
#import "PublicDefine.h"

#define UNDERLINE_HEIGHT 2 //下划线高
#define TITLE_FONT_SIZE 14

@interface SliderItem : UIView
{
    UILabel *_titleLabel;
    UIImageView *_imageView;;
}

@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) UIImage *image;
@property (nonatomic,strong) UIImage *selectedImage;
@property (nonatomic,assign) BOOL selected;

@end

@implementation SliderItem

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
         NSInteger iconWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 39 : 39);
        NSInteger iconHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 37 : 37);
        
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
        
        
        //水平分割线
        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame)-1, CGRectGetWidth([UIScreen mainScreen].bounds), 1)];
        sep.backgroundColor = [UIColor grayColor];
        sep.alpha = 0.3;
        [self addSubview:sep];
        
  
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


@implementation SliderView
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
        
        self.maxVisibleNum = 3;
        
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
    
    self.maxVisibleNum = 3;
    
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

- (void)buildWithTitles:(NSArray *)titles normalImages:(NSArray *)images selectedImages:(NSArray *)selectedImages
{
   
    
    CGFloat itemWidth = CGRectGetWidth(_scrlView.frame)/self.maxVisibleNum;
    NSInteger itemCount = [titles count];
    
    for (int i = 0; i<itemCount; i++) {
        SliderItem *item = [[SliderItem alloc] initWithFrame:CGRectMake(itemWidth*i, 0, itemWidth, CGRectGetHeight(_scrlView.frame))];
        [item setTitle:[titles objectAtIndex:i]];
        [item setImage:[images objectAtIndex:i]];
        [item setSelectedImage:[selectedImages objectAtIndex:i]];
        
        UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectItem:)];
        [item addGestureRecognizer:gest];
        
        [_scrlView addSubview:item];
        
        [_items addObject:item];
        
        
//        //垂直分割线
//        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(item.frame)+1, 1, 1, CGRectGetHeight(item.frame)-3)];
//        sep.backgroundColor = [UIColor grayColor];
//        sep.alpha = 0.3;
//        [_scrlView addSubview:sep];
    }
    
    _scrlView.contentSize = CGSizeMake(itemCount*itemWidth, CGRectGetHeight(self.bounds));
}

- (void)selectItem:(UIGestureRecognizer *)gesture
{
    SliderItem *item = (SliderItem *)[gesture view];
    
    NSInteger index = [_items indexOfObject:item];
    

    
    if ([self.delegate respondsToSelector:@selector(sliderView:didSelectItemAtIndex:)]) {
        [self.delegate sliderView:self didSelectItemAtIndex:index];
    }
    
 
    [self setSelectedIndex:index];
    
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    if ([_items count] > 0 && _selectedIndex != INVALID_INDEX && _selectedIndex < [_items count]) {
        
        SliderItem *tempItem = [_items objectAtIndex:_selectedIndex];
        tempItem.selected = NO;
        
    }
    
    _selectedIndex = selectedIndex;
    
    if ([_items count] > 0 && _selectedIndex != INVALID_INDEX && _selectedIndex < [_items count]) {
        
        SliderItem *selItem = [_items objectAtIndex:_selectedIndex];
        selItem.selected = YES;
    }
    
    
}

- (void)layoutSubviews
{
//    CGRect scrlViewFrame = _scrlView.frame;
//    

    
}

@end
