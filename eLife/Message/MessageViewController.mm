//
//  MessageViewController.m
//  eLife
//
//  Created by mac on 14-3-15.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "MessageViewController.h"
#import "AppDelegate.h"
#import "CustomTabBarController.h"
#import "NetAPIClient.h"
#import "HomeMsgViewController.h"
#import "DBManager.h"
#import "AlarmRecordViewController.h"
#import "PropertyMsgViewController.h"
#import "CommunityMsgViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "HistoryMsgViewController.h"
#import "DotView.h"
#import "UIBadgeView.h"
#import "JSBadgeView.h"
#import "FriendsViewController.h"
#import "MessageManager.h"
#import "User.h"
#import "MBProgressHUD.h"
#import "PublicDefine.h"
#import "Util.h"

#define CELL_HEIGHT     ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 61 : 130)
#define IMG_HEIGHT ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 44 : 80)
#define IMG_WIDTH IMG_HEIGHT
#define DATE_WIDTH ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 80 : 140)




static void SoundFinished(SystemSoundID soundID,void* clientData){
    /*播放全部结束，因此释放所有资源 */
    AudioServicesDisposeSystemSoundID(soundID);

}

@interface MessageViewController ()
{
    SystemSoundID soundID;

    BOOL networkUnreachable;
}

@end

@implementation MessageViewController


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
        //家庭信息通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleHomeMsgNtf:) name:MQRecvHomeMsgNotification object:nil];
        
        //收到留影留言消息通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLeaveMsgNtf:) name:MQRecvLeaveMsgNotification object:nil];
        
//        //报警信息通知
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAlarmMsgNtf:) name:MQRecvAlarmNotification object:nil];
        
        //社区信息通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCommMsgNtf:) name:MQRecvCommunityMsgNotification object:nil];
        
        //物业信息通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePropertyMsgNtf:) name:MQRecvPropertyMsgNotification object:nil];
        
        //添加留影留言通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAddLocalLeaveMsg:) name:LocalAddLeaveMsgNotification object:nil];


//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleQuaryCommMsgNtf:) name:QuaryCommunityMsgNotification object:nil];
//        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleQuaryPropertyMsgNtf:) name:QuaryPropertyMsgNotification object:nil];
        
        NSLog(@"messageview initWithNibName");
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    

    [Util unifyStyleOfViewController:self withTitle:@"信息服务"];
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];

    
    if (![User currentUser].isLocalMode) {
        //MessageManager开始处理用户消息
        [[MessageManager getInstance] dealWithUserMessage];
    }

    [self.tableView reloadData];

    if (![self isLastVersion]) {
        [(CustomTabBarController *)((AppDelegate *)[UIApplication sharedApplication].delegate).tabBarController displayTrackPoint:YES atIndex:3];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
     [self.tableView reloadData];

    [self showTotalUnreadMsgNum];
    
   
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //CustomTabBarView *t = ((AppDelegate *)[UIApplication sharedApplication].delegate).tabBarController.customTabBar;
    //NSLog(@"%@",NSStringFromCGRect(t.frame));
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
   
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
    
    AudioServicesRemoveSystemSoundCompletion(soundID);
}

#pragma - Private Methods

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showTotalUnreadMsgNum
{

//    NSString *badgeString = [NSString stringWithFormat:@"%d",[[MessageManager getInstance] totalUnreadMsgNum]];
//    [((AppDelegate *)[UIApplication sharedApplication].delegate).tabBarController setBadgeValue:badgeString atIndex:0];
}

- (BOOL)isLastVersion
{
    if (![NetAPIClient sharedClient].versionInfo.versionName) {
        return YES;
    }
    
    return [[NetAPIClient sharedClient].versionInfo.versionName isEqualToString:CLIENT_VERSION];
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

#pragma mark - Notification Handle


- (void)handleHomeMsgNtf:(NSNotification *)ntf
{
    HomeMsg *msg = [[ntf userInfo] objectForKey:MQRecvHomeMsgNotificationKey];
    
    if (msg) {
        
        if (msg.type != 2) {//呼叫转移播放其它声音
            [self playMsgSound];
        }
        
        [self showTotalUnreadMsgNum];
        [self.tableView reloadData];
    }

}

- (void)handleLeaveMsgNtf:(NSNotification *)ntf
{
    LeaveMsg *msg = [[ntf userInfo] objectForKey:MQRecvLeaveMsgNotificationKey];
    
    if (msg) {
        
        [self playMsgSound];
        
        [self showTotalUnreadMsgNum];
        [self.tableView reloadData];
    }
}

- (void)handleAddLocalLeaveMsg:(NSNotification *)ntf
{
    NSLog(@"message view recv local msg");
    
    [self.tableView reloadData];
    
}

- (void)handleGetGatewaysNtf
{
    
}

//- (void)handleAlarmMsgNtf:(NSNotification *)ntf
//{
//    AlarmRecord *msg = [[ntf userInfo] objectForKey:MQRecvAlarmNotificationKey];
//    
//    if (msg) {
//        
////        [self playMsgSound];
//        
//        [self showTotalUnreadMsgNum];
//        [self.tableView reloadData];
//    }
//
//}

- (void)handlePropertyMsgNtf:(NSNotification *)ntf
{
    PropertyMsg *msg = [[ntf userInfo] objectForKey:MQRecvPropertyMsgNotificationKey];
    
    if (msg) {
        
        [self playMsgSound];
        
        [self showTotalUnreadMsgNum];
        [self.tableView reloadData];
    }
 
}

- (void)handleCommMsgNtf:(NSNotification *)ntf
{
    CommunityMsg *msg = [[ntf userInfo] objectForKey:MQRecvCommunityMsgNotificationKey];
    
    if (msg) {
        [self playMsgSound];
        
        [self showTotalUnreadMsgNum];
        [self.tableView reloadData];
    }
    
}

- (void)handleQuaryCommMsgNtf:(NSNotification *)ntf
{
    [self.tableView reloadData];
}

- (void)handleQuaryPropertyMsgNtf:(NSNotification *)ntf
{
    [self.tableView reloadData];
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MessageCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    //UITableViewCell复用的时候，先移除content的子view，避免重叠
    for (UIView *v in [cell.contentView subviews])
    {
        [v removeFromSuperview];
    }
    
    NSString *imgName = nil;
    NSString *titleTxt = nil;
    NSString *detailTxt = nil;
    NSString *strDate = nil;
    NSInteger unreadMsgNum = 0;

    switch (indexPath.row) {
        case 0:
        {
            NSArray *homeMsgs = [[MessageManager getInstance] homeMsgArray];
            if ([homeMsgs count] > 0) {
                HomeMsg *msg = [homeMsgs lastObject];

                unreadMsgNum = [[MessageManager getInstance] unreadHomeMsgNum];
                
                strDate = [self dateStringFrom:msg.time];
                
                detailTxt = msg.fullContent;
            }
            
            imgName = @"home_info";
            titleTxt = @"家庭信息";
        }

         
            break;
            
            case 1:
        {
            imgName = @"microphone.png";
            
            titleTxt = @"家庭留言";
           
            
            NSArray *leaveMsgs = [[MessageManager getInstance] leaveMsgArray];
            if ([leaveMsgs count] > 0) {
                LeaveMsg *msg = [leaveMsgs lastObject];

                unreadMsgNum = [[MessageManager getInstance] unreadLeaveMsgNum];
                
                strDate = [self dateStringFrom:msg.sendTime];
                
                
                if (msg.type == 1) {
                     detailTxt = msg.fullContent;
                }
                else if (msg.type == 2) {
                    detailTxt = @"[图片]";
                }
                else if (msg.type == 20) {
                    detailTxt = @"[语音]";
                }

            }
        }

            break;
            
            case 2:
        {
            NSArray *alarmRecords = [[MessageManager getInstance] alarmMsgArray];
            if ([alarmRecords count] > 0) {
                AlarmRecord *record = [alarmRecords lastObject];
 
                unreadMsgNum = [[MessageManager getInstance] unreadAlarmMsgNum];
                strDate = [self dateStringFrom:record.alarmTime];
                
                detailTxt = [NSString stringWithFormat:@"%@",record.fullContent];
                
            }
            
            imgName = @"alarm.png";
            titleTxt = @"家庭报警";
        }

   
             break;
            
            case 3:
        {
            NSArray *propertyMsgs = [[MessageManager getInstance] propertyMsgArray];
            if ([propertyMsgs count] > 0) {
                PropertyMsg *msg = [propertyMsgs lastObject];
                strDate = [self dateStringFrom:msg.time];
                unreadMsgNum = [[MessageManager getInstance] unreadPropertyMsgNum];
                detailTxt = msg.fullContent;
            }
            
            imgName = @"property.png";
            titleTxt = @"物业信息";
            
        }

             break;
            
            case 4:
        {
            NSArray *commMsgs = [[MessageManager getInstance] commMsgArray];
            if ([commMsgs count] > 0) {
                CommunityMsg *msg = [commMsgs lastObject];
                unreadMsgNum = [[MessageManager getInstance] unreadCommMsgNum];
                strDate = [self dateStringFrom:msg.time];
                
                detailTxt = msg.fullContent;
            }
            
            imgName = @"community.png";
            titleTxt = @"公共信息";
        }

             break;
            
            case 5:
            imgName = @"setting.png";
            titleTxt = @"系统信息";
            detailTxt = @"";
             break;
            
        default:
            break;
    }
    
    //图标
    NSInteger imgOriginX = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 10 : 20);
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(imgOriginX, (CELL_HEIGHT-IMG_HEIGHT)/2, IMG_WIDTH, IMG_HEIGHT)];
    imgView.image = [UIImage imageNamed:imgName];
    [cell.contentView addSubview:imgView];
    
    const int rDateEdge = 4;//日期label距屏幕右边缘的距离
    const int lTxtEdge = 10;//文字label距图标距离
    NSInteger cellWidth = CGRectGetWidth(self.view.frame);
    
    //信息类型名
    NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 18 : 20);
    CGSize size = [titleTxt sizeWithFont:[UIFont boldSystemFontOfSize:fontSize] constrainedToSize:CGSizeMake(200, 30)];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(imgView.frame)+lTxtEdge, CGRectGetMinY(imgView.frame), size.width, size.height)];
    titleLabel.text = titleTxt;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.highlightedTextColor = [UIColor whiteColor];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:fontSize];
    [cell.contentView addSubview:titleLabel];
    
    //最近一条信息内容
    NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 4 : 18);
    fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 12 : 18);
    size = [detailTxt sizeWithFont:[UIFont systemFontOfSize:fontSize] constrainedToSize:CGSizeMake(cellWidth-CGRectGetMinX(titleLabel.frame), 24)];
    UILabel *detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(titleLabel.frame), CGRectGetMaxY(titleLabel.frame)+spacingY, size.width, size.height)];
    detailLabel.text = detailTxt;
    detailLabel.textColor = [UIColor blackColor];
    detailLabel.highlightedTextColor = [UIColor whiteColor];
    detailLabel.backgroundColor = [UIColor clearColor];
    detailLabel.font = [UIFont systemFontOfSize:fontSize];
    [cell.contentView addSubview:detailLabel];
    
    //最近一条信息时间
    fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 13 : 18);
    size = [strDate sizeWithFont:[UIFont systemFontOfSize:fontSize] constrainedToSize:CGSizeMake(DATE_WIDTH, 30)];
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(cellWidth - DATE_WIDTH - rDateEdge, CGRectGetMinY(titleLabel.frame), DATE_WIDTH, size.height)];
    dateLabel.text = strDate;
    dateLabel.textColor = [UIColor blackColor];
    dateLabel.highlightedTextColor = [UIColor whiteColor];
    dateLabel.backgroundColor = [UIColor clearColor];
    dateLabel.font = [UIFont systemFontOfSize:fontSize];
    [cell.contentView addSubview:dateLabel];
    
    //显示未读消息数
    if (unreadMsgNum > 0) {
        JSBadgeView *badgeView = [[JSBadgeView alloc] initWithParentView:imgView alignment:JSBadgeViewAlignmentTopRight];

        badgeView.badgeText = [NSString stringWithFormat:@"%d",unreadMsgNum];

    }

    
    //自定义分割线
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, CELL_HEIGHT - 1, cellWidth, 1)];
    sep.backgroundColor = [UIColor grayColor];
    sep.alpha = 0.3;
    [cell.contentView addSubview:sep];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIViewController *detailVC = nil;
    switch (indexPath.row) {
        case 0:
            detailVC = [[HomeMsgViewController alloc] initWithNibName:@"HomeMsgViewController" bundle:nil];
            ((HomeMsgViewController*)detailVC).msgs = [[MessageManager getInstance] homeMsgArray];
            

            [[MessageManager getInstance] setAllHomeMsgRead];
            
            break;
        case 1:

            detailVC = [[FriendsViewController alloc] initWithNibName:@"FriendsViewController" bundle:nil];
            ((FriendsViewController*)detailVC).msgArray = [[MessageManager getInstance] leaveMsgArray];

            break;
        case 2:
            detailVC = [[AlarmRecordViewController alloc] initWithNibName:@"AlarmRecordViewController" bundle:nil];
            ((AlarmRecordViewController*)detailVC).records = [[MessageManager getInstance] alarmMsgArray];

            [[MessageManager getInstance] setAllAlarmMsgRead];
            break;
        case 3:
            detailVC = [[PropertyMsgViewController alloc] initWithNibName:@"PropertyMsgViewController" bundle:nil];
            ((PropertyMsgViewController*)detailVC).records = [[MessageManager getInstance] propertyMsgArray];
            
            [[MessageManager getInstance] setAllPropertyMsgRead];
            
            break;
        case 4:
            detailVC = [[CommunityMsgViewController alloc] initWithNibName:@"CommunityMsgViewController" bundle:nil];
            ((CommunityMsgViewController*)detailVC).records = [[MessageManager getInstance] commMsgArray];

            [[MessageManager getInstance] setAllPropertyMsgRead];
            break;
        case 5:
//            detailVC = [[HistoryMsgViewController alloc] initWithNibName:@"HistoryMsgViewController" bundle:nil];

            break;
            
        default:
            break;
    }
    
    if (detailVC) {

//        UINavigationController *navController = ((AppDelegate*)[UIApplication sharedApplication].delegate).mainNavController;
//        
//        [navController setNavigationBarHidden:NO];
        [self.navigationController pushViewController:detailVC animated:YES];
        
    }
    
}


#pragma mark Play Sound
- (void)playMsgSound
{

     AudioServicesPlaySystemSound(1007);
}


@end
