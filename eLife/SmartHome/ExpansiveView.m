//
//  ExpansiveView.m
//  eLife
//
//  Created by mac on 14-3-31.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "ExpansiveView.h"
#import "ExpansiveCell.h"

#define MAGIN_X ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 10 : 12)
#define MAGIN_Y ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 8 : 16)

#define HEADER_HEIGHT ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 100)
#define CONTENT_HEIGHT ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 100)

@interface ExpansiveView ()
{
    UIScrollView *_scrlView;
    NSMutableArray *_cellArray;


}

@end

@implementation ExpansiveView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code

        self.autoresizesSubviews = YES;
        _cellArray = [NSMutableArray arrayWithCapacity:1];
        
        _scrlView = [[UIScrollView alloc] initWithFrame:frame];
        _scrlView.showsHorizontalScrollIndicator = NO;
        _scrlView.showsVerticalScrollIndicator = NO;
        _scrlView.backgroundColor = [UIColor clearColor];
        _scrlView.userInteractionEnabled = YES;
        _scrlView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [self addSubview:_scrlView];
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

- (void)layoutSubviews
{

}

- (void)reloadData
{
    NSLog(@"expviw reloadData begin");

    [_cellArray removeAllObjects];
    
    for (UIView * v in [_scrlView subviews]) {
        if ([v isKindOfClass:[ExpansiveCell class]]) {
             [v removeFromSuperview];
        }
    }
    
    //多少行
    NSInteger total = [self.dataSource numberOfRowsInExpansiveView:self];
    
    NSInteger origin_x = (CGRectGetWidth(self.frame) - self.cellWidth)/2;
    NSInteger origin_y = MAGIN_Y;
    
    for (NSUInteger i = 0; i < total; i++) {
        
        //每行的cell
        ExpansiveCell *cell = [self.dataSource expansiveView:self cellForRow:i];
        
        //cell的header 高
        CGFloat headerH = HEADER_HEIGHT;
        if ([self.delegate respondsToSelector:@selector(expansiveView:heightForHeaderAtRow:)]) {
            headerH = [self.delegate expansiveView:self heightForHeaderAtRow:i];
        }
        
        //cell的content高
        CGFloat contentH = CONTENT_HEIGHT;
        if ([self.delegate respondsToSelector:@selector(expansiveView:heightForContentAtRow:)]) {
            contentH = [self.delegate expansiveView:self heightForContentAtRow:i];
        }
        contentH = CGRectGetHeight(cell.contentView.frame);
        
        //计算cell frame
        CGFloat cell_w = CGRectGetWidth(self.frame)-2*origin_x;
        cell.frame = CGRectMake(origin_x, origin_y, cell_w, headerH);
        cell.headerView.frame = CGRectMake(0, 0, cell_w, headerH);
        cell.contentView.frame = CGRectMake(0, headerH, cell_w, contentH);
        cell.contentView.alpha = 0.0;//先隐藏contentview
        
        cell.headerView.delegate = self;
        [_scrlView addSubview:cell];
        
        [_cellArray addObject:cell];
        
        //下一个cell的y坐标
        origin_y += CGRectGetHeight(cell.headerView.frame) + MAGIN_Y;
    }
    
    _scrlView.contentSize = CGSizeMake(CGRectGetWidth(self.frame), origin_y);
    
    NSLog(@"expviw reloadData end");
}

- (void)reloadCellAtRow:(NSUInteger)row
{
    NSLog(@"reloadCellAtRow %d",row);
    
    ExpansiveCell *oldCell = [_cellArray objectAtIndex:row];
    [oldCell removeFromSuperview];
    [_cellArray removeObject:oldCell];
    
    ExpansiveCell *newCell = [self.dataSource expansiveView:self cellForRow:row];
    newCell.headerView.open = oldCell.headerView.open;
  
    CGRect frame = oldCell.frame;

    
    //cell的header 高
    CGFloat headerH = HEADER_HEIGHT;
    if ([self.delegate respondsToSelector:@selector(expansiveView:heightForHeaderAtRow:)]) {
        headerH = [self.delegate expansiveView:self heightForHeaderAtRow:row];
    }
    
    //cell的content高
    CGFloat contentH = CONTENT_HEIGHT;
    if ([self.delegate respondsToSelector:@selector(expansiveView:heightForContentAtRow:)]) {
        contentH = [self.delegate expansiveView:self heightForContentAtRow:row];
    }
    contentH = CGRectGetHeight(newCell.contentView.frame);
    
    //计算cell frame

    CGFloat alp = 0;
    if (newCell.headerView.open) {
        frame.size.height = contentH+headerH;
        alp = 1.0;
    }
    else {
        frame.size.height = headerH;
        alp = 0.0;
    }
   
    newCell.frame = frame;
    newCell.headerView.frame = oldCell.headerView.frame;
    newCell.contentView.frame = CGRectMake(0, headerH, CGRectGetWidth(frame), contentH);
    newCell.contentView.alpha = alp;//先隐藏contentview
    
    newCell.headerView.delegate = self;
    
    [_scrlView addSubview:newCell];

    ExpansiveCell *lastCell = [_cellArray lastObject];
    _scrlView.contentSize = CGSizeMake(CGRectGetWidth(self.frame), CGRectGetMaxY(lastCell.frame));
    
    [_cellArray replaceObjectAtIndex:row withObject:newCell];
}

- (void)tapHeaderView:(HeaderView *)headerView
{
    ExpansiveCell *cell = (ExpansiveCell *)headerView.superview;
    
    //计算cell的高度
    CGFloat h = headerView.open ? (CGRectGetHeight(headerView.frame) + CGRectGetHeight(cell.contentView.frame)) : CGRectGetHeight(headerView.frame);
    CGRect frame = cell.frame;
    NSInteger absHeight = h - frame.size.height;//变化的高度
    frame.size.height = h;
    
    NSUInteger indx = [_cellArray indexOfObject:cell];
    
    
    if (indx != NSNotFound && [self.delegate respondsToSelector:@selector(expansiveView:openHeader:atRow:)]) {
        [self.delegate expansiveView:self openHeader:headerView.open atRow:indx];
    }
    
    //计算_scrlView的contentsize
    ExpansiveCell *tempCell = [_cellArray lastObject];
    CGFloat contentH =  CGRectGetMaxY(tempCell.frame)+absHeight;
    _scrlView.contentSize = CGSizeMake(CGRectGetWidth(self.frame),contentH);
    
    //展开或关闭动画
    [UIView animateWithDuration:0.2 animations:^{
        cell.frame = frame;
        cell.contentView.alpha = headerView.open ? 1.0:0.0;
        
        //下面的cell下移
        for (int i = indx+1; i<[_cellArray count]; i++) {
            ExpansiveCell *cellBelow = [_cellArray objectAtIndex:i];
            CGRect f = cellBelow.frame;
            f.origin.y += absHeight;
            cellBelow.frame = f;
            
        }
        
        //滑动到顶部
        if (headerView.open) {
            
           // [self scrollCellToTop:indx];
        }
        else {
          //  [_scrlView setContentOffset:CGPointMake(0, 0)];
        }
        
        
    }completion:^(BOOL finished){
        if (finished) {

        }
    }];
    

}

- (void)scrollCellToTop:(NSUInteger)row
{
    if (row < [_cellArray count]) {
        ExpansiveCell *cell = [_cellArray objectAtIndex:row];
        CGFloat cellOriginY = CGRectGetMinY(cell.frame);
        [_scrlView setContentOffset:CGPointMake(0, cellOriginY - MAGIN_Y)];
    }
    
}

- (CGSize)contentSize
{
    return _scrlView.contentSize;
}

- (void)resizeContent:(CGSize)contentSize
{
    _scrlView.contentSize = contentSize;
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets
{
    _scrlView.contentInset = contentInsets;
}



@end
