//
//  MessageServiceController.h
//  eLife
//
//  Created by 陈杰 on 14/12/11.
//  Copyright (c) 2014年 mac. All rights reserved.
//


#import "DeviceData.h"
#import "NetAPIClient.h"
#import "Message.h"
#import "DBManager.h"
#import "PublicDefine.h"
#import "MessageManager.h"
#import "EGOImageView.h"
#import "Util.h"
#import "MessageServiceController.h"
#import "PhotoBrowseController.h"
#import "NotificationDefine.h"
#import "HHFullScreenViewController.h"


#define TITLE_HEIGHT 26
//#define CONTENT_HEIGHT 70
#define MAGIN_Y 8
#define MAGIN_X 10
#define IMAGE_SIZE 50

#define TAG_BTN 200

#define MAX_DISPLAY_MSGS 10 //最多显示的消息条数

#define MIN_CONTENT_HEIGHT 70 //内容最小高度


#define CONTENT_FONT_SIZE 14
#define IMAGE_ORIGIN_X 5
#define CONTENT_SPACING_X 5

@interface MessageServiceController () <UITableViewDataSource,UITableViewDelegate>
{
    //    IBOutlet UITableView *_tblView;
    
    NSMutableArray *_dataSource;//用于显示的消息数组
    
    NSMutableArray *_cellHeightArray;//cell高数组
    
    UIView *_bigView;
}

@end

@implementation MessageServiceController
@synthesize  records;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRcvCommMsg:) name:MQRecvCommunityMsgNotification object:nil];
        
        _dataSource = [NSMutableArray arrayWithCapacity:1];
        
        _cellHeightArray = [NSMutableArray arrayWithCapacity:1];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //    _tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //    _tblView.allowsSelection = NO;
    //    _tblView.backgroundColor = [UIColor colorWithRed:235/255. green:235/255. blue:235/255. alpha:1];
    
    [Util unifyStyleOfViewController:self withTitle:@"信息服务"];
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    
    //显示消息条数
    if ([self.records count]<=MAX_DISPLAY_MSGS) {
        [_dataSource addObjectsFromArray:self.records];
    }
    else {
        NSRange range = NSMakeRange([self.records count]-MAX_DISPLAY_MSGS, MAX_DISPLAY_MSGS);
        NSArray *tempArray = [self.records subarrayWithRange:range];
        [_dataSource addObjectsFromArray:tempArray];
    }
    

    // set header
    [self createHeaderView];
    
    self.tableView.backgroundColor = [UIColor colorWithRed:230/255. green:230/255. blue:230/255. alpha:1];
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
}

- (void)swipeRight
{
    [self goBack];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    CommunityMsg *msg = [[CommunityMsg alloc] init];
//    msg.title = @"测试";
//    msg.time = [[NSDate date] timeIntervalSince1970];
//    msg.fullContent = @"测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容测试内容";
//    msg.thumbnail = @"http://e.hiphotos.baidu.com/zhidao/pic/item/242dd42a2834349b273b751bcbea15ce36d3be6a.jpg";
//    msg.pic = @"http://e.hiphotos.baidu.com/zhidao/pic/item/242dd42a2834349b273b751bcbea15ce36d3be6a.jpg";
//    msg.pic = @"http://pic2.52pk.com/files/130529/2429878_102210_7633.jpg";
//    [_dataSource addObject:msg];
//    
//    CommunityMsg *msg1 = [[CommunityMsg alloc] init];
//    msg1.title = @"测试";
//    msg1.time = [[NSDate date] timeIntervalSince1970];
//    msg1.fullContent = @"测试内容测试内容测试内容测试测试内容";
//    msg1.thumbnail = @"http://e.hiphotos.baidu.com/zhidao/pic/item/242dd42a2834349b273b751bcbea15ce36d3be6a.jpg";
//    msg1.pic = @"http://e.hiphotos.baidu.com/zhidao/pic/item/242dd42a2834349b273b751bcbea15ce36d3be6a.jpg";
//    msg1.pic = @"http://pic2.52pk.com/files/130529/2429878_102210_7633.jpg";
//    [_dataSource addObject:msg1];
    
    [self reloadTable];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

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

-(void)beginToReloadData:(EGORefreshPos)aRefreshPos{
    [super beginToReloadData:aRefreshPos];
    
    if (aRefreshPos == EGORefreshHeader) {
        // pull down to refresh data
        if ([_dataSource count] < [self.records count]) {
            
            NSInteger canLoadNumOfMsg = [self.records count]- [_dataSource count];
            NSArray *leftArray = [self.records subarrayWithRange:NSMakeRange(0, canLoadNumOfMsg)];//剩余可以加载的数据
            
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
            
            [self reloadTable];
            
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

- (void)goBack
{
    
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)reloadTable
{
    [_cellHeightArray removeAllObjects];
    

    //先计算内容高度
    NSInteger maxWidth = CGRectGetWidth(self.tableView.bounds)-2*MAGIN_X-IMAGE_ORIGIN_X-IMAGE_SIZE-2*CONTENT_SPACING_X;
    NSInteger maxHeight = CGRectGetHeight(self.tableView.bounds);
    
    for (int i=0; i< [_dataSource count]; i++)
    {
        CommunityMsg *tempMsg = [_dataSource objectAtIndex:i];
        UIFont *font = [UIFont systemFontOfSize:CONTENT_FONT_SIZE];
        CGSize size = [tempMsg.fullContent sizeWithFont:font constrainedToSize:CGSizeMake(maxWidth, maxHeight)];
        if (size.height < MIN_CONTENT_HEIGHT) {
            size.height = MIN_CONTENT_HEIGHT;
        }
        
        CGFloat cellHeight =  TITLE_HEIGHT+size.height +2*MAGIN_Y;
        
        [_cellHeightArray addObject:[NSNumber numberWithFloat:cellHeight]];
    }
    
    
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellH = [[_cellHeightArray objectAtIndex:indexPath.row] floatValue];
    
    return cellH;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  [_dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    for (UIView *v in [cell.contentView subviews]) {
        [v removeFromSuperview];
    }
    
    CommunityMsg *tempMsg = [_dataSource objectAtIndex:indexPath.row];
    CGFloat cellH = [[_cellHeightArray objectAtIndex:indexPath.row] floatValue];
    CGFloat bgdH = cellH-2*MAGIN_Y;
    CGFloat contentH = bgdH-TITLE_HEIGHT;
    
    //背景
    UIView *bgdView = [[UIImageView alloc] initWithFrame:CGRectMake(MAGIN_X, MAGIN_Y, CGRectGetWidth(self.view.frame)-2*MAGIN_X, bgdH)];
    
    bgdView.backgroundColor = [UIColor whiteColor];
    bgdView.layer.cornerRadius = 5;
    bgdView.layer.borderColor = [UIColor colorWithRed:179/255. green:179/255. blue:179/255. alpha:1].CGColor;
    bgdView.layer.borderWidth = 1;
    [cell.contentView addSubview:bgdView];
    bgdView.userInteractionEnabled = YES;
    
    //标题
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, CGRectGetWidth(tableView.bounds)-110, TITLE_HEIGHT)];
    titleLbl.text = tempMsg.title;
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
    EGOImageView *thumbnail = [[EGOImageView alloc] initWithPlaceholderImage:[UIImage imageNamed:@"ServiceMessage"] delegate:nil];
    thumbnail.userInteractionEnabled = YES;
    thumbnail.tag = TAG_BTN + indexPath.row;
    thumbnail.frame = CGRectMake(IMAGE_ORIGIN_X, TITLE_HEIGHT+(contentH - IMAGE_SIZE)/2, IMAGE_SIZE, IMAGE_SIZE);
    
    //添加点击响应
    UITapGestureRecognizer *ges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showBigImage:)];
    [thumbnail addGestureRecognizer:ges];
    
    thumbnail.imageURL = [NSURL URLWithString:tempMsg.thumbnail];
    [bgdView addSubview:thumbnail];
    
    //内容
    UIFont *contentFont = [UIFont systemFontOfSize:CONTENT_FONT_SIZE];
    CGSize textSize = [tempMsg.fullContent sizeWithFont:contentFont constrainedToSize:CGSizeMake(CGRectGetWidth(bgdView.frame) - CGRectGetMaxX(thumbnail.frame)-CONTENT_SPACING_X*2, contentH)];
    UILabel *contentLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(thumbnail.frame)+CONTENT_SPACING_X, TITLE_HEIGHT+(contentH-textSize.height)/2, textSize.width, textSize.height)];
    contentLbl.text = tempMsg.fullContent;
    contentLbl.numberOfLines = 0;
    contentLbl.font = contentFont;
    contentLbl.backgroundColor = [UIColor clearColor];
    [bgdView addSubview:contentLbl];
    
    //日期
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(bgdView.frame) - 80- 10, 0, 80, TITLE_HEIGHT)];
    dateLabel.text = [self dateStringFrom:tempMsg.time];
    dateLabel.textColor = [UIColor blackColor];
    dateLabel.highlightedTextColor = [UIColor whiteColor];
    dateLabel.backgroundColor = [UIColor clearColor];
    dateLabel.font = [UIFont systemFontOfSize:13];
    [bgdView addSubview:dateLabel];
    
    cell.contentView.backgroundColor = [UIColor colorWithRed:230/255. green:230/255. blue:230/255. alpha:1];
    
    
    return cell;
    
}

- (void)dismissBigView
{
    [_bigView removeFromSuperview];
    //_bigView.hidden = YES;
}

- (void)showBigImage:(UIGestureRecognizer *)gesture
{
    EGOImageView *fromView = (EGOImageView*)gesture.view;
    NSInteger indx = fromView.tag - TAG_BTN;
    CommunityMsg *msg = [_dataSource objectAtIndex:indx];

    
    EGOImageView *toView = [[EGOImageView alloc] initWithPlaceholderImage:fromView.image delegate:nil];
    toView.frame = CGRectMake(0, 0, 200, 200);
    toView.placeholderImage = fromView.image;
    toView.imageURL = [NSURL URLWithString:msg.pic];
    toView.userInteractionEnabled = YES;

    
    CGRect frame =[self.view.window convertRect:fromView.frame
                                       fromView:fromView.superview];
    
    PhotoBrowseController *bigView = [[PhotoBrowseController alloc] initWithSuperView:[UIApplication sharedApplication].keyWindow];

    [bigView setFromView:fromView toView:toView originFrame:frame];
    
    [bigView startAnimation];

    
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

- (void)handleRcvCommMsg:(NSNotification *)ntf
{
    CommunityMsg *msg = [[ntf userInfo] objectForKey:MQRecvCommunityMsgNotificationKey];
    
    if (msg) {
        
        [[MessageManager getInstance] setCommMsgRead:msg];
        
        [_dataSource addObject:msg];
        
        [self reloadTable];
        
        
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
