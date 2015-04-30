//
//  HomeMsgViewController.m
//  eLife
//
//  Created by mac on 14-4-10.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "HomeMsgViewController.h"
#import "DeviceData.h"
#import "NetAPIClient.h"
#import "EGOImageView.h"
#import "EGOImageButton.h"
#import "HistoryMsgViewController.h"
#import "DBManager.h"
#import "PublicDefine.h"
#import "MessageManager.h"
#import "Util.h"

#define TITLE_HEIGHT 26//标题
#define CONTENT_HEIGHT 50//内容
#define MAGIN_Y 8
#define MAGIN_X 10
#define IMAGE_SIZE 40

#define TAG_BTN 200

#define MAX_DISPLAY_MSGS 5 //最多显示的消息条数

#define BOTTOM_BAR_H 44

@interface LongPressCell : UITableViewCell


@end

@implementation LongPressCell

- (BOOL)canBecomeFirstResponder {
    
    return YES;
    
}

@end

@interface HomeMsgViewController () <UITableViewDataSource,UITableViewDelegate,EGOImageButtonDelegate,EGOImageViewDelegate>
{
//    UITableView *_tblView;
    
    UIView *_bigView;
    
    UIView *_toolBar;
    
    UIView *_actionSheet;
    UIView *_fromView;
    
    NSMutableArray *_dataSource;//用于显示的消息数组
    
    BOOL _actShow;//标识_actionSheet是否显示
}

@end

@implementation HomeMsgViewController
@synthesize msgs;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRcvHomeMsg:) name:MQRecvHomeMsgNotification object:nil];
        
        _dataSource = [NSMutableArray arrayWithCapacity:1];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
//    _tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
//    _tblView.allowsSelection = YES;

    
    [Util unifyStyleOfViewController:self withTitle:@"家庭信息"];
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    
    UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBgd)];
    [self.view addGestureRecognizer:gest];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    //显示消息条数
    if ([self.msgs count]<=MAX_DISPLAY_MSGS) {
        
        [_dataSource addObjectsFromArray:self.msgs];
    }
    else {
        NSRange range = NSMakeRange([self.msgs count]-MAX_DISPLAY_MSGS, MAX_DISPLAY_MSGS);
        NSArray *tempArray = [self.msgs subarrayWithRange:range];
        [_dataSource addObjectsFromArray:tempArray];
    }
    
    
    [self.tableView reloadData];
    
    // set header
    [self createHeaderView];


//    NSTimer *t = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(test) userInfo:nil repeats:YES];
//    
//
//    [t fire];
    

}

- (void)test
{
    HomeMsg *msg = [[HomeMsg alloc] init];
    msg.type = 2;
    [[NSNotificationCenter defaultCenter] postNotificationName:MQRecvHomeMsgNotification object:nil userInfo:[NSDictionary dictionaryWithObject:msg forKey:MQRecvHomeMsgNotificationKey]];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    if (!_toolBar) {
        [self createToolBar];
    }
    

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    

    [self scrollToBottomAnimated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    self.tableView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return TITLE_HEIGHT + CONTENT_HEIGHT +2*MAGIN_Y;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  [_dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    LongPressCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[LongPressCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    for (UIView *v in [cell.contentView subviews]) {
        [v removeFromSuperview];
    }
    
    HomeMsg *tempMsg = [_dataSource objectAtIndex:indexPath.row];

    //背景
    UIView *bgdView = [[UIImageView alloc] initWithFrame:CGRectMake(MAGIN_X, MAGIN_Y, CGRectGetWidth(self.view.frame)-2*MAGIN_X, TITLE_HEIGHT+CONTENT_HEIGHT)];

    bgdView.backgroundColor = [UIColor whiteColor];
    bgdView.layer.cornerRadius = 5;
    bgdView.layer.borderColor = [UIColor colorWithRed:179/255. green:179/255. blue:179/255. alpha:1].CGColor;
    bgdView.layer.borderWidth = 1;
    [cell.contentView addSubview:bgdView];
    bgdView.userInteractionEnabled = YES;
    
    //标题
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 100, TITLE_HEIGHT)];
    titleLbl.text = [self titleForMsg:tempMsg];
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.font = [UIFont boldSystemFontOfSize:16];
    titleLbl.textColor = [UIColor blackColor];
    [bgdView addSubview:titleLbl];
    
    
    //自定义分割线
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(titleLbl.frame), CGRectGetWidth(bgdView.frame), 1)];
    sep.backgroundColor = [UIColor grayColor];
    sep.alpha = 0.2;
    [bgdView addSubview:sep];
    
    //缩略图
    EGOImageView *thumbnail = [[EGOImageView alloc] initWithPlaceholderImage:[UIImage imageNamed:@"home_info.png"] delegate:nil];
    thumbnail.userInteractionEnabled = YES;
    thumbnail.tag = TAG_BTN + indexPath.row;
    thumbnail.frame = CGRectMake(5, TITLE_HEIGHT+(CONTENT_HEIGHT - IMAGE_SIZE)/2, IMAGE_SIZE, IMAGE_SIZE);
    
    //添加点击响应
    UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showBigImage:)];
    [thumbnail addGestureRecognizer:ges];

    thumbnail.imageURL = [NSURL URLWithString:tempMsg.thumbnail];
    [bgdView addSubview:thumbnail];
    
    //内容
    UIFont *contentFont = [UIFont systemFontOfSize:14];
    CGSize textSize = [tempMsg.fullContent sizeWithFont:contentFont constrainedToSize:CGSizeMake(CGRectGetWidth(bgdView.frame) - CGRectGetMaxX(thumbnail.frame)-6*2, CONTENT_HEIGHT)];
    UILabel *contentLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(thumbnail.frame)+10, TITLE_HEIGHT+(CONTENT_HEIGHT-textSize.height)/2, textSize.width, textSize.height)];
    contentLbl.text = tempMsg.fullContent;
    contentLbl.numberOfLines = 0;
    contentLbl.font = contentFont;
    [bgdView addSubview:contentLbl];
    
    //日期
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(bgdView.frame) - 80- 10, 6, 80, 16)];
    dateLabel.text = [self dateStringFrom:tempMsg.time];
    dateLabel.textColor = [UIColor blackColor];
    dateLabel.highlightedTextColor = [UIColor whiteColor];
    dateLabel.backgroundColor = [UIColor clearColor];
    dateLabel.font = [UIFont systemFontOfSize:13];
    [bgdView addSubview:dateLabel];
    
    cell.contentView.backgroundColor = [UIColor colorWithRed:229/255. green:229/255. blue:229/255. alpha:1];
    
    UILongPressGestureRecognizer * longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(cellLongPress:)];
    
    [cell addGestureRecognizer:longPressGesture];
    
    return cell;
    
}

#pragma mark - Private Methods

- (void)swipeRight
{
    [self goBack];
}


-(void)beginToReloadData:(EGORefreshPos)aRefreshPos{
	[super beginToReloadData:aRefreshPos];
    
    if (aRefreshPos == EGORefreshHeader) {
        // pull down to refresh data
        if ([_dataSource count] < [self.msgs count]) {
            
            NSInteger canLoadNumOfMsg = [self.msgs count]- [_dataSource count];
            NSArray *leftArray = [self.msgs subarrayWithRange:NSMakeRange(0, canLoadNumOfMsg)];//剩余可以加载的数据
            
            if (canLoadNumOfMsg<=MAX_DISPLAY_MSGS) {
                // [_dataSource addObjectsFromArray:leftArray];
                NSRange range = NSMakeRange(0, canLoadNumOfMsg);
                [_dataSource insertObjects:leftArray atIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
            }
            else {
                NSRange range = NSMakeRange([leftArray count]-MAX_DISPLAY_MSGS, MAX_DISPLAY_MSGS);
                NSArray *tempArray = [leftArray subarrayWithRange:range];
                
                NSRange insertRange = NSMakeRange(0, MAX_DISPLAY_MSGS);
                [_dataSource insertObjects:tempArray atIndexes:[NSIndexSet indexSetWithIndexesInRange:insertRange]];
                //[_dataSource addObjectsFromArray:tempArray];
            }
            
            [self.tableView reloadData];
            
        }
        else {
            NSLog(@"no more data to load");
        }
        
        [self performSelector:@selector(finishLoadingData) withObject:nil afterDelay:REFRESH_HIDE_DELAY];
    }else if(aRefreshPos == EGORefreshFooter){
        // pull up to load more data
        
    }
}

- (void)finishLoadingData
{
    [self finishReloadingData];
}

- (void)tapBgd
{
    if (_actionSheet) {
        [UIView animateWithDuration:0.15 animations:^{
            [self hideActionSheet];
        }completion:NULL];
    }
}

- (void)createToolBar
{

    _toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame)-BOTTOM_BAR_H, CGRectGetWidth(self.view.frame), BOTTOM_BAR_H)];
    _toolBar.userInteractionEnabled = YES;
    _toolBar.backgroundColor = [UIColor colorWithRed:235/255. green:235/255. blue:235/255. alpha:1];
    _toolBar.autoresizingMask =  UIViewAutoresizingFlexibleTopMargin;
    
    NSInteger width = CGRectGetWidth(self.view.bounds);
    
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 1)];
    sep.backgroundColor = [UIColor grayColor];
    sep.alpha = 0.3;
    [_toolBar addSubview:sep];
    
//    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    leftBtn.frame = CGRectMake(0, 0, 80, toolBarH);
//    [leftBtn setTitle:@"其他" forState:UIControlStateNormal];
//    [leftBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    leftBtn.layer.borderColor = [UIColor grayColor].CGColor;
//    leftBtn.layer.borderWidth = 1.0;
//    [leftBtn addTarget:self action:@selector(clickLeftBtn:) forControlEvents:UIControlEventTouchUpInside];
//    [_toolBar addSubview:leftBtn];
    
    
    
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rightBtn.frame = CGRectMake(0, 0, width, BOTTOM_BAR_H);
    [rightBtn setTitle:@"用户操作" forState:UIControlStateNormal];
    [rightBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(clickRightBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_toolBar addSubview:rightBtn];
    
    [self.view addSubview:_toolBar];
    [self.view bringSubviewToFront:_toolBar];
    
    //    //调整tableview的高度
    //    CGRect f =  _tblView.frame;
    //    f.size.height -= (toolBarH+spacing_y);
    //    _tblView.frame = f;
    
    //调整tableview的高度
    CGRect f =  self.tableView.frame;
    f.size.height -= BOTTOM_BAR_H;
    self.tableView.frame = f;
    self.tableView.backgroundColor = [UIColor colorWithRed:229/255. green:229/255. blue:229/255. alpha:1];
}

- (void)clickLeftBtn:(UIButton *)sender
{
    
}

- (void)clickRightBtn:(UIButton *)sender
{
    if (!_actionSheet) {
        CGRect rct = sender.frame;
        NSInteger height = 90;
        _actionSheet = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(rct), CGRectGetHeight(self.view.frame), CGRectGetWidth(rct), height)];
        _actionSheet.backgroundColor = [UIColor colorWithRed:214/255. green:224/255. blue:234/255. alpha:1];
        
        UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeCustom];
        btn1.frame  = CGRectMake(0, 0, CGRectGetWidth(rct), 30);
        [btn1 setTitle:@"历史消息查看" forState:UIControlStateNormal];
        [btn1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn1 addTarget:self action:@selector(queryHistory) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
        btn2.frame  = CGRectMake(0, 30, CGRectGetWidth(rct), 30);
        [btn2 setTitle:@"消息订阅设置" forState:UIControlStateNormal];
        [btn2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn2 addTarget:self action:@selector(subSetting) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *btn3 = [UIButton buttonWithType:UIButtonTypeCustom];
        btn3.frame  = CGRectMake(0, 60, CGRectGetWidth(rct), 30);
        [btn3 setTitle:@"授权信息查询" forState:UIControlStateNormal];
        [btn3 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn3 addTarget:self action:@selector(queryOther) forControlEvents:UIControlEventTouchUpInside];
        
        [_actionSheet addSubview:btn1];
        [_actionSheet addSubview:btn2];
        [_actionSheet addSubview:btn3];
        [self.view insertSubview:_actionSheet belowSubview:_toolBar];
    }
    
    
    if (!_actShow) {
        [self showActionSheet];
    }
    else {
        [self hideActionSheet];
    }
    
    
}

- (void)cellLongPress:(UIGestureRecognizer *)recognizer{
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        CGPoint location = [recognizer locationInView:self.tableView];
        
        NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:location];
        
        LongPressCell *cell = (LongPressCell *)recognizer.view;
        
        //这里把cell做为第一响应(cell默认是无法成为responder,需要重写canBecomeFirstResponder方法)
        [cell becomeFirstResponder];
        

        UIMenuItem *itDelete = [[UIMenuItem alloc] initWithTitle:@"删除" action:@selector(handleDeleteCell:)];
        
        UIMenuController *menu = [UIMenuController sharedMenuController];
        
        [menu setMenuItems:[NSArray arrayWithObjects: itDelete,  nil]];
        
        CGRect frame = cell.frame;
        frame.size.height += MAGIN_Y;
        
        [menu setTargetRect:frame inView:self.tableView];
        
        [menu setMenuVisible:YES animated:YES];
        
    }
    
}

- (void)handleCopyCell:(id)sender{//复制cell
    
    NSLog(@"handle copy cell");
    
}


- (void)handleDeleteCell:(id)sender{//删除cell
    
    NSLog(@"handle delete cell");
    
}

- (void)goBack
{
    
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)queryHistory
{
    [self hideActionSheet];
    
    HistoryMsgViewController *vc = [[HistoryMsgViewController alloc] initWithNibName:@"HistoryMsgViewController" bundle:nil];
//    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
//    [self presentViewController:vc animated:YES completion:NULL];
    
    [self.navigationController setNavigationBarHidden:YES];
    [self.navigationController pushViewController:vc animated:YES];
    
    
}
- (void)subSetting
{
    
}
- (void)queryOther
{
    
}

- (void)hideActionSheet
{
    [UIView animateWithDuration:0.15 animations:^{
        
        CGRect frame = _actionSheet.frame;
        frame.origin.y = CGRectGetHeight(self.view.frame);
        _actionSheet.frame = frame;
        
    }completion:^(BOOL f){
        if (f) {
            _actShow = NO;
        }
    }];

}

- (void)showActionSheet
{
    [UIView animateWithDuration:0.15 animations:^{
        CGRect frame = _actionSheet.frame;
        frame.origin.y = CGRectGetHeight(self.view.frame) - CGRectGetHeight(frame) -  BOTTOM_BAR_H;
        _actionSheet.frame = frame;
    }completion:^(BOOL f){
        if (f) {
            _actShow = YES;
        }
    }];
}

- (NSString *)dateStringFrom:(int)time
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM-dd HH:mm"];
    NSString *str = nil;
    
    str = [formatter stringFromDate:date];
    
    return str;
}

- (void)showBigImage:(UIGestureRecognizer *)gesture
{
    EGOImageView *tapView = (EGOImageView*)gesture.view;
    NSInteger indx = tapView.tag - TAG_BTN;
    HomeMsg *msg = [_dataSource objectAtIndex:indx];
    

    CGRect fromFrame = [self.view.window convertRect:self.view.window.frame
                                      fromView:tapView];
    
    CGRect rct = [UIScreen mainScreen].bounds;
    UIView *v = [[UIView alloc] initWithFrame:rct];
    v.backgroundColor = [UIColor blackColor];
//    v.alpha = 0.0;
//    v.userInteractionEnabled = YES;
    _bigView = v;
    _bigView.userInteractionEnabled = YES;
    
    const NSInteger imgHeight = 250;
    EGOImageView *imgView = [[EGOImageView alloc] initWithPlaceholderImage:tapView.image delegate:nil];
    imgView.frame = fromFrame;
    imgView.imageURL = [NSURL URLWithString:msg.pic];
    imgView.userInteractionEnabled = YES;
    [v addSubview:imgView];
    
    UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissBigView)];
    [v addGestureRecognizer:ges];
    
    imgView.frame = CGRectMake(0,(CGRectGetHeight(rct)-imgHeight)/2, CGRectGetWidth(self.view.frame), imgHeight);
    [self.view.window addSubview:_bigView];
    
//    [UIView animateWithDuration:0.2 animations:^{
//        _bigView.alpha = 1.0;
//        imgView.frame = CGRectMake(0,(CGRectGetHeight(rct)-imgHeight)/2, CGRectGetWidth(self.view.frame), imgHeight);
//    }
//      }completion:^(BOOL finished){
//         
//     }];
    
}

- (void)dismissBigView
{
    [_bigView removeFromSuperview];
    //_bigView.hidden = YES;
}

- (NSString *)titleForMsg:(HomeMsg *)msg
{
    NSString *str = nil;
    //1:刷卡记录2:对讲记录3:报警记录4:过车记录
    if (msg.type == 1) {
        str = @"门禁刷卡";
    }
    else if (msg.type == 2) {
        str = @"呼叫对讲";
    }
    else if (msg.type == 3) {
        str = @"报警记录";
    }
    else if (msg.type == 4) {
        str = @"过车";
    }
    
    return str;
}

- (void)handleRcvHomeMsg:(NSNotification *)ntf
{
    HomeMsg *msg = [[ntf userInfo] objectForKey:MQRecvHomeMsgNotificationKey];
    if (msg) {

        [[MessageManager getInstance] setHomeMsgRead:msg];
        
        [_dataSource addObject:msg];
        [self.tableView reloadData];
        

        [self scrollToBottomAnimated:YES];
    }
}

- (void)scrollToBottomAnimated:(BOOL)yesOrNo
{
    if ([_dataSource count] > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_dataSource count]-1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:yesOrNo];
    }
}

@end
