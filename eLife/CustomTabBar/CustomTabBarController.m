//
//  CustomTabBarController.m
//  eLife
//
//  Created by mac on 14-3-15.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "CustomTabBarController.h"

#define TABBAR_HEIGHT ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 49 : 56)

@interface CustomTabBarController ()
{

    UIImage     *_barBgdImage;  //整个tabBar的背景
    NSArray     *_titleList; //tabbar item文字
    NSArray     *_normalImageList;   //非选中效果的tabBarItem数组
    NSArray     *_selectedImageList;     //选中效果的tabBarItem数组
    
    CustomTabBarView   *_tabBarView;
    
}

@end

@implementation CustomTabBarController
@synthesize slctdIndex = _slctIndex;


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    
}

- (CustomTabBarView *)customTabBar
{
    return _tabBarView;
}

- (void)setBadgeValue:(NSString *)aValue
              atIndex:(int)aIndex
{
    [_tabBarView setBadgeValue:aValue atIndex:aIndex];
}

- (void)displayTrackPoint:(BOOL)yesOrNo atIndex:(int)aIndex
{
    [_tabBarView displayTrackPoint:yesOrNo atIndex:aIndex];
}

- (void)setSlctdIndex:(NSUInteger)slctdIndex {

    [self setSelectedIndex:slctdIndex];
    _slctIndex = slctdIndex;
    
    [_tabBarView selectItemAtIndex:slctdIndex];
}



- (void)customTabBar:(CustomTabBarView *)customtabBar selectedItemAtIndex:(NSInteger)aIndex
{
    [self setSlctdIndex:aIndex];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    
    NSArray *titles = [NSArray arrayWithObjects:@"常用",@"控制",@"服务",@"更多", nil];
    UIImage *bgdImage = [UIImage imageNamed:@"TabBar.png"];
    NSArray *normalImages = [NSArray arrayWithObjects:[UIImage imageNamed:@"FavoriteNormal"],[UIImage imageNamed:@"CtrlNormal"],[UIImage imageNamed:@"ServiceNormal"],[UIImage imageNamed:@"MoreNormal"], nil];
    NSArray *selectedImages = [NSArray arrayWithObjects:[UIImage imageNamed:@"FavoriteSelected"],[UIImage imageNamed:@"CtrlSelected"],[UIImage imageNamed:@"ServiceSelected"],[UIImage imageNamed:@"MoreSelected"], nil];
    
   _tabBarView = [[CustomTabBarView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame)-TABBAR_HEIGHT, CGRectGetWidth(self.view.frame), TABBAR_HEIGHT)];
    [_tabBarView setTitleList:titles iconList:normalImages selectedIconList:selectedImages bgdImage:bgdImage];
    _tabBarView.delegate = self;
    _tabBarView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;

    [self.view addSubview:_tabBarView];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITabBarDelegate
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
   // self.selectedIndex = [tabBar.items indexOfObject:item];
}

@end



