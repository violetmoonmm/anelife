//
//  AlarmRecordViewController.m
//  eLife
//
//  Created by mac on 14-4-10.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "PropertyMsgViewController.h"
#import "DeviceData.h"
#import "NetAPIClient.h"
#import "Message.h"
#import "DBManager.h"
#import "PublicDefine.h"
#import "MessageManager.h"
#import "EGOImageView.h"
#import "Util.h"

#define TITLE_HEIGHT 26
#define CONTENT_HEIGHT 70
#define MAGIN_Y 8
#define MAGIN_X 10
#define IMAGE_SIZE 40

#define TAG_BTN 200

#define MAX_DISPLAY_MSGS 5 //最多显示的消息条数

@interface PropertyMsgViewController () <UITableViewDataSource,UITableViewDelegate>
{
//    IBOutlet UITableView *_tblView;
    
    NSMutableArray *_dataSource;//用于显示的消息数组
    
    UIView *_bigView;
}

@end

@implementation PropertyMsgViewController
@synthesize  records;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRcvPropertyMsg:) name:MQRecvPropertyMsgNotification object:nil];
        
        _dataSource = [NSMutableArray arrayWithCapacity:1];
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
    
    [Util unifyStyleOfViewController:self withTitle:@"物业信息"];
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
    
    [self.tableView reloadData];
    
    // set header
    [self createHeaderView];
    
    self.tableView.backgroundColor = [UIColor colorWithRed:229/255. green:229/255. blue:229/255. alpha:1];
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
}

- (void)swipeRight
{
    [self goBack:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
    
    
    [self scrollToBottomAnimated:NO];
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

- (void)goBack:(UIButton *)sender
{
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return TITLE_HEIGHT+CONTENT_HEIGHT +2*MAGIN_Y;
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
    titleLbl.text = @"物业消息";
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
    EGOImageView *thumbnail = [[EGOImageView alloc] initWithPlaceholderImage:[UIImage imageNamed:@"property.png"] delegate:nil];
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
    
    
    return cell;
    
}

- (void)dismissBigView
{
    [_bigView removeFromSuperview];
    //_bigView.hidden = YES;
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

- (NSString *)dateStringFrom:(int)time
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM-dd HH:mm"];
    NSString *str = nil;
    
    str = [formatter stringFromDate:date];
    
    return str;
}

- (void)handleRcvPropertyMsg:(NSNotification *)ntf
{
    PropertyMsg *msg = [[ntf userInfo] objectForKey:MQRecvPropertyMsgNotificationKey];
    
    if (msg) {
        
        [[MessageManager getInstance] setPropertyMsgRead:msg];
        
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
