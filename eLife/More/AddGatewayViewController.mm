//
//  AddGatewayViewController.m
//  eLife
//
//  Created by 陈杰 on 15/3/21.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#define CELL_HEIGHT 44
#define INVALID_INDEX -1

#import "AddGatewayViewController.h"
#import "NetAPIClient.h"
#import "MBProgressHUD.h"
#import "Util.h"
#import "GatewayListViewController.h"

#import "ZXingWidgetController.h"
#import <QRCodeReader.h>
#import <Decoder.h>
#import <TwoDDecoderResult.h>

@interface AddGatewayViewController () <UITextFieldDelegate,DecoderDelegate,UIImagePickerControllerDelegate,ZXingDelegate>
{

    BOOL expand;//是否展开
    NSInteger editIndex;//正在编辑的textfile 索引
    
    NSString *sn;
    NSString *name;
    NSString *user;
    NSString *pswd;
    NSString *ip;
    NSString *port;
    
    MBProgressHUD *hud;
}

@end



@implementation AddGatewayViewController

@synthesize sn = sn;
@synthesize ip = ip;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    editIndex = INVALID_INDEX;
    self.tableView.allowsSelection = NO;
    self.tableView.backgroundColor = [UIColor colorWithRed:230/255. green:230/255. blue:230/255. alpha:1];
    self.tableView.backgroundView = nil;
//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [Util unifyStyleOfViewController:self withTitle:@"添加网关"];
    
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    
    //默认值
    user = @"admin";
    pswd = @"admin";
    port = @"6000";

    
    if (!name) {
        if ([sn length] > 4)
        {
            name = [sn substringWithRange:NSMakeRange([sn length]-4, 4)];
            name = [NSString stringWithFormat:@"AE%@",name];
 
        }
        else if ([sn length] > 0) {
            name = [NSString stringWithFormat:@"AE%@",sn];
          
        }
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - Table view data source



- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
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
    
    
    UIButton *addBtn  = [UIButton buttonWithType:UIButtonTypeCustom];
    addBtn.frame = CGRectMake((CGRectGetWidth(tableView.frame)-300)/2, 54, 300, 44);
    [addBtn setTitle:@"添加" forState:UIControlStateNormal];
    [addBtn setBackgroundImage:[UIImage imageNamed:@"reg_btn"] forState:UIControlStateNormal];
    [addBtn addTarget:self action:@selector(addGateway:) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:addBtn];
    
    
    return footer;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 100;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    if (expand) {
        return 4;
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
//        case 2:
//            titleText = @"用户名:";
//            detailText = user;
//            break;
//        case 3:
//            titleText = @"密码:";
//            detailText = pswd;
//            break;
        case 2:
            titleText = @"IP:";
            detailText = ip;
            break;
        case 3:
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
//    txtField.textColor = [UIColor darkGrayColor];
    txtField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    txtField.backgroundColor = [UIColor clearColor];
    txtField.placeholder = @"请输入";
    txtField.borderStyle = UITextBorderStyleNone;
    txtField.clearButtonMode = UITextFieldViewModeWhileEditing;
    txtField.tag = indexPath.row;
    txtField.font = [UIFont systemFontOfSize:15];
    txtField.delegate = self;
    [cell.contentView addSubview:txtField];
    if (indexPath.row == editIndex) {
        [txtField becomeFirstResponder];
    }
    
    
    if (indexPath.row == 0) {
        UIButton *QRScanBtn  = [UIButton buttonWithType:UIButtonTypeCustom];
        QRScanBtn.frame = CGRectMake(0, 0, 44, 44);
        [QRScanBtn setImage:[UIImage imageNamed:@"QRScan"] forState:UIControlStateNormal];
        [QRScanBtn addTarget:self action:@selector(scanCode:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = QRScanBtn;
    }
    else {
        cell.accessoryView = nil;
    }
    
    
//    //自定义分割线
//    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, CELL_HEIGHT-1, CGRectGetWidth(tableView.frame), 1)];
//    sep.backgroundColor = [UIColor grayColor];
//    sep.alpha = 0.3;
//    [cell.contentView addSubview:sep];
    
    return cell;
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
//        case 2:
//            user = textField.text;
//            break;
//        case 3:
//            pswd = textField.text;
//            break;
        case 2:
            ip = textField.text;
            break;
        case 3:
            port = textField.text;
            break;
            
        default:
            break;
    }
}

- (void)showOrHideDetail:(UIButton *)sender
{
    expand = !expand;
    
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:1];
    for (int i = 2; i < 4; i++) {
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




#pragma mark - ZXingDelegate

- (void)zxingController:(ZXingWidgetController *)controller didScanResult:(NSString *)result
{
    [self dismissViewControllerAnimated:YES completion:^{[self outPutResult:result];}];
}

- (void)zxingControllerDidCancel:(ZXingWidgetController *)controller
{
    [self dismissViewControllerAnimated:YES completion:^{NSLog(@"cancel!");}];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    [self dismissViewControllerAnimated:YES completion:^{[self decodeImage:image];}];
}

- (void)decodeImage:(UIImage *)image
{
    NSMutableSet *qrReader = [[NSMutableSet alloc] init];
    QRCodeReader *qrcoderReader = [[QRCodeReader alloc] init];
    [qrReader addObject:qrcoderReader];
    
    Decoder *decoder = [[Decoder alloc] init];
    decoder.delegate = self;
    decoder.readers = qrReader;
    [decoder decodeImage:image];
}

#pragma mark - DecoderDelegate

- (void)decoder:(Decoder *)decoder didDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset withResult:(TwoDDecoderResult *)result
{
    [self outPutResult:result.text];
}

- (void)decoder:(Decoder *)decoder failedToDecodeImage:(UIImage *)image usingSubset:(UIImage *)subset reason:(NSString *)reason
{
    NSLog(@"解码失败");
    
    //    [self outPutResult:[NSString stringWithFormat:@"解码失败！"]];
}

- (void)outPutResult:(NSString *)result
{
    sn = result;
    
    if (!name) {
        if ([result length] > 4)
        {
            name = [result substringWithRange:NSMakeRange([result length]-4, 4)];
            name = [NSString stringWithFormat:@"AE%@",name];
   
        }
        else {
            name = [NSString stringWithFormat:@"AE%@",result];
        
        }
    }
    
    [self.tableView reloadData];
    
}

- (void)addGateway:(id)sender
{
    [self hideKeyboard];
    
    SHGateway *gateway = [[SHGateway alloc] init];
    gateway.serialNumber = sn;
    gateway.user = user;
    gateway.pswd = pswd;
    gateway.name = name;
    gateway.addr = ip;
    gateway.port = [port intValue];
    
    
    if ([sn length] == 0) {
        [self showAlertMsg:@"序列号不能为空"];
    }
    else if ([user length] == 0) {
        [self showAlertMsg:@"用户名不能为空"];
    }
    else if ([pswd length] == 0) {
        [self showAlertMsg:@"密码不能为空"];
    }
    else if ([ip length] == 0 ) {
        [self showAlertMsg:@"IP不能为空"];
    }
    else if ([port length] == 0 ) {
        [self showAlertMsg:@"端口不能为空"];
    }
    else {
        [self showWaitingStatus];
        
        
        void (^ successCallback)(void) = ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"绑定成功";
            [hud hide:YES afterDelay:1.0];
            
            //            [self.navigationController popViewControllerAnimated:YES];
            
            NSArray *controllerStack = [self.navigationController viewControllers];
            
            UIViewController *gatewayListController = nil;
            NSString *nibName = [Util nibNameWithClass:[GatewayListViewController class]];
            
            for (UIViewController *vc in controllerStack) {
                if ([vc.nibName isEqualToString:nibName]) {
                    gatewayListController = vc;
                    break;
                }
            }
            
            [self.navigationController popToViewController:gatewayListController animated:YES];
            
            //[self.navigationController popViewControllerAnimated:YES];
            
            
        };
        
        
        void (^ failureCallback)(int) = ^(int err){
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
            NSString *errorMsg = [self msgForErrorCode:err];
            
            hud.mode = MBProgressHUDModeText;
            hud.labelText = [NSString stringWithFormat:@"绑定失败,%@",errorMsg];
            [hud hide:YES afterDelay:1.5];
            
        };
        
        
        [[NetAPIClient sharedClient] bindGateway:gateway successCallback:successCallback failureCallback:failureCallback];
        
    }
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

- (void)scanCode:(id)sender
{
    ZXingWidgetController *widController = [[ZXingWidgetController alloc] initWithDelegate:self showCancel:YES OneDMode:NO];
    NSMutableSet *readers = [[NSMutableSet alloc] init];
    QRCodeReader *qrcodeReader = [[QRCodeReader alloc] init];
    [readers addObject:qrcodeReader];
    widController.readers = readers;
    [self presentViewController:widController animated:YES completion:^{}];
}


- (void)reqTimeout
{
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"请求超时!";
    
    [hud hide:YES afterDelay:1.5];
}

- (void)showWaitingStatus
{
    hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.labelText = @"请稍后...";
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.removeFromSuperViewOnHide = YES;
    [hud show:YES];
    
    [self performSelector:@selector(reqTimeout) withObject:nil afterDelay:15];
}

- (void)showAlertMsg:(NSString *)msg
{
    hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    hud.labelText = msg;
    hud.mode = MBProgressHUDModeText;
    hud.removeFromSuperViewOnHide = YES;
    
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    [hud show:YES];
    [hud hide:YES afterDelay:1.5];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
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
