//
//  AlarmRecordViewController.m
//  eLife
//
//  Created by mac on 14-4-10.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "AlarmRecordViewController.h"
#import "DeviceData.h"
#import "NetAPIClient.h"
#import "Message.h"
#import "DBManager.h"
#import "PublicDefine.h"
#import "MessageManager.h"
#import "Util.h"
#import "SHLocalControl.h"

#define TITLE_HEIGHT 26
#define CONTENT_HEIGHT 50
#define MAGIN_Y 8
#define MAGIN_X 10
#define IMAGE_SIZE 40

#define MAX_DISPLAY_MSGS 5 //最多显示的消息条数

@interface AlarmRecordViewController () <UITableViewDataSource,UITableViewDelegate>
{
//    IBOutlet UITableView *_tblView;
    
    NSMutableArray *_dataSource;//用于显示的消息数组
}

@end

@implementation AlarmRecordViewController
@synthesize  records;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRcvAlarmMsg:) name:OnAlarmNotification object:nil];
        
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
    

    [Util unifyStyleOfViewController:self withTitle:@"报警记录"];
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
    [self goBack];
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

- (void)goBack
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
    
    AlarmRecord *tempMsg = [_dataSource objectAtIndex:indexPath.row];
    
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
    titleLbl.text = tempMsg.alarmType;
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.font = [UIFont boldSystemFontOfSize:16];
    titleLbl.textColor = [UIColor blackColor];
    [bgdView addSubview:titleLbl];
    
    
    //自定义分割线
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(titleLbl.frame), CGRectGetWidth(bgdView.frame), 1)];
    sep.backgroundColor = [UIColor grayColor];
    sep.alpha = 0.2;
    [bgdView addSubview:sep];


    //图片
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(5, TITLE_HEIGHT+(CONTENT_HEIGHT - IMAGE_SIZE)/2, IMAGE_SIZE, IMAGE_SIZE)];
    imgView.image = [UIImage imageNamed:@"alarm.png"];
    [bgdView addSubview:imgView];
    
    UIFont *contentFont = [UIFont systemFontOfSize:14];
//    NSString *contentStr = [NSString stringWithFormat:@"地址:%@ 设备:%@ 发生报警",tempMsg.areaAddr,tempMsg.deviceName];
    NSString *contentStr = tempMsg.fullContent;
    CGSize textSize = [contentStr sizeWithFont:contentFont constrainedToSize:CGSizeMake(CGRectGetWidth(bgdView.frame) - CGRectGetMaxX(imgView.frame)-6*2, CONTENT_HEIGHT)];
    UILabel *contentLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(imgView.frame)+6, TITLE_HEIGHT+(CONTENT_HEIGHT-textSize.height)/2, textSize.width, textSize.height)];
    contentLbl.text = contentStr;
    contentLbl.numberOfLines = 0;
    contentLbl.font = contentFont;
    [bgdView addSubview:contentLbl];
    
    //日期
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(bgdView.frame) - 80- 10, 6, 80, 16)];
    dateLabel.text = [self dateStringFrom:tempMsg.alarmTime];
    dateLabel.textColor = [UIColor blackColor];
    dateLabel.highlightedTextColor = [UIColor whiteColor];
    dateLabel.backgroundColor = [UIColor clearColor];
    dateLabel.font = [UIFont systemFontOfSize:13];
    [bgdView addSubview:dateLabel];
    
    cell.contentView.backgroundColor = [UIColor colorWithRed:229/255. green:229/255. blue:229/255. alpha:1];
    
    return cell;
    
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

- (void)handleRcvAlarmMsg:(NSNotification *)ntf
{
    AlarmRecord *msg = [[ntf userInfo] objectForKey:OnAlarmNotificationKey];
    
    if (msg) {

        [[MessageManager getInstance] setAlarmMsgRead:msg];
        
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
