//
//  BoxView.m
//  eLife
//
//  Created by mac on 14-7-22.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BoxView.h"
#import "AirConditionView.h"
#import "MBProgressHUD.h"
#import "DimmerlightView.h"
#import "Util.h"
#import "DeviceData.h"
#import "NetAPIClient.h"
#import "BgdMusicView.h"
#import "GroundHeatView.h"

#define MAGIN_X 4
#define TABLE_H 180

#define BOX_CELL_H ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 80)
#define DEV_ICON_W ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 32 : 50)
#define DEV_ICON_H DEV_ICON_W


#define BOX_BTN_W ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 44 : 48)
#define BOX_BTN_H BOX_BTN_W

#define TAG_ON_BTN 200
#define TAG_OFF_BTN 300
#define TAG_MORE_BTN 400
#define TAG_CAMERA_BTN 500

#define DEF_NUM_OF_ROW 1


@implementation BoxView
{
    
    MBProgressHUD *hud;
    
    UIView *popView;
}

@synthesize devices = _devices;

- (id)initWithFrame:(CGRect)frame
{
    NSLog(@"box view init");
    if (self = [super initWithFrame:frame]) {
        
        _arrowView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 13, 13)];
        _arrowView.backgroundColor = [UIColor clearColor];
        _arrowView.image = [UIImage imageNamed:@"triangle_up.png"];
        
        [self addSubview:_arrowView];
        
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(MAGIN_X, CGRectGetMaxY(_arrowView.frame)-4, CGRectGetWidth(frame) - 2*MAGIN_X, TABLE_H) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.layer.borderColor = [UIColor colorWithRed:74/255. green:123/255. blue:44/255. alpha:1].CGColor;
        _tableView.layer.borderWidth = 1.0;
        _tableView.allowsSelection = NO;
        _tableView.backgroundColor = [UIColor colorWithRed:247/255. green:254/255. blue:243/255. alpha:1];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self insertSubview:_tableView belowSubview:_arrowView];
        
        
        self.backgroundColor = [UIColor colorWithRed:247/255. green:254/255. blue:243/255. alpha:1];
    }
    
    return self;
}



- (void)dealloc
{
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
    _tableView.delegate = nil;
    
    self.delegate = nil;
    
    [self removeObserveDevices];

}

- (void)setDevices:(NSArray *)devices
{
    
    [self removeObserveDevices];
    
    _devices = devices;
    
    
    [self observeDeviceState:devices];
    
    [self showDevices];
}


- (void)removeObserveDevices
{
    //NSLog(@"box view dealloc start");
    for (UIDevice *device in self.devices)
    {
        [device removeObserver:self forKeyPath:@"state.powerOn"];
    }
   // NSLog(@"box view dealloc end");
}

- (void)observeDeviceState:(NSArray *)devices
{
    
    for (SHDevice *device in devices)
    {
        [device addObserver:self forKeyPath:@"state.powerOn" options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    //    NSLog(@"keyPath:%@ change:%@",keyPath,[change description]);
    //  NSLog(@"%@",[[NSThread currentThread] isMainThread] ? @"isMainThread":@"not isMainThread");
  
    
    NSNumber *powerOn = [object valueForKeyPath:@"state.powerOn"];
    BOOL bOn = [powerOn boolValue];
    NSLog(@"box view device: %@ state change to %@",[(SHDevice *)object deviceId], bOn ? @"on" : @"off");
    
    NSInteger row = [self.devices indexOfObject:object];
    if (row != NSNotFound) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
        
        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
    }
    else {
        NSLog(@"not found device id %@ in box view",[(SHDevice *)object deviceId]);
    }

}

- (void)showDevices
{
    
    [_tableView reloadData];
    
    CGRect f = _tableView.frame;
    
    f.size.height = [self.devices count]*BOX_CELL_H;//计算tableview高度
    
    if (self.headerView) {
        f.size.height += CGRectGetHeight(self.headerView.frame);//加上header高度
    }
    
    if ([self.devices count] == 0) {
        f.size.height = DEF_NUM_OF_ROW*BOX_CELL_H;//没有设备 ，设置默认高度
    }
    _tableView.frame = f;
    
    CGRect frame = self.frame;
    frame.size.height = CGRectGetMaxY(_arrowView.frame) + CGRectGetHeight(f);
    self.frame = frame;
    
    
}

- (void)pointToRect:(CGRect)rect
{
    CGRect frame = _arrowView.frame;
    frame.origin.x = CGRectGetMinX(rect) + (CGRectGetWidth(rect) - CGRectGetWidth(_arrowView.frame))/2;
    _arrowView.frame = frame;
}


- (void)showCtrlFailedHint
{
    //    if (!hud) {
    //        hud = [[MBProgressHUD alloc] initWithView:self];
    //
    //        [self addSubview:hud];
    //        hud.removeFromSuperViewOnHide = NO;
    //    }
    //
    //    hud.mode = MBProgressHUDModeText;
    //    hud.labelText = @"控制失败！";
    //    [hud show:YES];
    //
    //    [self performSelector:@selector(hideHint) withObject:nil afterDelay:1.0];
}

- (void)hideHint
{
    [hud hide:YES];
}

//查看摄像头视频
- (void)viewCameraVideo:(UIButton *)sender
{
    NSInteger index = sender.tag - TAG_CAMERA_BTN;
    SHDevice *device = [self.devices objectAtIndex:index];
    
    if ([self.delegate respondsToSelector:@selector(boxViewPlayVideo:)]) {
        [self.delegate boxViewPlayVideo:device.cameraId];
    }
}


- (void)highlightButton:(UIButton *)sender
{
    //float F = [[UIDevice currentDevice].systemVersion floatValue];
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0) {
        sender.selected = YES;
        [self performSelector:@selector(cancelHighlight:) withObject:sender afterDelay:0.15];
    }
    
}

- (void)cancelHighlight:(UIButton *)sender
{
    sender.selected = NO;
}

//2 开 1关
- (void)turnOn:(UIButton *)sender
{
    
    [self highlightButton:sender];
    
    NSInteger index = sender.tag - TAG_ON_BTN;
    SHDevice *device = [self.devices objectAtIndex:index];
    
    
    //__weak BoxView *box = self;//直接在block里面用self以及实例变量会引起循环引用，so... （think:需要在前面加__block?局部变量用作值，因此不会引起self retain？加__weak是为了防止局部变量retain self，arc默认变量为strong reference，可加可不加？）
    
    //成功回调
    void (^ successCb)() = ^{
        NSLog(@"set power on: %@ success",device.deviceId);
        //        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        //        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        
    };
    
    void (^ failureCb)() = ^{
        NSLog(@"set power on: %@ failed",device.deviceId);
        
        //[box showCtrlFailedHint];
        
    };
    
    if ([device.type isEqualToString:CSHIA_DEVICE_LIGHT_SWITCH] || [device.type isEqualToString:SH_DEVICE_COMMLIGHT]) {
        
        [[NetAPIClient sharedClient] lightOpen:device.deviceId gatewayId:device.gatewayId successCallback:
         successCb failureCallback: failureCb];
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_LIGHT_DIMMER] || [device.type isEqualToString:SH_DEVICE_LEVELLIGHT]) {
        
        [[NetAPIClient sharedClient] lightOpen:device.deviceId gatewayId:device.gatewayId successCallback:
         successCb failureCallback: failureCb];
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_CURTAIN_SWITCH] || [device.type isEqualToString:SH_DEVICE_CURTAIN]) {
        
        [[NetAPIClient sharedClient] curtainOpen:device.deviceId gatewayId:device.gatewayId successCallback:successCb failureCallback:failureCb];
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_AIRCONDITION_GENERAL] || [device.type isEqualToString:SH_DEVICE_AIRCONDITION]) {
        [[NetAPIClient sharedClient] airConditionOpen:device.deviceId gatewayId:device.gatewayId successCallback:successCb failureCallback:failureCb];
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_BGDMUSIC]) {

    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_AIRCONDITION_GENERAL] || [device.type isEqualToString:SH_DEVICE_AIRCONDITION]) {
        [[NetAPIClient sharedClient] groundHeatOpen:device.deviceId gatewayId:device.gatewayId successCallback:successCb failureCallback:failureCb];
    }
}

- (void)turnOff:(UIButton *)sender
{
    [self highlightButton:sender];
    
    NSInteger index = sender.tag - TAG_OFF_BTN;
    SHDevice *device = [self.devices objectAtIndex:index];
    
    
    // __weak BoxView *box = self;//直接在block里面用self以及实例变量会引起循环引用，so... （think:需要在前面加__block?局部变量用作值，因此不会引起self retain？加__weak是为了防止局部变量retain self，arc默认变量为strong reference，可加可不加？只要block不retain self就可以）
    
    //成功回调
    void (^ successCb)() = ^{
        NSLog(@"set power off: %@ success",device.deviceId);
        
        //          NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        //        [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        
    };
    
    void (^ failureCb)() = ^{
        NSLog(@"set power off: %@ failed",device.deviceId);
        
        // [box showCtrlFailedHint];
        
    };
    
    if ([device.type isEqualToString:CSHIA_DEVICE_LIGHT_SWITCH] || [device.type isEqualToString:SH_DEVICE_COMMLIGHT]) {
        
        [[NetAPIClient sharedClient] lightClose:device.deviceId gatewayId:device.gatewayId successCallback:successCb failureCallback:failureCb];
    }
    if ([device.type isEqualToString:CSHIA_DEVICE_LIGHT_DIMMER] || [device.type isEqualToString:SH_DEVICE_LEVELLIGHT]) {
        
        [[NetAPIClient sharedClient] lightClose:device.deviceId gatewayId:device.gatewayId successCallback:successCb failureCallback:failureCb];
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_CURTAIN_SWITCH] || [device.type isEqualToString:SH_DEVICE_CURTAIN]) {
        
        [[NetAPIClient sharedClient] curtainClose:device.deviceId gatewayId:device.gatewayId successCallback:successCb failureCallback:failureCb];
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_AIRCONDITION_GENERAL] || [device.type isEqualToString:SH_DEVICE_AIRCONDITION]) {
        [[NetAPIClient sharedClient] airConditionClose:device.deviceId gatewayId:device.gatewayId successCallback:successCb failureCallback:failureCb];
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_BGDMUSIC]) {
        
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_AIRCONDITION_GENERAL] || [device.type isEqualToString:SH_DEVICE_AIRCONDITION]) {
        [[NetAPIClient sharedClient] groundHeatClose:device.deviceId gatewayId:device.gatewayId successCallback:successCb failureCallback:failureCb];
    }
    
}

- (void)showDetail:(UIButton *)sender
{
    [self highlightButton:sender];
    
    NSInteger index = sender.tag - TAG_MORE_BTN;
    SHDevice *device = [self.devices objectAtIndex:index];
    
    //    device.type = CSHIA_DEVICE_AIRCONDITION_GENERAL;
    //    SHAirconditionState *st = [[SHAirconditionState alloc] init];
    //    st.temperature = 16;
    //    st.mode = @"2";
    //    st.windSpeed = @"2";
    //    device.state = st;
    
    //BoxView *box = self;
    
    //空调弹出控制界面
    if ([device.type isEqualToString:CSHIA_DEVICE_AIRCONDITION_GENERAL] || [device.type isEqualToString:SH_DEVICE_AIRCONDITION]) {
        NSString *nibName = [Util nibNameWithClass:[AirConditionView class]];
        AirConditionView *airConditionView = (AirConditionView *)[[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] objectAtIndex:0];
        airConditionView.backgroundColor = [UIColor clearColor];
        [airConditionView setAirCondition:device];
        [airConditionView setCloseTarget:self selector:@selector(closePopView)];
        

        [self showDeviceControlView:airConditionView];
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_CURTAIN_SWITCH] || [device.type isEqualToString:@"3"]) {//窗帘
        [[NetAPIClient sharedClient] curtainStop:device.deviceId gatewayId:device.gatewayId successCallback:^{
            NSLog(@"curtain stop %@  success",device.deviceId);
            //            [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }failureCallback:^{
            NSLog(@"curtain stop %@  failed",device.deviceId);
            
            //[box showCtrlFailedHint];
        }];
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_CURTAIN_SWITCH] || [device.type isEqualToString:SH_DEVICE_CURTAIN]) {//窗帘
        [[NetAPIClient sharedClient] curtainStop:device.deviceId gatewayId:device.gatewayId successCallback:^{
            NSLog(@"curtain stop %@  success",device.deviceId);
            //            [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }failureCallback:^{
            NSLog(@"curtain stop %@  failed",device.deviceId);
            
            //[box showCtrlFailedHint];
        }];
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_LIGHT_DIMMER] || [device.type isEqualToString:SH_DEVICE_LEVELLIGHT]) {
        
        NSString *nibName = [Util nibNameWithClass:[DimmerlightView class]];
        DimmerlightView *dimmerLightView = (DimmerlightView *)[[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] objectAtIndex:0];
        dimmerLightView.backgroundColor = [UIColor clearColor];
        [dimmerLightView setDimmerlight:device];


        [self showDeviceControlView:dimmerLightView];
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_BGDMUSIC] || [device.type isEqualToString:CSHIA_DEVICE_BGDMUSIC]) {
        NSString *nibName = [Util nibNameWithClass:[BgdMusicView class]];
        BgdMusicView *bgdMusicView = (BgdMusicView *)[[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] objectAtIndex:0];
        bgdMusicView.backgroundColor = [UIColor clearColor];
        [bgdMusicView setCloseTarget:self selector:@selector(closePopView)];
        
        
        [self showDeviceControlView:bgdMusicView];
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_GROUNDHEAT] || [device.type isEqualToString:SH_DEVICE_GROUNDHEAT]) {
        
        NSString *nibName = [Util nibNameWithClass:[GroundHeatView class]];
        GroundHeatView *groundHeatView = (GroundHeatView *)[[[NSBundle mainBundle] loadNibNamed:nibName owner:nil options:nil] objectAtIndex:0];
        groundHeatView.backgroundColor = [UIColor clearColor];
        [groundHeatView setGroundHeat:device];
        [groundHeatView setCloseTarget:self selector:@selector(closePopView)];
        
        
        [self showDeviceControlView:groundHeatView];
    }

}

- (void)showDeviceControlView:(UIView *)deviceControlView
{
    
    UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(justTap)];
    [deviceControlView addGestureRecognizer:gest];
    
    
    UIView *bgdView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    bgdView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    popView = bgdView;
    
    UITapGestureRecognizer *tapGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBgdView)];
    [bgdView addGestureRecognizer:tapGest];
    
    CGRect frame = deviceControlView.frame;
    frame.origin.x = (CGRectGetWidth(bgdView.frame) - CGRectGetWidth(deviceControlView.frame))/2;
    frame.origin.y = (CGRectGetHeight(bgdView.frame) - CGRectGetHeight(deviceControlView.frame))/2;
    deviceControlView.frame = frame;
    
    [bgdView addSubview:deviceControlView];
    [[UIApplication sharedApplication].keyWindow addSubview:bgdView];
}

//仅为了让DimmerlightView和AirConditionView响应事件
- (void)justTap
{
    
}


- (void)tapBgdView
{
    [self closePopView];
}

- (void)closePopView
{
    [popView removeFromSuperview];
}

- (UIImage *)iconForDevice:(SHDevice *)device
{
    NSString *imgName = nil;
    if ([device.type isEqualToString:CSHIA_DEVICE_LIGHT_SWITCH] || [device.type isEqualToString:SH_DEVICE_COMMLIGHT]) {//开关型灯光
        if (device.state.powerOn) {
            imgName = @"lamp_on.png";
        }
        else {
            imgName = @"lamp_off.png";
        }
        
        //        imgName = @"light.png";
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_LIGHT_DIMMER] || [device.type isEqualToString:SH_DEVICE_LEVELLIGHT]) {
        
        if (device.state.powerOn) {
            imgName = @"lamp_on.png";
        }
        else {
            imgName = @"lamp_off.png";
        }
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_CURTAIN_SWITCH]  || [device.type isEqualToString:SH_DEVICE_CURTAIN]) {//窗帘
        if (device.state.powerOn) {
            imgName = @"curtain_on.png";
        }
        else {
            imgName = @"curtain_off.png";
        }
        
        //        imgName = @"curtain.png";
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_AIRCONDITION_GENERAL] || [device.type isEqualToString:SH_DEVICE_AIRCONDITION]) {
        if (device.state.powerOn) {//空调
            imgName = @"aircondition_on.png";
        }
        else {
            imgName = @"aircondition_off.png";
        }
        
        //        imgName = @"aircondition.png";
    }
    else if ([device.type isEqualToString:CSHIA_DEVICE_BGDMUSIC]) {
        if (device.state.powerOn) {
            imgName = @"flat_music_on.png";
        }
        else {
            imgName = @"flat_music_off.png";
        }
    }
    else {
        NSLog(@"%s unknown device type %@",__func__,device.type);
    }
    
    return [UIImage imageNamed:imgName];
    
}

#pragma mark UITableViewDataSource && UITableViewDelegate


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return CGRectGetHeight(self.headerView.frame);
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return BOX_CELL_H;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.devices count] > 0 ? [self.devices count] : 1;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHDevice *device = nil;
    if ([self.devices count]>0) {
        device = [self.devices objectAtIndex:indexPath.row];
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BoxCell"];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"BoxCell"];
    }
    
    for (UIView *v in [cell.contentView subviews])
    {
        [v removeFromSuperview];
    }
    
    if ([self.devices count] == 0 && indexPath.row == 0) {
        UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), BOX_CELL_H)];
        info.text = @"无设备";
        info.textAlignment = NSTextAlignmentCenter;
        info.backgroundColor = [UIColor clearColor];
        info.font = [UIFont systemFontOfSize:14];
        [cell.contentView addSubview:info];
        
        return cell;
    }
    
    //图标
    NSInteger orignX = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 12);
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(orignX, (BOX_CELL_H - DEV_ICON_H)/2, DEV_ICON_W, DEV_ICON_H)];
    imgView.image = [self iconForDevice:device];
    imgView.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:imgView];
    
    
    //名字
    NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 13 : 16);
    CGSize nameMaxSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? CGSizeMake(70, 20) : CGSizeMake(200, 22));
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    CGSize s = [device.name sizeWithFont:font constrainedToSize:nameMaxSize];
    
    NSInteger nameOriginY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 14 : 24);
    UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(imgView.frame)+4, nameOriginY, s.width, s.height)];
    nameLbl.text = device.name;
    nameLbl.font = font;
    nameLbl.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:nameLbl];
    
    //状态
    NSInteger statusFontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 13 : 14);
    NSInteger statusMaxHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 20 : 22);
    
    
    NSString *statusText = device.state.powerOn ? @"开":@"关";
    if ([device.type isEqualToString:SH_DEVICE_CURTAIN] || [device.type isEqualToString:CSHIA_DEVICE_CURTAIN_SWITCH]) {
        statusText = nil;//窗帘不显示开关
    }
    
    CGSize stSize = [statusText sizeWithFont:[UIFont systemFontOfSize:statusFontSize] constrainedToSize:CGSizeMake(40, 30)];
    UILabel *statusLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(nameLbl.frame), CGRectGetMaxY(nameLbl.frame)+2, stSize.width, stSize.height)];
    
    statusLbl.text = statusText;
    statusLbl.textColor = [UIColor grayColor];
    statusLbl.font = [UIFont systemFontOfSize:statusFontSize];
    statusLbl.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:statusLbl];
    
    if ([device.cameraId length] > 0) {
        //
        //        CGRect nameLblFrame = nameLbl.frame;
        //        nameLblFrame.size.width = 50;
        NSInteger cameraSpacing = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 1 : 80);
        UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [cameraBtn setFrame:CGRectMake(CGRectGetMaxX(statusLbl.frame)+cameraSpacing, (BOX_CELL_H - BOX_BTN_H)/2, BOX_BTN_W, BOX_BTN_H)];
        cameraBtn.tag = TAG_CAMERA_BTN + indexPath.row;
        [cameraBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
        [cameraBtn setImage:[UIImage imageNamed:@"camera_normal.png"] forState:UIControlStateNormal];
        [cameraBtn setImage:[UIImage imageNamed:@"camera_hl.png"] forState:UIControlStateHighlighted];
        [cameraBtn addTarget:self action:@selector(viewCameraVideo:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:cameraBtn];
        
    }
    
    
    
    NSString *onBtnImage = @"btn_on_normal.png";
    NSString *onBtnHl = @"btn_on_pressed.png";
    if ([device.type isEqualToString:CSHIA_DEVICE_CURTAIN_SWITCH]  || [device.type isEqualToString:SH_DEVICE_CURTAIN]) {
        onBtnImage = @"curtain_on_normal.png";
        onBtnHl = @"curtain_on_hl.png";
    }
    
    NSString *offBtnImage = @"btn_off_normal.png";
    NSString *offBtnHl = @"btn_on_pressed.png";
    if ([device.type isEqualToString:CSHIA_DEVICE_CURTAIN_SWITCH] || [device.type isEqualToString:SH_DEVICE_CURTAIN]) {
        offBtnImage = @"curtain_off_normal.png";
        offBtnHl = @"curtain_off_hl.png";
    }
    
    NSString *otherBtnImage = @"btn_more_normal.png";
    NSString *otherBtnHl = @"btn_more_pressed.png";
    if ([device.type isEqualToString:CSHIA_DEVICE_CURTAIN_SWITCH] || [device.type isEqualToString:SH_DEVICE_CURTAIN]) {
        otherBtnImage = @"curtain_stop_normal.png";
        otherBtnHl = @"curtain_stop_hl.png";
    }
    
    
    BOOL otherBtnEnabled = YES;
    if ([device.type isEqualToString:CSHIA_DEVICE_LIGHT_SWITCH]  || [device.type isEqualToString:SH_DEVICE_COMMLIGHT]) {
        otherBtnEnabled = NO;
    }
    
    
    //开按钮
    NSInteger onBtnOroginX = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 144 : 400);
    UIButton *onBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [onBtn setFrame:CGRectMake(onBtnOroginX, (BOX_CELL_H - BOX_BTN_H)/2, BOX_BTN_W, BOX_BTN_H)];
    onBtn.tag = TAG_ON_BTN + indexPath.row;
    onBtn.adjustsImageWhenHighlighted = YES;
    [onBtn setImageEdgeInsets:UIEdgeInsetsMake(5, 0, 5, 0)];
    [onBtn setImage:[UIImage imageNamed:onBtnImage] forState:UIControlStateNormal];
    [onBtn setImage:[UIImage imageNamed:onBtnHl] forState:UIControlStateHighlighted];
    [onBtn setImage:[UIImage imageNamed:onBtnHl] forState:UIControlStateSelected];
    [onBtn addTarget:self action:@selector(turnOn:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:onBtn];
    
    //关按钮
    NSInteger btnSpacing = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 6 : 30);
    UIButton *offBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [offBtn setFrame:CGRectMake(CGRectGetMaxX(onBtn.frame) + btnSpacing, (BOX_CELL_H - BOX_BTN_H)/2, BOX_BTN_W, BOX_BTN_H)];
    offBtn.tag = TAG_OFF_BTN + indexPath.row;
    [offBtn setImageEdgeInsets:UIEdgeInsetsMake(5, 0, 5, 0)];
    [offBtn setImage:[UIImage imageNamed:offBtnImage] forState:UIControlStateNormal];
    [offBtn setImage:[UIImage imageNamed:offBtnHl] forState:UIControlStateHighlighted];
    [offBtn setImage:[UIImage imageNamed:offBtnHl] forState:UIControlStateSelected];
    [offBtn addTarget:self action:@selector(turnOff:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:offBtn];
    
    
    //其它按钮
    UIButton *otherBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [otherBtn setFrame:CGRectMake(CGRectGetMaxX(offBtn.frame) + btnSpacing, (BOX_CELL_H - BOX_BTN_H)/2, BOX_BTN_W, BOX_BTN_H)];
    otherBtn.tag = TAG_MORE_BTN + indexPath.row;
    [otherBtn setImageEdgeInsets:UIEdgeInsetsMake(5, 0, 5, 0)];
    [otherBtn setImage:[UIImage imageNamed:otherBtnImage] forState:UIControlStateNormal];
    [otherBtn setImage:[UIImage imageNamed:otherBtnHl] forState:UIControlStateHighlighted];
    [otherBtn setImage:[UIImage imageNamed:otherBtnHl] forState:UIControlStateSelected];
    [otherBtn addTarget:self action:@selector(showDetail:) forControlEvents:UIControlEventTouchUpInside];
    [cell.contentView addSubview:otherBtn];
    otherBtn.enabled = otherBtnEnabled;
    
    
    //自定义分割线
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, BOX_CELL_H - 1, CGRectGetWidth(tableView.frame), 1)];
    sep.backgroundColor = [UIColor grayColor];
    sep.alpha = 0.3;
    [cell.contentView addSubview:sep];
    
    return cell;
}



@end
