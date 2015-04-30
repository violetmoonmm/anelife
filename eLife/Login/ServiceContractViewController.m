//
//  ServiceContractViewController.m
//  eLife
//
//  Created by 陈杰 on 15/1/6.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "ServiceContractViewController.h"

#import "UserRegisterViewController.h"
#import "Util.h"

@interface ServiceContractViewController () <UIWebViewDelegate>
{
    IBOutlet UIWebView *webView;
    IBOutlet UIActivityIndicatorView *indicator;
    IBOutlet UIButton *regBtn;
    
}

@end

@implementation ServiceContractViewController

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
    
    
    [Util unifyStyleOfViewController:self withTitle:@"服务协议"];
    
    
    [Util unifyGoBackButtonWithTarget:self selector:@selector(goBack)];
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    if (!self.registering) {
        CGRect frame = webView.frame;
        frame.size.height = CGRectGetHeight(self.view.frame);
        webView.frame = frame;
        
        
        regBtn.hidden = YES;
    }
    
    
    [indicator startAnimating];
    
    webView.delegate = self;
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"agreement" ofType:@"html"]];
    
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
}


- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)agree:(id)sender
{
    NSString *nibName = [Util nibNameWithClass:[UserRegisterViewController class]];
    UserRegisterViewController *viewController = [[UserRegisterViewController alloc] initWithNibName:nibName bundle:nil];
    
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController pushViewController:viewController animated:YES];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [indicator stopAnimating];
}

@end
