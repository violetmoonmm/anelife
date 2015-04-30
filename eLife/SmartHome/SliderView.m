//
//  WholeHouseView.m
//  eLife
//
//  Created by mac on 14-7-22.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "SliderView.h"

#define UNDERLINE_HEIGHT 2 //下划线高
#define TITLE_FONT_SIZE 14

@interface SliderItem : UIView
{
    UILabel *_titleLable;
    UIView *_underline;
}

@property (nonatomic,strong) NSString *title;
@property (nonatomic,assign) BOOL selected;

@end

@implementation SliderItem

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        _titleLable  = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLable.textColor = [UIColor blackColor];
        _titleLable.font = [UIFont systemFontOfSize:TITLE_FONT_SIZE];
        _titleLable.backgroundColor = [UIColor clearColor];
        [self addSubview: _titleLable];
        
        _underline = [[UIView alloc] initWithFrame:CGRectZero];
        _underline.backgroundColor = [UIColor colorWithRed:72/255. green:120/255. blue:41/255. alpha:1];
        _underline.hidden = YES;
        [self addSubview:_underline];
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

    _underline.hidden = _selected ? NO : YES;
}

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;

    
    CGSize size = [_title sizeWithFont:[UIFont systemFontOfSize:TITLE_FONT_SIZE] constrainedToSize:bounds.size];
    _titleLable.text = _title;
    _titleLable.frame = CGRectMake((CGRectGetWidth(bounds)-size.width)/2, (CGRectGetHeight(bounds)-size.height)/2, size.width, size.height);
    
    NSInteger width = CGRectGetWidth(_titleLable.frame) + 12;
    _underline.frame = CGRectMake((CGRectGetWidth(bounds)-width)/2, CGRectGetHeight(bounds)-UNDERLINE_HEIGHT, width, UNDERLINE_HEIGHT);

}

@end


#define MAX_VISIBLE_ITEM 5

@implementation SliderView
{
    NSArray *_titles;
    UIScrollView *_scrlView;
    NSMutableArray *_items;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        _items = [NSMutableArray arrayWithCapacity:1];
        
        _scrlView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _scrlView.showsHorizontalScrollIndicator = NO;
        
        _scrlView.backgroundColor = [UIColor colorWithRed:247/255. green:254/255. blue:243/255. alpha:1];

    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)buildWithTitles:(NSArray *)titles
{
    _titles = titles;
    
    _scrlView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
    _scrlView.showsHorizontalScrollIndicator = NO;
    //_scrlView.backgroundColor = [UIColor redColor];
    [self addSubview:_scrlView];
    
    CGFloat itemWidth = CGRectGetWidth(_scrlView.frame)/MAX_VISIBLE_ITEM;
    NSInteger itemCount = [titles count];
    
    for (int i = 0; i<itemCount; i++) {
        SliderItem *item = [[SliderItem alloc] initWithFrame:CGRectMake(itemWidth*i, 0, itemWidth, CGRectGetHeight(_scrlView.frame))];
        [item setTitle:[titles objectAtIndex:i]];
        
        UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectItem:)];
        [item addGestureRecognizer:gest];
        
        [_scrlView addSubview:item];
        
        [_items addObject:item];
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
    
    //取消选中
    SliderItem *tempItem = [_items objectAtIndex:_selectedIndex];
    tempItem.selected = NO;
    
    _selectedIndex = index;
    
    //设置选中
    [item setSelected:YES];
    
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    if ([_items count] > 0 && selectedIndex < [_items count]) {
        SliderItem *tempItem = [_items objectAtIndex:_selectedIndex];
        tempItem.selected = NO;
        
        _selectedIndex = selectedIndex;
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
