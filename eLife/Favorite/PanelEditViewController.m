//
//  PanelEditViewController.m
//  eLife
//
//  Created by mac mini on 14/10/30.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "PanelEditViewController.h"
#import "FtpShareViewController.h"
#import "NotificationDefine.h"
#import "AppDelegate.h"
#import "BJGridItem.h"
#import "Util.h"
#import "PublicDefine.h"
#import "FtpResourceViewController.h"
#import "NetAPIClient.h"
#import "DBManager.h"
#import "PhotoBrowseController.h"
#import "BigPicBrowseView.h"

#define ITEMS_PERROW 3//每行多少个
#define ITEMS_PERCOL 3//每列多少个

#define SPACING ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 10 : 20)//间隔


typedef NS_ENUM(NSInteger, RAScrollDirction) {
    RAScrollDirctionNone,
    RAScrollDirctionUp,
    RAScrollDirctionDown
};

@interface PanelEditViewController () <BJGridItemDelegate>
{
    NSMutableArray *panelArray;
    
    NSMutableArray *gridItems;

    
    UIButton *addbutton;
    IBOutlet UIScrollView *scrlView;
    
    CGPoint startPoint;
    CGPoint originPoint;
    BOOL contain;
    NSMutableDictionary *config;
    
    BOOL isReorder;
    
    BOOL showAgain;
    
    BOOL moving;

   
    UIEdgeInsets scrollTrigerEdgeInsets;

    RAScrollDirction scrollDirection;
}

@end

@implementation PanelEditViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFtpDownloadNtf:) name:FtpDownloadConfigNotification object:nil];
        
        panelArray = [NSMutableArray arrayWithCapacity:1];
        
        gridItems = [NSMutableArray arrayWithCapacity:1];
        
        config = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    scrollTrigerEdgeInsets = UIEdgeInsetsMake(40, 0, 40, 0);
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    
 
    [Util unifyStyleOfViewController:self withTitle:@"常用管理"];
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    
    UITapGestureRecognizer *singletap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [singletap setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:singletap];
    

    

   
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
  
    if (!showAgain) {
        //绘制panel
        NSDictionary *dic = [[DBManager defaultManager] queryPanelConfig];
        
        [config addEntriesFromDictionary:dic] ;
        
        [self drawItems];
    }

    showAgain = YES;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)swipeRight
{
    [self goBack];
}

- (void)goBack
{
    
//    UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
//    
//    [navController setNavigationBarHidden:YES];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    if (isReorder && [self.delegate respondsToSelector:@selector(panelEditViewControllerReorder)]) {
        [self.delegate performSelector:@selector(panelEditViewControllerReorder)];
    }
    
    
    [self.navigationController popViewControllerAnimated:YES];
    

    
}


- (void)setPanels:(NSArray *)panels
{
    [panelArray addObjectsFromArray:panels];
}


- (void)drawItems
{
    
    
    CGRect r = self.view.frame;
    
    int width = (CGRectGetWidth(self.view.frame)-SPACING*(ITEMS_PERROW+1))/ITEMS_PERROW;
    int height = (CGRectGetHeight(self.view.frame)-SPACING*(ITEMS_PERCOL+1))/ITEMS_PERCOL;
    
    for (NSString *panel in panelArray)
    {
        int index = [self indexForPanel:panel];
  
        if (INVALID_INDEX == index) {
            continue;
        }
        
        int row = index/ITEMS_PERROW;//第几行
        int col = index%ITEMS_PERROW;//第几列
        
        
        CGRect frame = CGRectMake(SPACING+col*(width+SPACING), SPACING+row*(height+SPACING), width, height);
        
        BJGridItem *item = [[BJGridItem alloc] initWithFrame:frame];
        
        [item setTitle:panel image:[self imageForName:panel] index:index removable:YES];

        item.delegate = self;
        [gridItems addObject:item];
        [scrlView addSubview:item];
    }
    
    NSInteger addBtnIndex = [panelArray count];
    
    addbutton = [UIButton buttonWithType:UIButtonTypeCustom];
    //[addbutton setTitle:@"Add" forState:UIControlStateNormal];
    [addbutton setBackgroundImage:[UIImage imageNamed:@"PanelAddBtn"] forState:UIControlStateNormal];
    [addbutton setFrame:CGRectMake(SPACING+(addBtnIndex%ITEMS_PERROW)*(width+SPACING), SPACING+(addBtnIndex/ITEMS_PERROW)*(height+SPACING), width, height)];
    [addbutton addTarget:self action:@selector(addPanel) forControlEvents:UIControlEventTouchUpInside];
    [scrlView addSubview: addbutton];
    

    
    [self setScrollSize];
}


- (UIImage *)imageForName:(NSString *)panelName
{

    NSString *panelDir = [USERDIR stringByAppendingPathComponent:PANEL_DIR];//panel 目录
    
    NSString *configDir = [panelDir stringByAppendingPathComponent:panelName];
    
    NSString *thumbnailPath = [configDir stringByAppendingPathComponent:THUMBNAIL];
    
    UIImage *image = [UIImage imageWithContentsOfFile:thumbnailPath];
    
    if (!image) {
        image = [UIImage imageNamed:@"PanelDefault"];
    }
    
    return image;
}


- (void)endEditing
{
    
    for (BJGridItem *item in gridItems) {
        [item disableEditing];
    }
  
}

- (void)addPanel
{

    [self endEditing];
    

    NSString *nibName = [Util nibNameWithClass:[FtpShareViewController class]];
    
    FtpShareViewController *vc = [[FtpShareViewController alloc] initWithNibName:nibName bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
    
//    if ([User currentUser].isLocalMode)
//    {
//        
//        NSString *nibName = [Util nibNameWithClass:[FtpShareViewController class]];
//        
//        FtpShareViewController *vc = [[FtpShareViewController alloc] initWithNibName:nibName bundle:nil];
//        [self.navigationController pushViewController:vc animated:YES];
//    }
//    else {//远程模式直接进入ftp资源列表
//
//        NSString *nibName = [Util nibNameWithClass:[FtpResourceViewController class]];
//        FtpResourceViewController *viewController = [[FtpResourceViewController alloc] initWithNibName:nibName bundle:nil];
//        
//        [viewController setIp:[NetAPIClient sharedClient].serverAddr port:21 user:@"AppPanel" pswd:@"Zwan!@#abc"];
//        
//        [self.navigationController pushViewController:viewController animated:YES];
//    }

    
    
}




- (void)handleFtpDownloadNtf:(NSNotification *)nft
{
    NSString *panelName = [[nft userInfo] objectForKey:FtpDownloadFileNameKey];
    NSString *filePath = [[nft userInfo] objectForKey:FtpDownloadFilePathKey];
    
    BOOL overwritten = NO;
    
    
    NSArray *names = [config allKeys];
    for (NSString *panel in names) {
        if ([panel isEqualToString:panelName]) {
            overwritten = YES;
            
            NSLog(@"panelName: %@overwritten yes",panelName);
            break;
        }
    }
    
   
    
    if (!overwritten) {
        NSInteger index = [names count];
        
         NSLog(@"handleFtpDownloadNtf %@ panel count %d",panelName,index);
        
        [panelArray addObject:panelName];
        
        [self addItemAtIndex:index name:panelName];
        
        
        [self setIndex:index forPanel:panelName];
  
        
        [self resetAddBtnAtIndex:index+1];
        
        [self setScrollSize];
        

    }

    if ([self.delegate respondsToSelector:@selector(panelEditViewController:downloadFile:path:overwritten:)]) {
        [self.delegate panelEditViewController:self downloadFile:panelName path:filePath  overwritten:overwritten];
    }
    
}


- (int)indexForPanel:(NSString *)panel
{
    NSMutableDictionary *dic = [config objectForKey:panel];
    
    id indexObj = [dic objectForKey:KEY_INDEX];
    if ([indexObj isKindOfClass:[NSNumber class]]) {
        
        return [indexObj intValue];
    }
    
    return INVALID_INDEX;
}

- (void)setIndex:(NSInteger)index forPanel:(NSString *)panel
{
    NSMutableDictionary *dic = [config objectForKey:panel] ;
    
    if (!dic) {
        dic = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    else {
        dic = [NSMutableDictionary dictionaryWithDictionary:dic];
    }
    
    [dic setObject:[NSNumber numberWithInt:index] forKey:KEY_INDEX];
    [config setObject:dic forKey:panel];
    
    [self saveConfig];
}



- (void)saveConfig
{
  
    [[DBManager defaultManager] savePanelConfig:config];
    
//    [[NSUserDefaults standardUserDefaults] setObject:config forKey:PANEL_CONFIG];
}

- (void)addItemAtIndex:(NSInteger)index name:(NSString *)name
{
    int width = (CGRectGetWidth(self.view.frame)-SPACING*(ITEMS_PERROW+1))/ITEMS_PERROW;
    int height = (CGRectGetHeight(self.view.frame)-SPACING*(ITEMS_PERCOL+1))/ITEMS_PERCOL;
    
    int row = index/ITEMS_PERROW;//第几行
    int col = index%ITEMS_PERROW;//第几列
    
    
    CGRect frame = CGRectMake(SPACING+col*(width+SPACING), SPACING+row*(height+SPACING), width, height);
    
    BJGridItem *item = [[BJGridItem alloc] initWithFrame:frame];
    
    [item setTitle:name image:[self imageForName:name] index:index removable:YES];

    item.delegate = self;
    [gridItems addObject:item];
    [scrlView addSubview:item];
}


- (void)resetAddBtnAtIndex:(NSInteger)index
{
    NSLog(@"resetAddBtnAtIndex %d",index);
    
    int width = (CGRectGetWidth(self.view.frame)-SPACING*(ITEMS_PERROW+1))/ITEMS_PERROW;
    int height = (CGRectGetHeight(self.view.frame)-SPACING*(ITEMS_PERCOL+1))/ITEMS_PERCOL;
    
    int row = index/ITEMS_PERROW;//第几行
    int col = index%ITEMS_PERROW;//第几列
    
    
    CGRect frame = CGRectMake(SPACING+col*(width+SPACING), SPACING+row*(height+SPACING), width, height);
    
    [addbutton setFrame:frame];
    

}


- (void)setScrollSize
{
    CGFloat  height = CGRectGetMaxY(addbutton.frame) > CGRectGetHeight(scrlView.frame) ? CGRectGetMaxY(addbutton.frame)+SPACING : CGRectGetHeight(scrlView.frame);
    
    scrlView.contentSize = CGSizeMake(CGRectGetWidth(scrlView.bounds), height);
}

#pragma mark-- BJGridItemDelegate
- (void)gridItemDidClicked:(BJGridItem *)gridItem{
    NSLog(@"grid at index %d did clicked",gridItem.index);
    
    if (gridItem.isEditing) {
         [self endEditing];
    }
    else {
        
        UIImage *img = gridItem.imageView.image;
        
        UIImageView *fromView = gridItem.imageView;
        
        UIImageView *toView = [[UIImageView alloc] initWithImage:img];
        toView.frame = CGRectMake(0, 0, img.size.width, img.size.height);
        toView.userInteractionEnabled = YES;
        
        CGFloat y = scrlView.contentOffset.y + CGRectGetMinY(gridItem.frame);
        CGRect rct = CGRectMake(CGRectGetMinX(gridItem.frame), y, CGRectGetWidth(gridItem.frame), CGRectGetHeight(gridItem.frame));
        
        CGRect frame = [[UIApplication sharedApplication].keyWindow convertRect:fromView.frame fromView:gridItem];
        
        //    BigPicBrowseView *bigView = [[BigPicBrowseView alloc] initWithSuperView:[UIApplication sharedApplication].keyWindow];
        //
        //    [bigView setFromView:fromView originFrame:frame];
        //
        //    [bigView startAnimation];
        
        PhotoBrowseController *bigView = [[PhotoBrowseController alloc] initWithSuperView:[UIApplication sharedApplication].keyWindow];
        
        [bigView setFromView:fromView toView:toView originFrame:frame];
        
        [bigView startAnimation];
    }
   

}

- (void)gridItemDidDeleted:(BJGridItem *)gridItem atIndex:(NSInteger)index{
    NSLog(@"grid at index %d did deleted",gridItem.index);
    

    
    NSInteger tempIndex = [gridItems indexOfObject:gridItem];//gridItem在gridItems数组中的位置
    
    [gridItems removeObject:gridItem];
    
    
    [config removeObjectForKey:gridItem.title];
    
    [self saveConfig];
    
    //删除
    NSString *panelDir = [USERDIR stringByAppendingPathComponent:PANEL_DIR];//panel 目录
    NSString *dirPath = [panelDir stringByAppendingPathComponent:gridItem.title];

    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:dirPath error:&error];
    
    [UIView animateWithDuration:0.15 animations:^{
        
        for (BJGridItem *tempItem in gridItems)
        {
            if (tempItem.index > index) {
                tempItem.index = tempItem.index - 1;
                
                CGRect newFrame = [self frameAtIndex:tempItem.index];
                
                [tempItem setFrame:newFrame];
       
                [self setIndex:tempItem.index forPanel:tempItem.title];
            }
        }
    
        
        NSInteger addBtnIndex = [gridItems count];
        CGRect addBtnFrame = [self frameAtIndex:addBtnIndex];
        [addbutton setFrame:addBtnFrame];
        
    }];
    
    [self setScrollSize];
    
    [gridItem removeFromSuperview];
    gridItem = nil;
    
    if ([self.delegate respondsToSelector:@selector(panelEditViewController:deleteItemAtIndex:)]) {
        [self.delegate panelEditViewController:self deleteItemAtIndex:index];
    }
}
- (void)gridItemDidEnterEditingMode:(BJGridItem *)gridItem withGestureRecognizer:(UILongPressGestureRecognizer *)recognizer {
    
    addbutton.hidden = YES;
    
//    NSLog(@"gridItems count:%d",[gridItems count]);
    for (BJGridItem *item in gridItems) {
        NSLog(@"%d",item.index);
        [item enableEditing];
    }
    //[addbutton enableEditing];

    startPoint = [recognizer locationInView:gridItem];
    
//    NSLog(@"startPoint = %@",NSStringFromCGPoint(startPoint));
    
    originPoint = gridItem.center;
    
    
    [UIView animateWithDuration:0.15 animations:^{
        
        gridItem.transform = CGAffineTransformMakeScale(1.1, 1.1);
//        gridItem.alpha = 0.7;
    }];

}
- (void)gridItemDidMoved:(BJGridItem *)gridItem withLocation:(CGPoint)point moveGestureRecognizer:(UILongPressGestureRecognizer *)recognizer {
    
    CGPoint newPoint = [recognizer locationInView:gridItem];
    
    //CGPoint pointInView = [recognizer locationInView:gridItem];
    CGPoint pointInScrlView = [scrlView convertPoint:point fromView:gridItem];
    
    
    NSLog(@"scrlview contentoffset %@",NSStringFromCGPoint(scrlView.contentOffset));
    if (CGRectGetMaxY(gridItem.frame) + scrollTrigerEdgeInsets.bottom >= scrlView.contentOffset.y + CGRectGetHeight(scrlView.bounds) && scrlView.contentOffset.y + CGRectGetHeight(scrlView.bounds) <= scrlView.contentSize.height) {
        
        
        //滑动方向，与拖动方向相反
        scrollDirection = RAScrollDirctionUp;//往下拖动，scrollview 向上滑
        
        [self autoScroll:gridItem];
    }
    else if (CGRectGetMinY(gridItem.frame) <= scrlView.contentOffset.y + scrollTrigerEdgeInsets.top && CGRectGetMinY(gridItem.frame) > SPACING) {
        scrollDirection = RAScrollDirctionDown;//往上拖动，scrollview 向下滑
        
        [self autoScroll:gridItem];
    }
    
    //    NSLog(@"pointInScrlView = %@",NSStringFromCGPoint(pointInScrlView));
    
    
    CGFloat deltaX = newPoint.x-startPoint.x;
    CGFloat deltaY = newPoint.y-startPoint.y;
    gridItem.center = CGPointMake(gridItem.center.x+deltaX,gridItem.center.y+deltaY);
    //    NSLog(@"center = %@",NSStringFromCGPoint(gridItem.center));
    
    NSInteger toIndex = [self indexOfPoint:gridItem.center withButton:gridItem];
    
    NSLog(@"toindex %d",toIndex);
    
    if (toIndex == INVALID_INDEX)
    {
        contain = NO;
        
        NSLog(@"gridItemDidMoved contain no");
    }
    else
    {
        NSLog(@"gridItemDidMoved contain yes");
        
        
        contain = YES;
        
        isReorder = YES;
        
        BJGridItem *toItem = [gridItems objectAtIndex:toIndex];
        
        
        NSInteger toOrderIndex = toItem.index;
        NSInteger fromOrderIndex = gridItem.index;
        
        originPoint = toItem.center;
        
        
        
        BOOL forward = toOrderIndex < fromOrderIndex ? YES : NO;
        
        
        if (!forward) {//往后
            
            for (BJGridItem *item in gridItems)
            {
                if (item.index >= fromOrderIndex+1 && item.index <= toOrderIndex) {
                    item.index -= 1;
                    
                    [self setIndex:item.index forPanel:item.title];
                    
                    CGRect frame = [self frameAtIndex:item.index];
                    
                    item.frame = frame;
                }
            }
            
        }
        else {//向前
            
            for (BJGridItem *item in gridItems)
            {
                if (item.index >= toOrderIndex && item.index < fromOrderIndex) {
                    item.index += 1;
                    
                    
                    [self setIndex:item.index forPanel:item.title];
                    
                    CGRect frame = [self frameAtIndex:item.index];
                    
                    item.frame = frame;
                }
            }
            
        }
        
        gridItem.index = toOrderIndex;
        
        
        [self setIndex:gridItem.index forPanel:gridItem.title];
        
        moving = NO;
        
        
        
    }
    
}

- (void) gridItemDidEndMoved:(BJGridItem *) gridItem withLocation:(CGPoint)point moveGestureRecognizer:(UILongPressGestureRecognizer*) recognizer {
    
    NSLog(@"gridItemDidEndMoved");

   
    addbutton.hidden = NO;
    
    gridItem.transform = CGAffineTransformIdentity;
    
    gridItem.center = originPoint;
    
    

    
}

- (void) handleSingleTap:(UITapGestureRecognizer *) gestureRecognizer{

    [self endEditing];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if(touch.view != scrlView){
        return NO;
    }else
        return YES;
}

#pragma mark-- private

- (void)autoScroll:(BJGridItem *)item
{
    NSLog(@"autoScroll %d",scrollDirection);
    
    CGPoint contentOffset = scrlView.contentOffset;

    CGSize contentSize = scrlView.contentSize;
    CGSize boundsSize = scrlView.bounds.size;
    CGFloat increment = 0;
    
    if (scrollDirection == RAScrollDirctionUp) {
        CGFloat percentage = (CGRectGetMaxY(item.frame) - contentOffset.y - boundsSize.height - scrollTrigerEdgeInsets.bottom ) / scrollTrigerEdgeInsets.bottom;
        increment = 10 * percentage;
        if (increment >= 10.f) {
            increment = 10.f;
        }
    }
    else if (scrollDirection == RAScrollDirctionDown) {
        CGFloat percentage = (1.f - ((CGRectGetMinY(item.frame) - contentOffset.y ) / scrollTrigerEdgeInsets.top));
        increment = -10.f * percentage;
        if (increment <= -10.f) {
            increment = -10.f;
        }
    }

    [UIView animateWithDuration:.07f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{

        scrlView.contentOffset = CGPointMake(contentOffset.x,contentOffset.y+increment);

    } completion:nil];
}

- (CGRect)frameAtIndex:(NSInteger)index
{
    int width = (CGRectGetWidth(self.view.frame)-SPACING*(ITEMS_PERROW+1))/ITEMS_PERROW;
    int height = (CGRectGetHeight(self.view.frame)-SPACING*(ITEMS_PERCOL+1))/ITEMS_PERCOL;
    
    int row = index/ITEMS_PERROW;//第几行
    int col = index%ITEMS_PERROW;//第几列
    
    
    CGRect frame = CGRectMake(SPACING+col*(width+SPACING), SPACING+row*(height+SPACING), width, height);
    
    return frame;
}


- (NSInteger)indexOfLocation:(CGPoint)location{
    NSInteger index;
    
    int gridWith = (CGRectGetWidth(self.view.frame)-SPACING*(ITEMS_PERROW+1))/ITEMS_PERROW;
    int gridHight = (CGRectGetHeight(self.view.frame)-SPACING*(ITEMS_PERCOL+1))/ITEMS_PERCOL;

    NSInteger row =  location.y / (gridHight + 20);
    NSInteger col = location.x  / (gridWith + 20);
    
    NSInteger rows = CGRectGetMaxY(addbutton.frame)/(gridHight+SPACING);
    
    if (row >= rows || col >= ITEMS_PERROW) {
        return  INVALID_INDEX;
    }
    
    index =  row * ITEMS_PERROW + col;
    if (index >= [gridItems count]) {
        return  INVALID_INDEX;
    }
    
    return index;
}


- (NSInteger)indexOfPoint:(CGPoint)point withButton:(BJGridItem *)btn
{
    for (NSInteger i = 0;i<gridItems.count;i++)
    {
        BJGridItem *button = gridItems[i];
        if (button != btn)
        {
            if (CGRectContainsPoint(button.frame, point))
            {
                return i;
            }
        }
    }
    return INVALID_INDEX;
}




- (BJGridItem *)itemAtOrderIndex:(NSInteger)index
{
    for (BJGridItem *item in gridItems)
    {
        if (item.index == index) {
            return item;
        }
    }
    
    return nil;
}




@end
