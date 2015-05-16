//
//  AlarmViewController.m
//  eLife
//
//  Created by 陈杰 on 14/11/22.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "AlarmViewController.h"
#import "VideoWnd.h"
#import "Util.h"
#import "zw_dssdk.h"
#import "Message.h"
#import "NotificationDefine.h"
#import "User.h"
#import "NetReachability.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"


static float cellHeight = 44;

@interface AlarmViewController () <UITableViewDataSource,UITabBarDelegate>
{
    IBOutlet UITableView *tblView;
    IBOutlet VideoWnd *videoWnd;
    IBOutlet UIButton *playBtn;//视频播放按钮
    
  
    NSInteger selectedIndex;
}

@end

@implementation AlarmViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
  
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAlarmNtf:)
                                                     name:OnAlarmNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    selectedIndex = 0;
    
    [Util unifyStyleOfViewController:self withTitle:@"家庭报警"];
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
//    record.msgStatus = MessageStatusRead;
    

    if (([NetReachability isReachableViaWWAN] && [User currentUser].alarmVideo == AVSEnableViaWifi)
        || [User currentUser].alarmVideo == AVSEnableVideo) {
        
        AlarmRecord *record = [self.alarmRecords objectAtIndex:0];
        [self playVideoWithRecord:record];
        
    }

    
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

- (void)goBack
{
    
#ifndef INVALID_VIDEO
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
#endif
    
    [(AppDelegate *)[UIApplication sharedApplication].delegate dismissAlarmView];
    
//    [self.navigationController.view removeFromSuperview];

}

- (void)appDidEnterBackground:(NSNotification*)ntf
{

    [self stopPlaying];
}





- (void)handleAlarmNtf:(NSNotification *)ntf
{
    AlarmRecord *record = [[ntf userInfo] objectForKey:OnAlarmNotificationKey];
    
    if ([record.alarmStatus isEqualToString:@"Start"]) {
        [self.alarmRecords insertObject:record atIndex:0];
        
        selectedIndex++;
        
        [tblView reloadData];
    }
//    else {
//        NSString *state = @"恢复";
//        
//        NSString *alarmAddr = alarmInfo.channelName ? alarmInfo.channelName : [NSString stringWithFormat:@"通道%@",alarmInfo.channelId];
//        
//        NSString *content = [NSString stringWithFormat:@"%@%@%@报警",alarmAddr,state,alarmInfo.alarmType];
//        
//        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
//        
//        hud.removeFromSuperViewOnHide = YES;
//        hud.labelText = content;
//        hud.mode = MBProgressHUDModeText;
//        [[UIApplication sharedApplication].keyWindow addSubview:hud];
//        
//        [hud show:YES];
//        [hud hide:YES afterDelay:2.0];
//    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return cellHeight;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return [self.alarmRecords count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"AlarmTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    // Configure the cell...
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    
    for (UIView *v in cell.contentView.subviews)
    {
        [v removeFromSuperview];
    }
    
    AlarmRecord *record = [self.alarmRecords objectAtIndex:indexPath.row];
    
    NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM/dd, HH:mm:ss, "];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:record.alarmTime];
    NSString *strDate = [formatter stringFromDate:date];
    
    NSString *state =  @"发生" ;
    
    NSString *alarmAddr = record.channelName ? record.channelName : [NSString stringWithFormat:@"通道%@",record.channelId];
    NSString *alarmType = record.alarmType ? record.alarmType : @"";
    NSString *content = [NSString stringWithFormat:@"%@%@%@报警",alarmAddr,state,alarmType];
    
    NSString *text = [NSString stringWithFormat:@"%@%@",strDate,content];
    
    NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 14 : 16);
    
    NSInteger wid = 31;//new图标宽度
    
    CGSize textSize = [text sizeWithFont:[UIFont systemFontOfSize:fontSize] constrainedToSize:CGSizeMake(CGRectGetWidth(tableView.frame)-10-wid-4, cellHeight)];
    
    UIColor *color = nil;
    if (selectedIndex == indexPath.row) {
        color = [UIColor colorWithRed:220/255. green:70/255. blue:7/255. alpha:1];
    }
    else if (record.msgStatus == MessageStatusUnread) {
        color = [UIColor blackColor];
    }
    else{
        color = [UIColor grayColor];
    }
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, (cellHeight-textSize.height)/2, textSize.width, textSize.height)];
    lbl.text = text;
    lbl.font = [UIFont systemFontOfSize:fontSize];
    lbl.textColor = color;
    lbl.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:lbl];
    
    if (record.msgStatus == MessageStatusUnread) {
        
        UIImageView *noteView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(tblView.frame)-wid-2, (cellHeight - 19)/2, wid, 19)];
        noteView.image = [UIImage imageNamed:@"New"];
        [cell.contentView addSubview:noteView];
    }
    
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, cellHeight-1, CGRectGetWidth(tblView.frame), 1)];
    sep.backgroundColor = [UIColor colorWithRed:239/255. green:239/255. blue:239/255. alpha:1];
    [cell.contentView addSubview:sep];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    AlarmRecord *record = [self.alarmRecords objectAtIndex:indexPath.row];
    
    record.msgStatus = MessageStatusRead;
    
    if (([NetReachability isReachableViaWWAN] && [User currentUser].alarmVideo == AVSEnableViaWifi)
        || [User currentUser].alarmVideo == AVSEnableVideo) {
        
   
        [self playVideoWithRecord:record];
        
    }
    else {
        [self stopPlaying];
    }
    
    
    selectedIndex = indexPath.row;
    
    [tblView reloadData];
}


- (void)stopPlaying
{
    //关闭视频可以自动锁屏
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
#ifndef INVALID_VIDEO
    [zw_dssdk dssdk_rtv_stop:(__bridge void *)(videoWnd)];
#endif
    
    playBtn.hidden = NO;
   
}

- (IBAction)cancelAlarm:(id)sender
{
    [self goBack];
}


- (IBAction)clickPlayVideo:(id)sender
{
    AlarmRecord *record = [self.alarmRecords objectAtIndex:selectedIndex];
    
    [self playVideoWithRecord:record];
}


- (void)playVideoWithRecord:(AlarmRecord *)record
{
    
    playBtn.hidden = YES;
    
    float fplayScale = 1.0;
    if ([UIScreen instancesRespondToSelector:@selector(scale)])
    {
        fplayScale = (CGFloat)[[UIScreen mainScreen] scale];
    }
    
    NSString *url = [record videoAddr];
    NSString *pubUrl = [record pubVideoAddr];
    
    
    NSLog(@"play video url:%@  pubUrl:%@",url,pubUrl);
    
#ifndef INVALID_VIDEO
    
    MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:videoWnd];
    [videoWnd addSubview:tempHud];
    tempHud.removeFromSuperViewOnHide = YES;
    tempHud.mode = MBProgressHUDModeIndeterminate;
    [tempHud show:YES];
    
    int ret = -1;
    int ret1 = -1;
    if (url) {
        ret = [zw_dssdk dssdk_rtv_start:(__bridge void *)(videoWnd):(char*)[url UTF8String] :fplayScale];
    }
    
  
    if (ret != 1 && pubUrl) {
        
        ret1 = [zw_dssdk dssdk_rtv_start:(__bridge void *)(videoWnd):(char*)[pubUrl UTF8String] :fplayScale];
        
    }
    
    
    if (ret == 1 || ret1 == 1) {
//        self.isPlaying = YES;
        playBtn.hidden = YES;
        
        
        //看视频的时候防止锁屏
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
    }
    else {
        NSString *msg = [NSString stringWithFormat:@"%@(错误码:%d)\n%@(错误码:%d)",url,ret,pubUrl,ret1];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"打开视频失败" message:msg delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert show];
        
//        self.isPlaying = NO;
        playBtn.hidden = NO;
    }
    
    [tempHud hide:YES];
    
    
#endif
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PlayVideoNotification object:self];
    
}

@end
