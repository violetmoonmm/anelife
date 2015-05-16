//
//  GatewayInfoViewController.m
//  eLife
//
//  Created by 陈杰 on 15/3/21.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "GatewayInfoViewController.h"
#import "NetAPIClient.h"
#import "MBProgressHUD.h"
#import "Util.h"
#import "NotificationDefine.h"
#import "GatewayUsersViewController.h"
#import "QRCodeEncoderViewController.h"

#define CELL_HEIGHT 44
#define EDIT_TIMEOUT 15
#define INVALID_INDEX -1

@interface GatewayInfoViewController () <UITextFieldDelegate,UIAlertViewDelegate>
{
    BOOL isEditing;//进入编辑模式
    
    UIButton *rightBtn1;
    UIButton *rightBtn2;

    BOOL expand;//是否展开
    NSInteger editIndex;//正在编辑的textfile 索引
    
    NSString *sn;
    NSString *name;
    NSString *user;
    NSString *pswd;
    NSString *ip;
    NSString *port;
    
    MBProgressHUD *hud;
    
    UIButton *synConfigBtn;//同步配置
    UIButton *authBtn;//重新认证
    UIButton *QRCodeBtn;//二维码授权
    UIButton *editPswdBtn;//管理密码修改
}

@end

@implementation GatewayInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [Util unifyStyleOfViewController:self withTitle:@"网关详细信息"];
    
    
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    //修改按钮
    rightBtn1 = [UIButton buttonWithType:UIButtonTypeCustom];
    rightBtn1.frame = CGRectMake(0, 0, 44, 44);
    [rightBtn1 addTarget:self action:@selector(editGateway:) forControlEvents:UIControlEventTouchUpInside];
    [rightBtn1 setImage:[UIImage imageNamed:@"EditGateway"] forState:UIControlStateNormal];
    //    [returnBtn setTitle:@"添加" forState:UIControlStateNormal];
    UIBarButtonItem *editBtnItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn1];
    
    //删除按钮
    rightBtn2 = [UIButton buttonWithType:UIButtonTypeCustom];
    rightBtn2.frame = CGRectMake(0, 0, 44, 44);
    [rightBtn2 addTarget:self action:@selector(delGateway:) forControlEvents:UIControlEventTouchUpInside];
    [rightBtn2 setImage:[UIImage imageNamed:@"RemoveGateway"] forState:UIControlStateNormal];
    //    [returnBtn setTitle:@"添加" forState:UIControlStateNormal];
    UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn2];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:rightBtnItem,editBtnItem, nil];
    
    editIndex = INVALID_INDEX;
    self.tableView.allowsSelection = NO;
    self.tableView.backgroundColor = [UIColor colorWithRed:230/255. green:230/255. blue:230/255. alpha:1];
    self.tableView.backgroundView = nil;
//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    sn = self.gateway.serialNumber;
    name = self.gateway.name;
    user = self.gateway.user;
    pswd = self.gateway.pswd;
    ip = self.gateway.addr;
    port = [NSString stringWithFormat:@"%d",self.gateway.port];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    if (expand) {
        return 6;
    }
    
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"AddGatewayCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    // Configure the cell...
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    for (UIView *v in [cell.contentView subviews])
    {
        [v removeFromSuperview];
    }
    
    
    NSString *titleText = nil;
    NSString *detailText = nil;
    switch (indexPath.row) {
        case 0:
            titleText = @"序列号:";
            detailText = sn;
            break;
        case 1:
            titleText = @"名称:";
            detailText = name;
            break;
        case 2:
            titleText = @"用户名:";
            detailText = user;
            break;
        case 3:
            titleText = @"密码:";
            detailText = pswd;
            break;
        case 4:
            titleText = @"IP:";
            detailText = ip;
            break;
        case 5:
            titleText = @"端口号:";
            detailText = port;
            break;
            
        default:
            break;
    }
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 58, CELL_HEIGHT)];
    lbl.backgroundColor = [UIColor clearColor];
    lbl.text = titleText;
    lbl.textColor = [UIColor darkGrayColor];
    lbl.textAlignment = NSTextAlignmentRight;
    lbl.font = [UIFont systemFontOfSize:15];
    [cell.contentView addSubview:lbl];
    
    NSInteger spacingX = 12;
    NSInteger txtFiledH = 40;
    UITextField *txtField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(lbl.frame)+spacingX, (CELL_HEIGHT-txtFiledH)/2, CGRectGetWidth(tableView.frame)-CGRectGetMaxX(lbl.frame)-68, txtFiledH)];
    txtField.text = detailText;
    if (!isEditing) {
        txtField.textColor = [UIColor darkGrayColor];
    }
    else {
        txtField.textColor = [UIColor blackColor];
    }
    txtField.placeholder = @"请输入";
    txtField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    txtField.borderStyle = UITextBorderStyleNone;
    txtField.clearButtonMode = UITextFieldViewModeWhileEditing;
    txtField.tag = indexPath.row;
    txtField.font = [UIFont systemFontOfSize:15];
    txtField.delegate = self;
    [cell.contentView addSubview:txtField];
    if (indexPath.row == editIndex) {
        [txtField becomeFirstResponder];
    }
    

    if (!isEditing)
    {
        txtField.userInteractionEnabled = NO;
    }
    else {
        txtField.userInteractionEnabled = YES;
    }
    
    if (indexPath.row == 0) {
        txtField.userInteractionEnabled = NO;
        txtField.textColor = [UIColor grayColor];
    }
    
    
//    //自定义分割线
//    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, CELL_HEIGHT-1, CGRectGetWidth(tableView.frame), 1)];
//    sep.backgroundColor = [UIColor grayColor];
//    sep.alpha = 0.3;
//    [cell.contentView addSubview:sep];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 100)];
    
    NSString *title = expand ? @"隐藏" : @"更多";
    NSString *imageName = expand ? @"BlueUpBtn" : @"BlueDownBtn";
    
    UIButton *expandBtn  = [UIButton buttonWithType:UIButtonTypeCustom];
    expandBtn.frame = CGRectMake(CGRectGetWidth(tableView.frame)-74, 8, 64, 40);
    [expandBtn setTitle:title forState:UIControlStateNormal];
    [expandBtn setTitleColor:[UIColor colorWithRed:76/255. green:186/255. blue:255/255. alpha:1] forState:UIControlStateNormal];
    [expandBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, -24, 0, 0)];
    [expandBtn setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [expandBtn setImageEdgeInsets:UIEdgeInsetsMake(0,44,0,0)];
    [expandBtn addTarget:self action:@selector(showOrHideDetail:) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:expandBtn];
    
    if (self.gateway.authorized) {

        if (!synConfigBtn)
        {
            synConfigBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            synConfigBtn.frame = CGRectMake((CGRectGetWidth(tableView.frame)-300)/2, 54, 300, 44);
            [synConfigBtn setTitle:@"同步配置" forState:UIControlStateNormal];
            [synConfigBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [synConfigBtn setBackgroundImage:[UIImage imageNamed:@"reg_btn"] forState:UIControlStateNormal];
            [synConfigBtn addTarget:self action:@selector(synConfig:) forControlEvents:UIControlEventTouchUpInside];
        }
        [footer addSubview:synConfigBtn];
        
        if (!QRCodeBtn)
        {
           
            QRCodeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            QRCodeBtn.frame = CGRectMake((CGRectGetWidth(tableView.frame)-300)/2, CGRectGetMaxY(synConfigBtn.frame)+10, 300, 44);
            [QRCodeBtn setTitle:@"二维码授权" forState:UIControlStateNormal];
            [QRCodeBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [QRCodeBtn setBackgroundImage:[UIImage imageNamed:@"LongWhiteBtn"] forState:UIControlStateNormal];
            [QRCodeBtn addTarget:self action:@selector(AuthQRCode:) forControlEvents:UIControlEventTouchUpInside];
            
        }
        [footer addSubview:QRCodeBtn];
        
        if (!editPswdBtn)
        {
            
            editPswdBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            editPswdBtn.frame = CGRectMake((CGRectGetWidth(tableView.frame)-300)/2, CGRectGetMaxY(QRCodeBtn.frame)+10, 300, 44);
            [editPswdBtn setTitle:@"管理密码修改" forState:UIControlStateNormal];
            [editPswdBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [editPswdBtn setBackgroundImage:[UIImage imageNamed:@"LongWhiteBtn"] forState:UIControlStateNormal];
            [editPswdBtn addTarget:self action:@selector(changePswd:) forControlEvents:UIControlEventTouchUpInside];
            
        }
        
        [footer addSubview:editPswdBtn];

    }
    else {
        if (!authBtn)
        {
            authBtn  = [UIButton buttonWithType:UIButtonTypeCustom];
            authBtn.frame = CGRectMake((CGRectGetWidth(tableView.frame)-300)/2, 54, 300, 44);
            [authBtn setTitle:@"认证" forState:UIControlStateNormal];
            [authBtn setBackgroundImage:[UIImage imageNamed:@"reg_btn"] forState:UIControlStateNormal];
            [authBtn addTarget:self action:@selector(reauth:) forControlEvents:UIControlEventTouchUpInside];
            
          
        }
        
        [footer addSubview:authBtn];
    }
    
    
    
    return footer;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 210;
}


#pragma mark UITextFiledDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    editIndex = textField.tag;
    //    switch (textField.tag) {
    //        case 0:
    //            sn = textField.text;
    //            break;
    //        case 1:
    //            name = textField.text;
    //            break;
    //        case 2:
    //            user = textField.text;
    //            break;
    //        case 3:
    //            pswd = textField.text;
    //            break;
    //        case 4:
    //            ip = textField.text;
    //            break;
    //        case 5:
    //            port = textField.text;
    //            break;
    //
    //        default:
    //            break;
    //    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    switch (textField.tag) {
        case 0:
            sn = textField.text;
            break;
        case 1:
            name = textField.text;
            break;
        case 2:
            user = textField.text;
            break;
        case 3:
            pswd = textField.text;
            break;
        case 4:
            ip = textField.text;
            break;
        case 5:
            port = textField.text;
            break;
            
        default:
            break;
    }
}



#pragma mark Private Method
- (void)showOrHideDetail:(UIButton *)sender
{
    expand = !expand;
    
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:1];
    for (int i = 2; i < 6; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    if (expand) {//点击更多
        
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        
        [sender setTitle:@"隐藏" forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"BlueUpBtn"] forState:UIControlStateNormal];
    }
    else {//点击隐藏
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
        
        [sender setTitle:@"更多" forState:UIControlStateNormal];
        [sender setImage:[UIImage imageNamed:@"BlueDownBtn"] forState:UIControlStateNormal];
    }
}



- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}




- (void)reqTimeout
{
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"请求超时!";
    
    [hud hide:YES afterDelay:1.5];
}

- (void)showWaitingStatus
{
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.labelText = @"请稍后...";
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.removeFromSuperViewOnHide = YES;
    [hud show:YES];
    
    [self performSelector:@selector(reqTimeout) withObject:nil afterDelay:EDIT_TIMEOUT];
}

- (void)showAlertMsg:(NSString *)msg
{
    hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.labelText = msg;
    hud.mode = MBProgressHUDModeText;
    hud.removeFromSuperViewOnHide = YES;
    [hud show:YES];
    [hud hide:YES afterDelay:1.5];
}


//- (void)showRefreshFinished
//{
//    //    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reqTimeout) object:nil];
//    
//    hud.labelText = @"同步完成";
//    hud.mode = MBProgressHUDModeCustomView;
//    
//    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
//    
//    [hud hide:YES afterDelay:1.5];
//}

//同步配置
- (void)synConfig:(id)sender
{
    
    MBProgressHUD *tempHud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:tempHud];
    tempHud.labelText = @"正在同步...";
    tempHud.mode = MBProgressHUDModeIndeterminate;
    tempHud.removeFromSuperViewOnHide = YES;
    [tempHud show:YES];
    
    [[NetAPIClient sharedClient] synchronizeConfig:self.gateway completionCallback:^{

        tempHud.labelText = @"同步完成";
        tempHud.mode = MBProgressHUDModeCustomView;
        
        tempHud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
        
        [tempHud hide:YES afterDelay:1.5];
    }];
    
}



//二维码授权
- (void)AuthQRCode:(id)sender
{
    NSString *nibName = [Util nibNameWithClass:[QRCodeEncoderViewController class]];
    QRCodeEncoderViewController *vc = [[QRCodeEncoderViewController alloc] initWithNibName:nibName bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

//管理密码修改
- (void)changePswd:(id)sender
{
    
}

//重新授权
- (void)reauth:(id)sender
{
    [self showWaitingStatus];
    
    [[NetAPIClient sharedClient] reauthGateway:self.gateway successCallback:^{
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"认证成功";
        [hud hide:YES afterDelay:1.5];
        
        [self.navigationController popViewControllerAnimated:YES];
        
    }failureCallback:^(NSString *error){
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        hud.mode = MBProgressHUDModeText;
        hud.labelText = error;
        [hud hide:YES afterDelay:1.5];
    }];
}

- (NSString *)msgForErrorCode:(int)errorCode
{
    NSString *msg = nil;
    if(ErrorAdded == errorCode)
    {
        msg = @"该网关已经添加!";
    }
    else if (ErrorTimeout == errorCode)
    {
        msg = @"超时!";
    }
    else if (DisRe_UserInvalid == errorCode)
    {
        msg = @"用户名错误!";
    }
    else if (DisRe_PasswordInvalid == errorCode)
    {
        msg = @"密码错误!";
    }
    else if (DisRe_SerialNoInvalid == errorCode)
    {
        msg = @"序列号错误!";
    }
    else if (DisRe_ConnectFailed == errorCode)
    {
        msg = @"连接失败!";
    }
    else if (DisRe_Keepalivetimeout == errorCode)
    {
        msg = @"连接失败!";
    }
    else if (DisRe_RegistedFailed == errorCode)
    {
        msg = @"注册失败!";
    }
    else if (DisRe_RegistedRefused == errorCode)
    {
        msg = @"注册被拒绝!";
    }
    else if (DisRe_AuthCodeInvalid == errorCode)
    {
        msg = @"授权码无效!";
    }
    else if (DisRe_AuthFailed == errorCode)
    {
        msg = @"认证失败!";
    }
    else if (DisRe_NotAuthMode == errorCode)
    {
        msg = @"拒绝授权!";
    }
    else if (DisRe_OutOfAuthLimit == errorCode)
    {
        msg = @"拒绝授权!";
    }
    else if (DisRe_Disconnected == errorCode)
    {
        msg = @"断线!";
    }
    else if (DisRe_ParamInvalid == errorCode)
    {
        msg = @"参数异常!";
    }
    else if (DisRe_Unknown == errorCode)
    {
        msg = @"未知原因!";
    }
    else {
        msg = [NSString stringWithFormat:@"错误码%d",errorCode];
    }
    
    return msg;
}

- (void)delGateway:(id)sender
{
    if (!isEditing){//进入编辑模式
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"确定要删除网关吗" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert show];
        

    }
    else {//正在编辑模式，取消编辑
        
        [rightBtn1 setImage:[UIImage imageNamed:@"EditGateway"] forState:UIControlStateNormal];
        [rightBtn2 setImage:[UIImage imageNamed:@"RemoveGateway"] forState:UIControlStateNormal];
        
        isEditing = NO;
        authBtn.enabled = YES;
        
        //还原
        sn = self.gateway.serialNumber;
        name = self.gateway.name;
        user = self.gateway.user;
        pswd = self.gateway.pswd;
        ip = self.gateway.addr;
        port = [NSString stringWithFormat:@"%d",self.gateway.port];
        [self.tableView reloadData];
    }
    

    
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *str = [ alertView buttonTitleAtIndex:buttonIndex];
    if ([str isEqualToString:@"确定"]) {
        
        [self showWaitingStatus];
        
        [[NetAPIClient sharedClient] removeGateway:self.gateway timeout:EDIT_TIMEOUT successCallback:^{
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"删除成功！";
            [hud hide:YES afterDelay:1.5];
            
            [self.navigationController popViewControllerAnimated:YES];
            
        }failureCallback:^(int err){
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"删除失败！";
            [hud hide:YES afterDelay:1.5];
        }];
    }
}

- (void)editGateway:(id)sender
{

    [self hideKeyboard];
    
    if (!isEditing){//进入编辑模式
    
        [rightBtn1 setImage:[UIImage imageNamed:@"SaveEdit"] forState:UIControlStateNormal];
        [rightBtn2 setImage:[UIImage imageNamed:@"CancelEdit"] forState:UIControlStateNormal];
        
        isEditing = YES;
  
        [self.tableView reloadData];
        authBtn.enabled = NO;
        
    }
    else {//正在编辑模式，保存
        if ([sn length] == 0) {
            [self showAlertMsg:@"序列号不能为空"];
        }
        else if ([user length] == 0) {
            [self showAlertMsg:@"用户名不能为空"];
        }
        else if ([pswd length] == 0) {
            [self showAlertMsg:@"密码不能为空"];
        }
        else if ([ip length] == 0) {
            [self showAlertMsg:@"IP不能为空"];
        }
        else if ([port length] == 0) {
            [self showAlertMsg:@"端口不能为空"];
        }
        else {
            [self showWaitingStatus];
            
            
            void (^successCallback)() = ^{
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"修改成功";
                [hud hide:YES afterDelay:1.5];
                
                [self.navigationController popViewControllerAnimated:YES];
                
//                [rightBtn1 setImage:[UIImage imageNamed:@"EditGateway"] forState:UIControlStateNormal];
//                [rightBtn2 setImage:[UIImage imageNamed:@"RemoveGateway"] forState:UIControlStateNormal];
//                
//                isEditing = NO;
//                authBtn.enabled = YES;
                
            };
            
            void (^failureCallback)(int) = ^(int err){
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                
                
                NSString *info = [NSString stringWithFormat:@"修改失败,%@",[self msgForErrorCode:err]];
                hud.mode = MBProgressHUDModeText;
                hud.labelText = info;
                [hud hide:YES afterDelay:1.5];
                
            };
            
            
            [[NetAPIClient sharedClient] editGateway:self.gateway withName:name user:user pswd:pswd ip:ip port:port timeout:EDIT_TIMEOUT successCallback:successCallback failureCallback:failureCallback];
            
        }
    }
    
    

    
}

- (void)hideKeyboard
{
    for (UITableViewCell *cell in [self.tableView visibleCells])
    {
        for (UIView *subView in [cell.contentView subviews])
        {
            if ([subView isKindOfClass:[UITextField class]]) {
                if ([(UITextField *)subView isFirstResponder]) {
                    [(UITextField *)subView resignFirstResponder];
                }
                
                break;
            }
        }
    }
    
}


@end
