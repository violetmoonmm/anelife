//
//  AlarmServiceController.m
//  eLife
//
//  Created by 陈杰 on 14/12/11.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "AlarmServiceController.h"
#import "DeviceData.h"
#import "NetAPIClient.h"
#import "Message.h"
#import "DBManager.h"
#import "PublicDefine.h"
#import "MessageManager.h"
#import "Util.h"
#import "NotificationDefine.h"


#define CELL_H 60

#define MAX_DISPLAY_MSGS 10 //最多显示的消息条数

@interface AlarmServiceController () <UITableViewDataSource,UITableViewDelegate>
{
    //    IBOutlet UITableView *_tblView;
    
    NSMutableArray *_dataSource;//用于显示的消息数组
}

@end

@implementation AlarmServiceController
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
    
    
    [Util unifyStyleOfViewController:self withTitle:@"报警服务"];
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
    return CELL_H;
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
    
    AlarmRecord *record = [_dataSource objectAtIndex:indexPath.row];
 
    NSInteger iconWidth = 20;
    NSInteger iconHeight = 20;
    NSInteger originX = 8;
    NSInteger labelSpacingX = 6;
    
    //图标
    UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake(originX, (CELL_H-iconHeight)/2, iconWidth, iconHeight)];
    icon.image = [UIImage imageNamed:@"AlarmIcon"];
    [cell.contentView addSubview:icon];
    
    
    //日期
    NSString *strDate = [self dateStringFrom:record.alarmTime];
    UIFont *dateFont = [UIFont systemFontOfSize:13];
    CGSize dateSize = [strDate sizeWithFont:dateFont constrainedToSize:CGSizeMake(CGRectGetWidth(tableView.bounds)-CGRectGetMaxX(icon.frame)-labelSpacingX, iconHeight)];

    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(icon.frame)+labelSpacingX, 6, dateSize.width, dateSize.height)];
    dateLabel.text = strDate;
    dateLabel.textColor = [UIColor blackColor];
    dateLabel.highlightedTextColor = [UIColor whiteColor];
    dateLabel.backgroundColor = [UIColor clearColor];
    dateLabel.font = dateFont;
    [cell.contentView addSubview:dateLabel];
    
    //内容
    UIFont *contentFont = [UIFont systemFontOfSize:14];

    NSString *state = [record.alarmStatus  isEqualToString:@"Start"]? @"发生" : @"恢复";
    
    NSString *alarmAddr = record.channelName ? record.channelName : [NSString stringWithFormat:@"通道%@",record.channelId];
    NSString *alarmType = record.alarmType ? record.alarmType : @"";
    NSString *content = [NSString stringWithFormat:@"%@%@%@报警",alarmAddr,state,alarmType];
    
    CGSize textSize = [content sizeWithFont:contentFont constrainedToSize:CGSizeMake(CGRectGetWidth(tableView.bounds)-CGRectGetMaxX(icon.frame)-labelSpacingX, iconHeight)];
    UILabel *contentLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(icon.frame)+labelSpacingX, CGRectGetMaxY(dateLabel.frame)+10, textSize.width, textSize.height)];
    contentLbl.text = content;
    contentLbl.font = contentFont;
    contentLbl.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:contentLbl];
    

    //自定义分割线
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, CELL_H-1, CGRectGetWidth(tableView.frame), 1)];
    sep.backgroundColor = [UIColor grayColor];
    sep.alpha = 0.2;
    [cell.contentView addSubview:sep];
    
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
