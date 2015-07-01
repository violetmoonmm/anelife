//
//  GatewayUsersViewController.m
//  eLife
//
//  Created by 陈杰 on 15/4/15.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "GatewayUsersViewController.h"
#import "User.h"
#import "Util.h"
#import "NotificationDefine.h"
#import "DeviceData.h"
#import "MBProgressHUD.h"
#import "PopInputView.h"
#import "NetAPIClient.h"

#define CELL_H 84


@interface GatewayUsersViewController () <PopInputViewDelegate>
{
    MBProgressHUD *hud;
    UIButton *editBtn;
    
    NSInteger removeIndex;//将要删除用户index
    NSMutableArray *usersArray;
}

@end

@implementation GatewayUsersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [Util unifyStyleOfViewController:self withTitle:@"授权用户"];
    
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    //修改按钮
    editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    editBtn.frame = CGRectMake(0, 0, 44, 44);
    [editBtn addTarget:self action:@selector(edit) forControlEvents:UIControlEventTouchUpInside];
//    [editBtn setImage:[UIImage imageNamed:@"EditGateway"] forState:UIControlStateNormal];
    [editBtn setTitle:@"编辑" forState:UIControlStateNormal];
    [editBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [editBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
    UIBarButtonItem *editBtnItem = [[UIBarButtonItem alloc] initWithCustomView:editBtn];
    self.navigationItem.rightBarButtonItem = editBtnItem;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    
    usersArray = [NSMutableArray arrayWithCapacity:1];

    
    [self showWaitingStatus];
    
    [[NetAPIClient sharedClient] getAuthUsersOfGateway:self.gateway successCallback:^(NSArray *users){
        
        [self hideWaitingStatus];
        
        [usersArray addObjectsFromArray:users];
        
        [self.tableView reloadData];
        
    }failureCallback:^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"查询失败!";
        [hud  hide:YES afterDelay:1.5];
    }];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)edit
{
    self.tableView.editing = !self.tableView.editing;
    
    if (self.tableView.isEditing)
    {
        [editBtn setTitle:@"完成" forState:UIControlStateNormal];
    }
    else {
        [editBtn setTitle:@"编辑" forState:UIControlStateNormal];
    }
    
    
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)hideWaitingStatus
{
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [hud hide:YES];
}

- (void)showWaitingStatus
{
    NSLog(@"showWaitingStatus");
    
    
    [hud hide:YES];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"请稍后...";
    hud.mode = MBProgressHUDModeIndeterminate;
    [hud show:YES];
    
    [self performSelector:@selector(reqTimeout) withObject:nil afterDelay:10];
    
    
}

- (void)reqTimeout
{
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"请求超时!";
    
    
    [hud hide:YES afterDelay:1.5];
    
    
}




- (void)showCtrlFailedHint:(NSString *)info
{
    
    MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:tempHud];
    tempHud.removeFromSuperViewOnHide = YES;
    tempHud.mode = MBProgressHUDModeText;
    tempHud.labelText = info;
    [tempHud show:YES];
    
    [tempHud hide:YES afterDelay:1.0];
}


#pragma mark UITableViewDataSource && UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_H;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return [usersArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *identifier = @"userlist";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    // Configure the cell...
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    for (UIView *v in [cell.contentView subviews])
    {
        [v removeFromSuperview];
    }
    
    GatewayUser *user = [usersArray objectAtIndex:indexPath.row];

    NSInteger originX = 10;
    NSInteger profileSize = 60;
    
    //头像
    NSString *userImage = user.online ? @"GUserOnline" : @"GUserOffline";
    NSInteger imgMargin = (CELL_H-profileSize)/2;
    UIImageView *profileView = [[UIImageView alloc] initWithFrame:CGRectMake(imgMargin, imgMargin, profileSize, profileSize)];
    profileView.image = [UIImage imageNamed:userImage];
    [cell.contentView addSubview:profileView];
    
    
    NSInteger phoneNoHeight = 24;
    NSInteger phoneModelHeight = 24;
    NSInteger dateHeight = 24;
    NSInteger spacingY = (CELL_H-phoneNoHeight-phoneModelHeight-dateHeight)/4;
    
    //用户手机号
    NSInteger nameFontSize = (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)  ? 16 : 18);
    UIFont *nameFont = [UIFont systemFontOfSize:nameFontSize];
    CGSize size = [user.phoneNumber sizeWithFont:nameFont constrainedToSize:CGSizeMake(200, phoneNoHeight)];
    UILabel *userLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(profileView.frame)+8, spacingY, size.width, phoneNoHeight)];
    userLbl.text = user.phoneNumber;
    userLbl.highlightedTextColor = [UIColor whiteColor];
    userLbl.font = nameFont;
    userLbl.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:userLbl];
    
    //手机型号
    NSString *strModel = [user.deviceModel length] > 0 ? user.deviceModel : @"未知";
    strModel = [NSString stringWithFormat:@"终端型号: %@",strModel];
    NSInteger fontSize = (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)  ? 14 : 16);
    UIFont *detailFont = [UIFont systemFontOfSize:fontSize];
    size = [strModel sizeWithFont:detailFont constrainedToSize:CGSizeMake(300, phoneModelHeight)];
    UILabel *deviceLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(userLbl.frame), CGRectGetMaxY(userLbl.frame)+spacingY, size.width, phoneModelHeight)];
    deviceLbl.text = strModel;
    deviceLbl.highlightedTextColor = [UIColor whiteColor];
    deviceLbl.font = detailFont;
    deviceLbl.backgroundColor = [UIColor clearColor];
    deviceLbl.textColor = [UIColor darkGrayColor];
    [cell.contentView addSubview:deviceLbl];
    
    //登录时间
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:user.loginTime];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM-dd HH:mm"];
    NSString *strDate = [formatter stringFromDate:date];
    strDate = [NSString stringWithFormat:@"上次登录: %@",strDate];
    size = [strDate sizeWithFont:detailFont constrainedToSize:CGSizeMake(300, dateHeight)];
    UILabel *dateLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(userLbl.frame), CGRectGetMaxY(deviceLbl.frame)+spacingY, size.width, phoneModelHeight)];
    dateLbl.text = strDate;
    dateLbl.highlightedTextColor = [UIColor whiteColor];
    dateLbl.font = detailFont;
    dateLbl.backgroundColor = [UIColor clearColor];
    dateLbl.textColor = [UIColor darkGrayColor];
    [cell.contentView addSubview:dateLbl];
    
    //是否在线
    NSString *strState = user.online ? @"在线" : @"不在线";
    UIColor *textColor = user.online ? [UIColor colorWithRed:14/255. green:203/255. blue:0 alpha:1] : [UIColor grayColor];
    fontSize = (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)  ? 14 : 16);
    UIFont *stateFont = [UIFont systemFontOfSize:fontSize];
    size = [strState sizeWithFont:stateFont constrainedToSize:CGSizeMake(200, phoneModelHeight)];
    UILabel *stateLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth(tableView.frame)-size.width-10, CGRectGetMinY(userLbl.frame), size.width, phoneModelHeight)];
    stateLbl.text = strState;
    stateLbl.highlightedTextColor = [UIColor whiteColor];
    stateLbl.font = stateFont;
    stateLbl.backgroundColor = [UIColor clearColor];
    stateLbl.textColor = textColor;
    [cell.contentView addSubview:stateLbl];
    
    
    //自定义分割线
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, CELL_H-1, CGRectGetWidth(tableView.frame), 1)];
    sep.backgroundColor = [UIColor grayColor];
    sep.alpha = 0.2;
    [cell.contentView addSubview:sep];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"删除";
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    GatewayUser *user = [usersArray objectAtIndex:indexPath.row];
    
    if ([user.phoneNumber isEqualToString:[User currentUser].name]) {
        return NO;
    }
    
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {

         removeIndex = indexPath.row;
        
        PopInputView *inputView = [[PopInputView alloc] initWithTitle:@"删除授权用户" placeholder:@"请输入安全密码" delegate:self];
        [inputView show];
        
        // Delete the row from the data source.
        
       
    }

}

#pragma mark PopInputViewDelegate

- (void)popInputView:(PopInputView *)popInputView clickOkButtonWithText:(NSString *)inputText
{
    if ([inputText isEqualToString:@"666666"]) {

        MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        [self.navigationController.view addSubview:tempHud];
        tempHud.labelText = @"请稍后...";
        tempHud.mode = MBProgressHUDModeIndeterminate;
        tempHud.removeFromSuperViewOnHide = YES;
        [hud show:YES];
        
        
        GatewayUser *user = [usersArray objectAtIndex:removeIndex];
        [[NetAPIClient sharedClient] removeAuthUser:user fromGateway:self.gateway successCallback:^{
            NSLog(@"删除用户成功");
            
            [usersArray removeObject:user];
            
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:removeIndex inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }failureCallback:^{
            tempHud.labelText = @"删除用户失败!";
        }];

    }
    else {
        
        [self showCtrlFailedHint:@"密码错误!"];
        
        
    }
}

- (void)popInputView:(PopInputView *)popInputView clickCancelButtonWithText:(NSString *)inputText
{
  
}

@end
