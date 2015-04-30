//  CustomTabBarView.m
//  eLife
//
//  Created by mac on 14-3-15.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "CustomTabBarView.h"
#import "CustomTabBarItem.h"


@implementation CustomTabBarView
{
    NSMutableArray *_items;
    NSInteger _selectedIndex;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _items = [NSMutableArray arrayWithCapacity:1];
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

- (void)selectItem:(CustomTabBarItem *)sender
{

    NSInteger index =  [_items indexOfObject:sender];
    

    //[self selectItemAtIndex:index];
    
    if ([self.delegate respondsToSelector:@selector(customTabBar:selectedItemAtIndex:)]) {
        [self.delegate customTabBar:self selectedItemAtIndex:index];
    }
}

- (void)selectItemAtIndex:(NSInteger)index
{
    if (index == _selectedIndex) {
        return;
    }
    
    [[_items objectAtIndex:index] setSelected:YES];
    
    [[_items objectAtIndex:_selectedIndex] setSelected:NO];
    
    _selectedIndex = index;

}

- (void)setTitleList:(NSArray *)aTitleList
			   iconList:(NSArray *)aIconList
	   selectedIconList:(NSArray *)aSelectedIconList
               bgdImage:(UIImage *)aBgdImage
{
    _selectedIndex = 0;
    
//    UIImageView *backImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
//    backImageView.backgroundColor = [UIColor clearColor];
//    backImageView.image = aBgdImage;
//    [self addSubview:backImageView];
    
    self.backgroundColor = [UIColor colorWithPatternImage:aBgdImage];
   
    NSUInteger theNum = [aTitleList count];
    int width = CGRectGetWidth(self.frame) / theNum;
    
    for (int i = 0; i < theNum; i++) {
        CGRect itemFrame  = CGRectMake(i*width, 0, width, CGRectGetHeight(self.frame));
        CustomTabBarItem *item = [[CustomTabBarItem alloc] initWithFrame:itemFrame title:[aTitleList objectAtIndex:i] image:[aIconList objectAtIndex:i] hightedImage:[aSelectedIconList objectAtIndex:i]];
        [item addTarget:self action:@selector(selectItem:) forControlEvents:UIControlEventTouchUpInside];

        [item setBackgroundColor:[UIColor clearColor]];
        [item setSelected:NO];
        
        [_items addObject:item];
        [self addSubview:item];

    }

    
    [[_items objectAtIndex:0] setSelected:YES];
}

- (void)displayTrackPoint:(BOOL)yesOrNo atIndex:(int)aIndex
{
    [[_items objectAtIndex:aIndex] displayTrackPoint:yesOrNo];
}

- (void)setBadgeValue:(NSString *)aValue
              atIndex:(int)aIndex
{
    [[_items objectAtIndex:aIndex] setBadgeValue:aValue];
}

@end
