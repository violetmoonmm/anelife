//
//  FtpResourceViewController.m
//  eLife
//
//  Created by mac on 14-9-22.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "FtpResourceViewController.h"
#import "MBProgressHUD.h"
#import "Util.h"
#import "ZipArchive.h"
#import "NotificationDefine.h"
#import "PublicDefine.h"
#import "FtpShareViewController.h"
#import "NetApiClient.h"

#define TEXT_HEIGHT 44
#define DETAIL_HEIGHT 44

#define PANEL_DIR @"panel"

#define MAX_PANEL 16


@interface FtpResourceViewController () <UITableViewDataSource,UITableViewDelegate>
{
    NSString *_ip;
    NSString *_user;
    NSString *_pswd;
    NSUInteger _port;

    
    MBProgressHUD *hud;
    
    NSMutableArray *_entries;
    
    
    IBOutlet UITableView *_tblView;
    
    IBOutlet UIButton *_btnUpload;
    IBOutlet UIButton *_btnDownload;
    
    NSInteger ftpMethod;//0 下载 1 上传
    
    UIButton *rightBtn;
    
    NSMutableArray *_downloadFiles;//选中下载的文件路径
    NSMutableArray *_downloadPaths;//选中的tablviewcell indexpath
    
    
    
}

@end

@implementation FtpResourceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        _entries = [NSMutableArray arrayWithCapacity:1];
        
        _downloadFiles = [NSMutableArray arrayWithCapacity:1];
        _downloadPaths = [NSMutableArray arrayWithCapacity:1];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDownloadFileNtf:) name:FileDownloadNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [Util unifyStyleOfViewController:self withTitle:@"资源列表"];
    

    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    

    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    addBtn.frame = CGRectMake(0, 0, 44, 44);
    [addBtn addTarget:self action:@selector(clickRightBtn) forControlEvents:UIControlEventTouchUpInside];
    [addBtn setImage:[UIImage imageNamed:@"Download"] forState:UIControlStateNormal];
    //    [returnBtn setTitle:@"添加" forState:UIControlStateNormal];
    UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:addBtn];
    self.navigationItem.rightBarButtonItem = rightBtnItem;
    rightBtn = addBtn;
    
    
    //_tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tblView.backgroundColor = [UIColor colorWithRed:230/255. green:230/255. blue:230/255. alpha:1];
    _tblView.backgroundView = nil;
    
    
    _btnDownload.selected = YES;
    

    
    _user = [self escapeString:_user];
    _pswd = [self escapeString:_pswd];


    [self showWaitingStatus];

    
    [[NetAPIClient sharedClient] getShareFileListOfGateway:self.gateway successCallback:^(NSArray *fileList){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reqTimeout) object:nil];
        
        [hud hide:YES];
        
        for (NSString *entry in fileList) {

            if ([entry rangeOfString:@"panel.zip"].location != NSNotFound) {
                [_entries addObject:entry];
            }

        }

        [_tblView reloadData];
        
    } failureCallback:^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reqTimeout) object:nil];
        
        [hud hide:YES];
        
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"获取共享文件列表失败!";
        
        [hud hide:YES afterDelay:1.5];
    }];
}


- (NSString *)escapeString:(NSString *)string
{
    
    NSString *newString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR("#[]@$ &'()*+,;\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
    
    return newString;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    _tblView.dataSource = nil;
    _tblView.delegate = nil;
    
    
}


#pragma mark Methods


- (NSInteger)numberOfPanels
{
    
    NSString *panelDir = [USERDIR stringByAppendingPathComponent:PANEL_DIR];//panel 目录
    
    NSError *error;
    
    NSArray *subDirArray =  [[NSFileManager defaultManager] contentsOfDirectoryAtPath:panelDir error:&error];
    
    return [subDirArray count];
}

- (void)setRightItem
{
    if (0 == ftpMethod) {
        self.navigationItem.rightBarButtonItem = nil;
        [rightBtn setImage:[UIImage imageNamed:@"Download"] forState:UIControlStateNormal];
        UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
        self.navigationItem.rightBarButtonItem = rightBtnItem;
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
        [rightBtn setImage:[UIImage imageNamed:@"Upload"] forState:UIControlStateNormal];
        UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
        self.navigationItem.rightBarButtonItem = rightBtnItem;
    }
}

- (IBAction)btnDownloadAction:(id)sender
{
    _btnDownload.selected = YES;
    _btnUpload.selected = NO;
    
    ftpMethod = 0;
    
    [self setRightItem];
}

- (IBAction)btnUploadAction:(id)sender
{
    _btnUpload.selected = YES;
    _btnDownload.selected = NO;
    
    ftpMethod = 1;
    
    [self setRightItem];
}

- (void)clickRightBtn
{
    if (ftpMethod == 0 && [_downloadFiles count]) {
        
        [self showWaitingStatus];
        
        [_downloadPaths removeAllObjects];
        [_tblView reloadData];
        
        NSMutableArray *zipPaths = [NSMutableArray arrayWithCapacity:1];
        
        

        
        for (NSString *entry in _downloadFiles) {
            
            
            NSRange r = [entry rangeOfString:@"/" options:NSBackwardsSearch];
            NSRange nameRange = NSMakeRange(r.location + r.length, [entry length] - (r.location + r.length));
            NSString *fileName = [entry substringWithRange:nameRange];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *path = [paths objectAtIndex:0];
           
            NSString *zipPath = [path stringByAppendingPathComponent:fileName];
        
            [zipPaths addObject:zipPath];

        }
        
        [[NetAPIClient sharedClient] downloadShareFiles:_downloadFiles toLocalPaths:zipPaths fromGateway:self.gateway];
    }
}

- (void)swipeRight
{
    [self goBack];
}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
    
//    NSArray *controllerStack = [self.navigationController viewControllers];
//    
//    UIViewController *ftpListController = nil;
//    NSString *nibName = [Util nibNameWithClass:[FtpShareViewController class]];
//    
//    for (UIViewController *vc in controllerStack) {
//        if ([vc.nibName isEqualToString:nibName]) {
//            ftpListController = vc;
//            break;
//        }
//    }
//    
//    [self.navigationController popToViewController:ftpListController animated:YES];
}

- (void)setIp:(NSString *)ip port:(NSUInteger)port user:(NSString *)user pswd:(NSString *)pswd
{
    _ip = ip;
    _port = port;
    _user = user;
    _pswd = pswd;

}


- (void)showWaitingStatus
{
    hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.labelText = @"请稍后...";
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.removeFromSuperViewOnHide = YES;
    [hud show:YES];
    
    [self performSelector:@selector(reqTimeout) withObject:nil afterDelay:10];
}

- (void)reqTimeout
{
    hud.mode = MBProgressHUDModeText;
	hud.labelText = @"请求超时!";
    
    [hud hide:YES afterDelay:1.5];
    
    hud = nil;
}


- (void)showDownloadFinished:(NSString *)fileName
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reqTimeout) object:nil];
    
	hud.mode = MBProgressHUDModeCustomView;
    
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
    
	hud.labelText = [NSString stringWithFormat:@"%@下载完成",fileName];
    
    [hud hide:YES afterDelay:1.0];
}

- (void)showDownLoadPanelNumHint
{
    hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.labelText = @"面板最多添加16个";
    hud.mode = MBProgressHUDModeText;
    hud.removeFromSuperViewOnHide = YES;
    [hud show:YES];
  
    [hud hide:YES afterDelay:1.0];
}

#pragma mark Download
- (void)handleDownloadFileNtf:(NSNotification *)ntf
{
    NSDictionary *dataDic = [ntf userInfo] ;
    NSString *destinationPath = [dataDic objectForKey:@"LocalPath"];
    
  
    NSRange r = [destinationPath rangeOfString:@"/" options:NSBackwardsSearch];
    NSRange nameRange = NSMakeRange(r.location + r.length, [destinationPath length] - (r.location + r.length));
    NSString *fileName = [destinationPath substringWithRange:nameRange];
    
    [self showDownloadFinished:fileName];
    
    if ([fileName rangeOfString:@"."].location != NSNotFound) {
        fileName = [fileName  substringToIndex:[fileName rangeOfString:@"."].location];
    }
    
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //
    //    NSString *documentDirectory = [paths objectAtIndex:0];
    
    NSString *panelDir = [USERDIR stringByAppendingPathComponent:PANEL_DIR];//panel目录
    
    
    NSString *dirPath = [panelDir stringByAppendingPathComponent:fileName];//解压文件路径
    
    ZipArchive *za = [[ZipArchive alloc] init];
    if ([za UnzipOpenFile: destinationPath]) {
        if (![za UnzipFileTo: dirPath overWrite: YES]) {
            [za UnzipCloseFile];
        }
        else {
            NSDictionary *dataDic = [NSDictionary dictionaryWithObjectsAndKeys:dirPath,FtpDownloadFilePathKey, fileName,FtpDownloadFileNameKey,nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:FtpDownloadConfigNotification object:nil userInfo:dataDic];
        }
    }

}

#pragma mark ACFTPClientDelegate

//-(void)client:(ACFTPClient*)client request:(id)request didUpdateStatus:(NSString*)status
//{
//    NSLog(@"%@",status);
//}
//
//-(void)client:(ACFTPClient*)client request:(id)request didFailWithError:(NSError*)error
//{
//    
//    NSLog(@"reques failed %@",error.description);
//    
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reqTimeout) object:nil];
//    
//    hud.mode = MBProgressHUDModeText;
//	hud.labelText = @"请求失败!";
//    
//    [hud hide:YES afterDelay:1.5];
//    
//    hud = nil;
//}
//
//-(void)client:(ACFTPClient*)client request:(id)request didDownloadFile:(NSURL*)sourceURL toDestination:(NSString*)destinationPath
//{
//    
//    BOOL b = [NSThread isMainThread];
//    NSRange r = [destinationPath rangeOfString:@"/" options:NSBackwardsSearch];
//    NSRange nameRange = NSMakeRange(r.location + r.length, [destinationPath length] - (r.location + r.length));
//    NSString *fileName = [destinationPath substringWithRange:nameRange];
//    
//    [self showDownloadFinished:fileName];
//    
//    if ([fileName rangeOfString:@"."].location != NSNotFound) {
//        fileName = [fileName  substringToIndex:[fileName rangeOfString:@"."].location];
//    }
//    
////    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
////    
////    NSString *documentDirectory = [paths objectAtIndex:0];
//    
//    NSString *panelDir = [USERDIR stringByAppendingPathComponent:PANEL_DIR];//panel目录
//    
// 
//    NSString *dirPath = [panelDir stringByAppendingPathComponent:fileName];//解压文件路径
//    
//    ZipArchive *za = [[ZipArchive alloc] init];
//    if ([za UnzipOpenFile: destinationPath]) {
//        if (![za UnzipFileTo: dirPath overWrite: YES]) {
//            [za UnzipCloseFile];
//        }
//        else {
//            NSDictionary *dataDic = [NSDictionary dictionaryWithObjectsAndKeys:dirPath,FtpDownloadFilePathKey, fileName,FtpDownloadFileNameKey,nil];
//            
//            [[NSNotificationCenter defaultCenter] postNotificationName:FtpDownloadConfigNotification object:nil userInfo:dataDic];
//        }
//    }
//
//}
//
//-(void)client:(ACFTPClient*)client request:(id)request didListEntries:(NSArray*)entries
//{
//   
//    
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reqTimeout) object:nil];
//    
//    [hud hide:YES];
//    
//    for (ACFTPEntry *entry in entries) {
//        
//        NSLog(@"ftp list %@",entry.name);
//        
//        if (entry.type == FTPEntryTypeFile) {
//            
//            if ([entry.name rangeOfString:@"panel.zip"].location != NSNotFound) {
//                [_entries addObject:entry];
//            }
//        }
//        
//    }
//    
//    [_tblView reloadData];
//}
//
//-(void)client:(ACFTPClient*)client request:(id)request didUploadFile:(NSString*)sourcePath toDestination:(NSURL*)destination
//{
//    
//}
//
//-(void)client:(ACFTPClient*)client request:(id)request didMakeDirectory:(NSURL*)destination
//{
//    
//}


#pragma mark UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
         return TEXT_HEIGHT;
    }
    
    return DETAIL_HEIGHT;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    
    for (UIView *v in [cell.contentView subviews]) {
        [v removeFromSuperview];
    }
    

   
    
    
    UIFont *textFont = [UIFont systemFontOfSize:16];
    UIFont *detailFont = [UIFont systemFontOfSize:14];
    
  
    if (0 == indexPath.section) {
        if (0 == indexPath.row) {
            
            NSString *title = @"场景";
            CGSize size = [title sizeWithFont:textFont];
            
            UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (TEXT_HEIGHT-size.height)/2, 100, size.height)];
            textLabel.text = title;
            textLabel.font = textFont;
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.textColor = [UIColor blackColor];
            
            [cell.contentView addSubview:textLabel];
            
            
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        else {
            
            
            NSString *entry = nil;
            if ([_entries count]) {
                entry = [_entries objectAtIndex:(indexPath.row-1)];
            }
            
            NSRange r = [entry rangeOfString:@"/" options:NSBackwardsSearch];
            NSRange nameRange = NSMakeRange(r.location + r.length, [entry length] - (r.location + r.length));
            NSString *fileName = [entry substringWithRange:nameRange];

            CGSize size = [fileName sizeWithFont:detailFont];
            
            UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, (DETAIL_HEIGHT-size.height)/2, 280, size.height)];
            textLabel.text = fileName;
            textLabel.font = detailFont;
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.textColor = [UIColor blackColor];
            
            [cell.contentView addSubview:textLabel];
            
            
            
            BOOL checked = NO;
            for (NSIndexPath *tempIndexPath in _downloadPaths) {
                if (NSOrderedSame == [tempIndexPath  compare:indexPath]) {
                    checked = YES;
                    break;
                }
            }
            
            
            cell.accessoryType = checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
    }
    else {
        if (0 == indexPath.row) {
            
            NSString *title = @"其他";
            CGSize size = [title sizeWithFont:textFont];
            
            UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (TEXT_HEIGHT-size.height)/2, 100, size.height)];
            textLabel.text = title;
            textLabel.backgroundColor = [UIColor clearColor];
            textLabel.textColor = [UIColor blackColor];
            textLabel.font = textFont;
            [cell.contentView addSubview:textLabel];
            
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }

    return cell;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        
        return [_entries count]+1;
    }
    
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return  2;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row != 0 && indexPath.section == 0) {
        BOOL checked;
        NSIndexPath *aIndexPath = nil;
        for (NSIndexPath *tempIndexPath in _downloadPaths) {
            if (NSOrderedSame == [tempIndexPath  compare:indexPath]) {
                checked = YES;
                aIndexPath = tempIndexPath;
                break;
            }
        }
        
        
        NSString *entry = [_entries objectAtIndex:indexPath.row - 1];
        
        if (nil != aIndexPath) {//已经选中,取消
            [_downloadPaths removeObject:aIndexPath];
            
            [_downloadFiles removeObject:entry];
            
            [tableView reloadData];
        }
        else {//添加
            
            [_downloadPaths addObject:indexPath];
            
            [_downloadFiles addObject:entry];
            
            [tableView reloadData];
        }
        
        
    }

}

@end
