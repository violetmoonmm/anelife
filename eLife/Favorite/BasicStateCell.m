//
//  BasicStateCell.m
//  eLife
//
//  Created by mac on 14-9-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BasicStateCell.h"
#import "DeviceData.h"
#import "NotificationDefine.h"

#define MarginX 2//x轴左右边缘
#define MarginY 2//y轴上下边缘

#define CELL_HEIGHT 30

@interface BasicStateCell () <UITableViewDataSource,UITableViewDelegate>

@end

@implementation BasicStateCell
{

    NSMutableArray *dataSource;//显示的设备
    
    UITableView *tblView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
//        UIImageView *bgdView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
//        bgdView.image = [UIImage imageNamed:@"PageFlipOrange"];
//        [self addSubview:bgdView];
//        
        self.backgroundColor = [UIColor clearColor];
        
    
        dataSource = [NSMutableArray arrayWithCapacity:1];
        
        tblView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame)) style:UITableViewStylePlain];
        tblView.delegate = self;
        tblView.backgroundColor = [UIColor clearColor];
        tblView.dataSource = self;
        tblView.allowsSelection = NO;
        tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
//        [bgdView addSubview:tblView];
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tblView.frame), CGRectGetHeight(tblView.frame))];
        imgView.image = [UIImage imageNamed:@"PageFlipOrange"];
        tblView.backgroundView = imgView;
        
       [self addSubview:tblView];
        

        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceStatusChangeNtf:) name:DeviceStatusChangeNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleQueryStatusNtf:) name:QueryDeviceStatusNotification object:nil];
        
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (void)setDisplayDevices:(NSArray *)devices
{
    
    [dataSource removeAllObjects];
    
    [dataSource addObjectsFromArray:devices];
    
    [tblView reloadData];
}


- (void)handleQueryStatusNtf:(NSNotification *)ntf
{
     SHGateway *gateway = [ntf object];
    
    if ([gateway.serialNumber isEqualToString:self.gatewayId]) {
        [tblView reloadData];
    }
}


- (void)handleDeviceStatusChangeNtf:(NSNotification *)ntf
{
    
    id object = [ntf object];
    
    
    SHDevice *device = (SHDevice *)object;
    
    NSIndexPath *indexPath =  [self indexPathOfDevice:device];
    
    if (indexPath) {
        
        
        [tblView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    
}

- (NSIndexPath *)indexPathOfDevice:(SHDevice *)device
{
    
    if (NSOrderedSame == [device.gatewaySN compare:self.gatewayId options:NSCaseInsensitiveSearch]) {//是当前显示的网关的设备
        
        
        NSInteger row = [dataSource indexOfObject:device];
        if (row != NSNotFound) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:row inSection:0];
            
            return path;
        }
    }
    
    
    return nil;
}


#pragma mark UITableViewDataSource && UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return [dataSource count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *identifier = @"BasicState";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    // Configure the cell...
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    for (UIView *v in [cell.contentView subviews])
    {
        [v removeFromSuperview];
    }
    
    SHDevice *device = [dataSource objectAtIndex:indexPath.row];
    
    NSString *name = device.name;
    NSString *status = nil;
    if (!device.state.online) {
        status = @"?";
    }
    else {
        status = device.state.powerOn ? @"开" : @"关";
    }

    
    NSInteger fontSize = CELL_TEXT_FONT;
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    
    CGSize textSize = [name sizeWithFont:font constrainedToSize:tableView.frame.size];
    
    UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, (CELL_HEIGHT - textSize.height)/2, CGRectGetWidth(tableView.frame)/2+10, textSize.height)];
    nameLbl.text = name;
    nameLbl.font = font;
    nameLbl.textColor = [UIColor whiteColor];
    nameLbl.textAlignment = NSTextAlignmentRight;
    nameLbl.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:nameLbl];
    
    UILabel *statusLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(nameLbl.frame)+10, (CELL_HEIGHT - textSize.height)/2, CGRectGetWidth(tableView.frame)/2-20, textSize.height)];
    statusLbl.text = status;
    statusLbl.font = font;
    statusLbl.textColor = [UIColor whiteColor];
    statusLbl.textAlignment = NSTextAlignmentLeft;
    statusLbl.backgroundColor = [UIColor clearColor];
    [cell.contentView addSubview:statusLbl];
    
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
    
//    cell.contentView.backgroundColor = [UIColor colorWithRed:220/255. green:86/255. blue:45/255. alpha:1];
    
    return cell;
}

@end
