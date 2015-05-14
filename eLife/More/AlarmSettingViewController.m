//
//  AlarmSettingViewController.m
//  eLife
//
//  Created by 陈杰 on 15/4/28.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "AlarmSettingViewController.h"
#import "User.h"
#import "AlarmVideoViewController.h"
#import "Util.h"
#import "UserDBManager.h"

#define CELL_H 44


@interface AlarmSettingViewController ()

@end

@implementation AlarmSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [Util unifyStyleOfViewController:self withTitle:@"报警通知"];
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];

    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    


}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    [self.tableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)setAlarmEnable:(UISwitch *)sender
{
    [User currentUser].disableAlarm = !sender.on;
    
    [[UserDBManager defaultManager] updateUser:[User currentUser]];

    NSIndexPath *indx = [NSIndexPath indexPathForRow:0 inSection:1];
    
    if (sender.on) {

        
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indx] withRowAnimation:UITableViewRowAnimationTop];
    }
    else {

        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indx] withRowAnimation:UITableViewRowAnimationTop];
    }
    

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return 24;
    }
    
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        UILabel *tipLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 24)];
        tipLbl.text = @"若关闭,当发生报警时,将不会实时提醒";
        tipLbl.backgroundColor = [UIColor clearColor];
        tipLbl.textColor = [UIColor grayColor];
        tipLbl.textAlignment = NSTextAlignmentCenter;
        tipLbl.font = [UIFont systemFontOfSize:15];
        
        return tipLbl;
    }
    
    
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_H;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([User currentUser].disableAlarm && section == 1) {
        return 0;
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *identifier = @"alarmsetting";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    // Configure the cell...
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    for (UIView *v in [cell.contentView subviews])
    {
        [v removeFromSuperview];
    }
    
    NSString *txt = nil;
    if (indexPath.section == 0) {
        txt = @"接收报警通知";
    }
    else {
        txt = @"联动视频";
    }
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 120, CELL_H)];
    lbl.text = txt;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor blackColor];
    lbl.font = [UIFont boldSystemFontOfSize:15];
    [cell.contentView addSubview:lbl];

    
    
    if (indexPath.section == 0) {
        UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 20)];
        aSwitch.on = ![User currentUser].disableAlarm;
        [aSwitch addTarget:self action:@selector(setAlarmEnable:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = aSwitch;
    }
    else {

        NSString *videoSetting = nil;
        switch ([User currentUser].alarmVideo) {
            case AVSEnableVideo:
                videoSetting = @"2G/3G/4G和WiFi";
                break;
            case AVSEnableViaWifi:
                videoSetting = @"仅WiFi";
                break;
            case AVSDisable:
                videoSetting = @"不联动";
                break;
                
            default:
                break;
        }
        
        UILabel *vslbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(tableView.bounds)-160, 0, 120, CELL_H)];
        vslbl.text = videoSetting;
        vslbl.backgroundColor = [UIColor clearColor];
        vslbl.textColor = [UIColor darkGrayColor];
        vslbl.textAlignment = NSTextAlignmentRight;
        vslbl.font = [UIFont boldSystemFontOfSize:15];
        [cell.contentView addSubview:vslbl];
        
        
        //箭头
        UIImageView *rightArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Userguide_enter_icon.png"]];
        rightArrow.frame = CGRectMake(0, 0, 20, 20);
        rightArrow.backgroundColor = [UIColor clearColor];
        cell.accessoryView = rightArrow;
        
    }
    

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        NSString *nibName = [Util nibNameWithClass:[AlarmVideoViewController class]];
        AlarmVideoViewController *controller = [[AlarmVideoViewController alloc] initWithNibName:nibName bundle:nil];
        
        [self.navigationController pushViewController:controller animated:YES];
    }
}




@end
