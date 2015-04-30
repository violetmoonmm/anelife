//
//  HistoryMsgViewController.m
//  eLife
//
//  Created by mac on 14-4-11.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "HistoryMsgViewController.h"
#import "NetAPIClient.h"

@interface HistoryMsgViewController () <UIWebViewDelegate>
{
    IBOutlet UIWebView *_webView;
    IBOutlet UIButton *backBtn;
  
   IBOutlet UIActivityIndicatorView *_indicator;
}

- (IBAction)goBack:(id)sender;

@end

@implementation HistoryMsgViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        CGRect frame = _webView.frame;
        frame.origin.y +=20;
        frame.size.height -=20;
        _webView.frame = frame;
        
        frame = backBtn.frame;
        frame.origin.y +=20;
        backBtn.frame = frame;
        
        
    }
    
    _webView.dataDetectorTypes = UIDataDetectorTypeNone;
    _webView.scrollView.bounces = NO;
    
    [_indicator startAnimating];
    
    NSString *addr = [NSString stringWithFormat:@"http://%@:%d/zwelife_web/hisloginfo/hisloginfo.do",[NetAPIClient sharedClient].serverAddr,[NetAPIClient sharedClient].serverPort];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:addr]];

    [_webView loadRequest:req];
    _webView.delegate =self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    

}

- (IBAction)goBack:(id)sender
{
//    [self dismissViewControllerAnimated:YES completion:NULL];
    
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    NSLog(@"webview  load  finish");

    [_indicator stopAnimating];
    NSString *callId = [NetAPIClient sharedClient].callId;
        NSString *js = [NSString stringWithFormat:@"setCallId('%@')",callId];
    
    [_webView stringByEvaluatingJavaScriptFromString:js];
    
    // Disable user selection
    
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
    
    // Disable callout
    
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)swipeRight
{
    [self goBack:nil];
}


//- (void)goBack
//{
//    
//    [self.navigationController popViewControllerAnimated:YES];
//}



@end
