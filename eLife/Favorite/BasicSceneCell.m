//
//  BasicSceneCell.m
//  eLife
//
//  Created by mac on 14-9-9.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "BasicSceneCell.h"
#import "NetAPIClient.h"
#import "MBProgressHUD.h"
#import "SCGIFImageView.h"

#define MarginX 2//x轴左右边缘
#define MarginY 2//y轴上下边缘

#define MAX_ITEM_NUM 4  //最多显示的模式数量

#define SELECTED_COLOR [UIColor colorWithRed:0/255. green:150/255. blue:255/255. alpha:1]

#define NORMAL_COLOR [UIColor colorWithRed:162/255. green:202/255. blue:230/255. alpha:1]

@interface SceneItem : UIView

@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) UIImage *icon;

@property (nonatomic) BOOL selected;

@property (nonatomic,strong) NSString *gatewayId;
@property (nonatomic,strong) NSString *deviceId;

@property (nonatomic,strong) SHSceneMode *scene;
//@property (nonatomic,strong) NSString *ctrlName;

- (void)startAnimating;
- (void)stopAnimating;
@end

@implementation SceneItem
{
    UIImageView *iconView;
    UILabel *nameLbl;
    UIImageView *checkView;
    SCGIFImageView *animateView;

}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
//        CGFloat iconW = 60;
//        CGFloat iconH = 45;
//        CGFloat nameH = 22;
//        CGFloat spacingY = 6;
//        CGFloat originY = (CGRectGetHeight(frame) - iconH - nameH - spacingY)/2;
        
        NSInteger iconH = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 45 : 90);
        NSInteger iconW = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 120);
        NSInteger fontSize = CELL_TEXT_FONT;
        NSInteger nameH = 24;
        NSInteger spacingY = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 4 : 10);
        NSInteger originY = (CGRectGetHeight(frame) - iconH - nameH - spacingY)/2;
        
        iconView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(frame)-iconW)/2, originY, iconW, iconH)];
        iconView.userInteractionEnabled = YES;
        [self addSubview:iconView];
        
        nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(iconView.frame)+spacingY, CGRectGetWidth(frame), nameH)];
        nameLbl.textColor  = [UIColor whiteColor];
        nameLbl.backgroundColor = [UIColor clearColor];
        nameLbl.textAlignment = NSTextAlignmentCenter;
        nameLbl.font = [UIFont systemFontOfSize:fontSize];
        [self addSubview:nameLbl];
        

        //动画
        animateView = [[SCGIFImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
//        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"SceneSwitching" ofType:@"gif"];
//        [animateView setGIFFile:filePath];
//        [animateView setAnimationDuration:2.0];
//        [animateView setAnimationRepeatCount:0];
        animateView.hidden = YES;
        [self addSubview:animateView];

    }
    
    return self;
}

- (void)setName:(NSString *)name
{
    nameLbl.text = name;
    
}

- (void)setIcon:(UIImage *)icon
{
    iconView.image = icon;
}

- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    

    [self setNeedsLayout];
    
}

- (void)layoutSubviews
{
    if (self.selected) {
        checkView.hidden = NO;
        self.backgroundColor = SELECTED_COLOR;
    }
    else {
        checkView.hidden = YES;
        self.backgroundColor = NORMAL_COLOR;
    }
}


- (void)startAnimating
{
    animateView.hidden = NO;
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"SceneSwitching" ofType:@"gif"];
    [animateView setGIFFile:filePath];
    [animateView setAnimationDuration:2.0];
    [animateView setAnimationRepeatCount:0];
    [animateView startAnimating];

}
- (void)stopAnimating
{
    [animateView stopAnimating];
    animateView.hidden = YES;
}

@end



@implementation BasicSceneCell
{
    UIView *bgdView;
    
    NSMutableArray *itemArray;
    
    SceneItem *selectedItem;

}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        itemArray = [NSMutableArray arrayWithCapacity:1];
        
        bgdView = [[UIView alloc] initWithFrame:CGRectMake(MarginX, MarginY, CGRectGetWidth(frame) - MarginX*2, CGRectGetHeight(frame) - MarginY*2)];
        bgdView.backgroundColor = [UIColor colorWithRed:116/255. green:173/255. blue:213/255. alpha:1];
        [self addSubview:bgdView];
        
    
    }
    return self;
}

- (void)selectSceneItem:(UITapGestureRecognizer *)gest
{
    selectedItem.selected = NO;
    
    SceneItem *item = (SceneItem *)gest.view;
    item.selected = YES;
    
    selectedItem = item;
    
    [selectedItem startAnimating];
    

    [[NetAPIClient sharedClient] setSceneMode:item.scene successCallback:^{

        [selectedItem stopAnimating];
        
    }failureCallback:^{
        [selectedItem stopAnimating];

        [self showCtrlFailedHint];
    }];
    

}






- (void)setElements:(NSArray *)elements
{
    
    if ([elements count]) {
        
        NSDictionary *params = [elements objectAtIndex:0];
        
       // _deviceId = [params objectForKey:@"dev_id"];
        _gatewayId = [params objectForKey:@"gateway_sn"];
    }
    
    
    CGFloat spacingX = 2;
    NSInteger originX = 0;
    
    for (NSDictionary *dic in elements) {
        NSString *devId = [dic objectForKey:@"dev_id"];
        NSString *gatewayId = [dic objectForKey:@"gateway_sn"];
        NSString *imgName = [dic objectForKey:@"background"];
        
        CGRect frame = CGRectMake(originX, 0, (CGRectGetWidth(bgdView.frame)-3*spacingX)/MAX_ITEM_NUM, CGRectGetHeight(bgdView.frame));
        
        SceneItem *item = [[SceneItem alloc] initWithFrame:frame];
//        item.name = name;
        item.icon = [UIImage imageNamed:imgName];
        item.deviceId = devId;
        item.gatewayId = gatewayId;
        item.selected = NO;
        [bgdView addSubview:item];
        [itemArray addObject:item];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectSceneItem:)];
        [item addGestureRecognizer:tap];
        
        
        //下一个item的originx
        originX = CGRectGetMaxX(item.frame) + spacingX;
    }
    
}

- (void)associateWithDevices:(NSArray *)sceneArray
{
    for (SceneItem *item in itemArray) {
        
        for (SHSceneMode *sceneMode in sceneArray) {
            if ([item.deviceId isEqualToString:sceneMode.serialNumber]) {
                item.name = sceneMode.name;
                item.scene = sceneMode;
                
                break;
            }
        }

    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)showCtrlFailedHint
{
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"控制失败！";
    [hud show:YES];
    
    [hud hide:YES afterDelay:1.0];
}

@end
