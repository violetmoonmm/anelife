//
//  GridView.m
//  eLife
//
//  Created by mac on 14-4-1.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "GridView.h"

#import "RoomView.h"

#define ITEM_TAG 100
#define NUMBER_OF_ITEM_PERROW ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 3 : 4) //每行多少个view

@interface GridView () <BoxViewDelegate>
{
  
    RoomView *_selectedItem;
    BOOL _showBox;
    
    NSInteger _selectedRow;
    BoxView *_boxView;
    
    NSMutableArray *_rowViewArray;
    
    NSInteger _numOfItems;
}

- (void)clickItem:(UIButton *)sender;

@end

@implementation GridView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        NSLog(@"grid view init");
        
        _rowViewArray = [NSMutableArray arrayWithCapacity:1];
        self.userInteractionEnabled = YES;
        self.autoresizesSubviews = YES;

    }
    return self;
}

- (void)dealloc
{
   
    _boxView = nil;//防止_boxView被释放的时候收到kov通知导致崩溃
    self.delegate = nil;
    
    NSLog(@"grid view dealloc");

}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *v = [super hitTest:point withEvent:event];
    
    return v;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
//    if (CGRectContainsPoint(self.frame, point)) {
//        return YES;
//    }
//    
//    return NO;
    
    BOOL b = [super pointInside:point withEvent:event];
    
    return b;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (void)layoutSubviews
{
    for (UIView *v in _rowViewArray)
    {
        CGRect f = v.frame;
        f.size.width = CGRectGetWidth(self.frame);
        v.frame = f;
    }
    
    [super layoutSubviews];
}

- (void)buildWithTitles:(NSArray *)titles subTitles:(NSArray *)subtitles icons:(NSArray *)icons selectedIcons:(NSArray *)selectedIcons  bgdImages:(NSArray *)bgdImages
{
    _numOfItems = [titles count];

    for (UIView *v in self.subviews)
    {
        [v removeFromSuperview];
    }
    [_rowViewArray removeAllObjects];
    
    
    
    NSInteger magin_x = 8;
    NSInteger magin_y = 12;
    NSInteger btn_w = 90;
    NSInteger btn_h = 46;
    NSInteger origin_x = magin_x;
    NSInteger origin_y = magin_y;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        magin_x = 30;
        magin_y = 12;
        btn_w = 143;
        btn_h = 58;
        origin_x = magin_x;
        origin_y = magin_y;
    }
    
    UIView *rowView = nil;
    
    NSInteger itemCount = [titles count];
    for (int i= 0 ; i<itemCount; i++) {
        
        //一行视图
        if (i%NUMBER_OF_ITEM_PERROW == 0) {
            rowView = [[UIView alloc] initWithFrame:CGRectMake(0, origin_y+(btn_h + magin_y)*(i/NUMBER_OF_ITEM_PERROW), CGRectGetWidth(self.frame), btn_h)];
            [self addSubview:rowView];
            rowView.backgroundColor = [UIColor clearColor];
            [rowView setAutoresizesSubviews:YES];
            //rowView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            //[rowView setUserInteractionEnabled:YES];
            [_rowViewArray addObject:rowView];
        }
        
        //单个item
        CGRect frame = CGRectMake(origin_x + (btn_w + magin_x)*(i%NUMBER_OF_ITEM_PERROW), 0, btn_w, btn_h);
        RoomView *btn = [[RoomView alloc] initWithFrame:frame];
        [btn buildIcon:[icons objectAtIndex:i] selectedIcon:[selectedIcons objectAtIndex:i] title:[titles objectAtIndex:i] subtitle:[subtitles objectAtIndex:i] backgroundImage:[UIImage imageNamed:@"room_selected.png"]];
        btn.userInteractionEnabled = YES;
        btn.autoresizesSubviews = YES;
        btn.tag = i+ITEM_TAG;
        btn.backgroundColor = [UIColor clearColor];

        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickItem:)];
        [btn addGestureRecognizer:gesture];

        [rowView addSubview:btn];
    }
    
    CGRect frame = CGRectZero;
    NSInteger rowNum = itemCount/NUMBER_OF_ITEM_PERROW + ((itemCount%NUMBER_OF_ITEM_PERROW) > 0 ? 1 :0);//多少行
    frame.size.height = 2*origin_y+(rowNum-1)*magin_y +rowNum*btn_h;
    
    if (itemCount == 0) {
        frame.size.height = 60;
    }
    self.frame = frame;
//    self.backgroundColor = [UIColor clearColor];

}



- (void)reloadWholeHouseCtrlView
{
    CGFloat boxViewPreHeight = _boxView.frame.size.height;//boxview原来高度
    
    NSArray *devices = [NSArray array];

    NSInteger index = _numOfItems-1;
    
    if ([self.delegate respondsToSelector:@selector(deviceListForGridView:atIndex:)]) {
        devices = [self.delegate deviceListForGridView:self atIndex:index];//全宅控制
    }
    
    [_boxView setDevices:devices];//boxview确定现在frame
    
    
    CGFloat absHeight = _boxView.frame.size.height - boxViewPreHeight;//boxview现在高度差
    
    if ([self.delegate respondsToSelector:@selector(gridView:changeContentHeight:)]) {
        [self.delegate gridView:self changeContentHeight:absHeight];
    }
    
    
    CGRect myframe = self.frame;
    myframe.size.height += absHeight;
    self.frame = myframe;
    
    CGRect superViewFrame = self.superview.frame;
    superViewFrame.size.height += absHeight;
    self.superview.frame = superViewFrame;
    
    
    
    NSUInteger row = index/NUMBER_OF_ITEM_PERROW;//
    
    if (_selectedRow == row) {//当前展示的行
       
        
        for (NSUInteger i = row+1; i< [_rowViewArray count]; i++) {//下面的行调整高度
            UIView *rowView = [_rowViewArray objectAtIndex:i];
            CGRect frame = rowView.frame;
            frame.origin.y += absHeight;
            rowView.frame = frame;
        }
    }
    
    
}

- (void)closeBox
{
    NSLog(@"closeBox");
    
    if (_selectedItem) {
        NSUInteger row = [_rowViewArray indexOfObject:_selectedItem.superview];
        for (NSUInteger i= row+1;i<[_rowViewArray count];i++) {//下面的行调整y坐标
            UIView *rowView = [_rowViewArray objectAtIndex:i];
            CGRect frame = rowView.frame;
            frame.origin.y -= CGRectGetHeight(_boxView.frame);
            rowView.frame = frame;

        }
    }
    
    
    if (_showBox) {

        CGRect myframe = self.frame;
        myframe.size.height -= CGRectGetHeight(_boxView.frame);
        self.frame = myframe;
        
        [_boxView removeFromSuperview];
        _boxView = nil;
        
        NSLog(@"_boxView removeFromSuperview");
        
    }
    
    
    _selectedItem.selected = NO;
    _selectedItem = nil;
    _showBox = NO;
    
}



- (void)clickItem:(UIGestureRecognizer *)gst
{
    RoomView *sender = (RoomView*)[gst view];
    if (sender == _selectedItem) {
        return;
    }
    
    //取消选中
    if (_selectedItem) {
        [_selectedItem setSelected:NO];
    }
    
    //选中
    sender.selected = YES;
    _selectedItem = sender;
    
    
    //    if (self.showBoxView) {
    if (!_boxView) {
        NSLog(@"alloc init boxview");
        CGFloat origin_y = CGRectGetMaxY(sender.superview.frame);
        _boxView = [[BoxView alloc] initWithFrame:CGRectMake(0, origin_y, CGRectGetWidth(self.frame), 0)];
        _boxView.delegate = self;
        
        [self addSubview:_boxView];
    }
    
    //        }
    
    CGFloat boxViewPreHeight = _boxView.frame.size.height;//boxview原来高度
    
  
    
    NSUInteger index = sender.tag - ITEM_TAG;
    
    NSArray *devices = [NSArray array];
    
    //header
    if ([self.delegate respondsToSelector:@selector(gridView:headerForBoxViewAtIndex:)]) {
        _boxView.headerView = [self.delegate gridView:self headerForBoxViewAtIndex:index];
    }
    
    //cell
    if ([self.delegate respondsToSelector:@selector(deviceListForGridView:atIndex:)]) {
        devices = [self.delegate deviceListForGridView:self atIndex:index];
    }
    
    [_boxView setDevices:devices];//boxview确定现在frame
    
    
    CGFloat absHeight = _boxView.frame.size.height - boxViewPreHeight;//boxview现在高度差
    
    if (!_showBox) {//box View 未展示
        CGRect myframe = self.frame;
        myframe.size.height += _boxView.frame.size.height;
        self.frame = myframe;
        
        CGRect superViewFrame = self.superview.frame;
        superViewFrame.size.height += _boxView.frame.size.height;
        self.superview.frame = superViewFrame;
        
        
        if ([self.delegate respondsToSelector:@selector(gridView:changeContentHeight:)]) {
            [self.delegate gridView:self changeContentHeight:_boxView.frame.size.height];
        }
    }
    else
    {
        CGRect myframe = self.frame;
        myframe.size.height += absHeight;
        self.frame = myframe;
        
        CGRect superViewFrame = self.superview.frame;
        superViewFrame.size.height += absHeight;
        self.superview.frame = superViewFrame;
        
        if ([self.delegate respondsToSelector:@selector(gridView:changeContentHeight:)]) {
            [self.delegate gridView:self changeContentHeight:absHeight];
        }
    }
    
    
    NSUInteger row = [_rowViewArray indexOfObject:sender.superview];//
    
    
    if (_showBox) {//boxview已经显示
        if (_selectedRow == row) {//当前展示的行与现在点击的是同一行
            [self pointToPosition:sender];
            
            for (NSUInteger i = row+1; i< [_rowViewArray count]; i++) {//下面的行调整高度
                UIView *rowView = [_rowViewArray objectAtIndex:i];
                CGRect frame = rowView.frame;
                frame.origin.y += absHeight;
                rowView.frame = frame;
            }
        }
        else if (_selectedRow > row) {//点击的行在当前展示的行的上面
            
            for (NSUInteger i = row+1; i<= _selectedRow; i++) {//它们之间行向下移
                UIView *rowView = [_rowViewArray objectAtIndex:i];
                CGRect frame = rowView.frame;
                frame.origin.y += _boxView.frame.size.height;
                rowView.frame = frame;
            }
            for (NSUInteger i = _selectedRow+1; i< [_rowViewArray count]; i++) {//当前展示行的下面行调整位置
                UIView *rowView = [_rowViewArray objectAtIndex:i];
                CGRect frame = rowView.frame;
                frame.origin.y += absHeight;
                rowView.frame = frame;
            }
            
            [self pointToPosition:sender];
            
        }
        
        else {//点击的行在当前展示的行的下面
            
            for (NSUInteger i = _selectedRow+1; i<= row; i++) {//它们之间行向上移
                UIView *rowView = [_rowViewArray objectAtIndex:i];
                CGRect frame = rowView.frame;
                frame.origin.y -= boxViewPreHeight;
                rowView.frame = frame;
            }
            
            for (NSUInteger i = row+1; i<[_rowViewArray count]; i++) {//点击行的下面行调整位置
                UIView *rowView = [_rowViewArray objectAtIndex:i];
                CGRect frame = rowView.frame;
                frame.origin.y += absHeight;
                rowView.frame = frame;
            }
            
            [self pointToPosition:sender];
            
        }
    }
    else//boxview未展示在界面
    {
        if (row+1 < [_rowViewArray count]) {//如果不是最后排
            for (NSUInteger i= row+1;i<[_rowViewArray count];i++) {//下面的往下移
                UIView *rowView = [_rowViewArray objectAtIndex:i];
                CGRect frame = rowView.frame;
                frame.origin.y += CGRectGetHeight(_boxView.frame);
                rowView.frame = frame;
            }
        }
        [self pointToPosition:sender];
        
    }
    
    _selectedRow = row;
    _showBox = YES;
    
    
    if ([self.delegate respondsToSelector:@selector(gridView:didSelectItemAtIndex:)]) {
        [self.delegate gridView:self didSelectItemAtIndex:index];
    }
    
}

- (void)pointToPosition:(UIView*)sender
{
    //指向选中的位置
    CGRect frame = _boxView.frame;
    frame.origin.y = CGRectGetMaxY(sender.superview.frame);
    _boxView.frame = frame;
    [_boxView pointToRect:sender.frame];
}

- (void)boxViewPlayVideo:(NSString *)cameraId
{
    if ([self.delegate respondsToSelector:@selector(gridView:playVideo:)]) {
        [self.delegate gridView:self playVideo:cameraId];
    }
}

@end
