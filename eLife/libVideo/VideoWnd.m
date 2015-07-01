//
//  VideoWnd.m
//  iDMSS
//
//  Created by Flying on 11-6-21.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VideoWnd.h"
#import <QuartzCore/QuartzCore.h>

#define MINDISTANCE 30

@implementation VideoWnd

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
	if((self = [super initWithCoder:coder])) 
	{
		// Get the layer
		CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		
	}
	
	return self;
}

- (void)awakeFromNib
{
    UIPinchGestureRecognizer *pin = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinGesture:)];
    [self addGestureRecognizer:pin];
}

- (void)handlePinGesture:(UIPinchGestureRecognizer *)gstr
{
    if (gstr.state == UIGestureRecognizerStateEnded) {
        
        if (self.enablePTZCtrl && [self.delegate respondsToSelector:@selector(videoWnd:scale:)]) {
            [self.delegate videoWnd:self scale:gstr.scale];
        }
    }

}

//创建视频控件
- (void)setupVideoControls
{
//    NSInteger btnWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 60 : 80);
//    NSInteger btnHeight = btnWidth;
//    
//    playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    playBtn.frame = CGRectMake((CGRectGetWidth(videoWnd.frame)-btnWidth)/2, (CGRectGetHeight(videoWnd.frame)-btnHeight)/2 , btnWidth, btnHeight);
//    [playBtn setImage:[UIImage imageNamed:@"VideoPlayNormal"] forState:UIControlStateNormal];
//    [playBtn setImage:[UIImage imageNamed:@"VideoPlayHl"] forState:UIControlStateHighlighted];
//    [playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
//    [videoWnd addSubview:playBtn];
//    //playBtn.backgroundColor = [UIColor redColor];
//    
//    playBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
//    
//    
//    sideBar = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(videoWnd.frame)-SIDE_BAR_WIDTH, 0, SIDE_BAR_WIDTH, CGRectGetHeight(videoWnd.frame))];
//    sideBar.backgroundColor = [UIColor clearColor];
//    sideBar.userInteractionEnabled = YES;
//    [videoWnd addSubview:sideBar];
//    sideBar.hidden = YES;
//    
//    sideBar.autoresizingMask = UIViewAutoresizingFlexibleHeight |  UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
//    sideBar.autoresizesSubviews = YES;
//    
//    
//    CGFloat btnMargin = 4;
//    
//    //视频质量选择按钮
//    bitrateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    CGFloat bitrateBtnW = 60;
//    CGFloat bitrateBtnH = 32;
//    bitrateBtn.frame = CGRectMake(CGRectGetMinX(sideBar.frame)-bitrateBtnW-14, btnMargin, bitrateBtnW, bitrateBtnH);
//    //        [bitrateBtn setBackgroundImage:[UIImage imageNamed:@"VideoCloseNormal"] forState:UIControlStateNormal];
//    //        [bitrateBtn setBackgroundImage:[UIImage imageNamed:@"VideoCloseHl"] forState:UIControlStateHighlighted];
//    [bitrateBtn setTitle:@"清晰" forState:UIControlStateNormal];
//    [bitrateBtn addTarget:self action:@selector(changeBitRate:) forControlEvents:UIControlEventTouchUpInside];
//    [videoWnd addSubview:bitrateBtn];
//    bitrateBtn.hidden = YES;
//    
//    [self setBitrateBtnState:UIControlStateNormal];
//    bitrateBtn.layer.cornerRadius = 5;
//    bitrateBtn.layer.borderWidth = 1;
//    bitrateBtn.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
//    
//    
//    bitrateView = [[BitrateView alloc] initWithText:@[@"清晰",@"流畅"]];
//    CGRect tempFrame = bitrateView.frame;
//    tempFrame.origin.x = CGRectGetMinX(bitrateBtn.frame) - (CGRectGetWidth(bitrateView.frame)- CGRectGetWidth(bitrateBtn.frame))/2;
//    tempFrame.origin.y = CGRectGetMaxY(bitrateBtn.frame)+10;
//    bitrateView.frame = tempFrame;
//    bitrateView.delegate = self;
//    [videoWnd addSubview:bitrateView];
//    bitrateView.hidden = YES;
//    bitrateView.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin  | UIViewAutoresizingFlexibleBottomMargin;
//    bitrateView.selectedIndex = 0;
//    
//    //关闭视频按钮
//    closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    closeBtn.frame = CGRectMake(0, btnMargin, SIDE_BAR_WIDTH, SIDE_BAR_WIDTH);
//    [closeBtn setImage:[UIImage imageNamed:@"VideoCloseNormal"] forState:UIControlStateNormal];
//    [closeBtn setImage:[UIImage imageNamed:@"VideoCloseHl"] forState:UIControlStateHighlighted];
//    [closeBtn setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
//    [closeBtn addTarget:self action:@selector(stopPlaying) forControlEvents:UIControlEventTouchUpInside];
//    [sideBar addSubview:closeBtn];
//    
//    //closeBtn.backgroundColor = [UIColor redColor];
//    closeBtn.autoresizingMask = UIViewAutoresizingNone;
//    
//    
//    //全屏按钮
//    landscapeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    landscapeBtn.frame = CGRectMake(0, CGRectGetHeight(sideBar.frame)-SIDE_BAR_WIDTH-btnMargin, SIDE_BAR_WIDTH, SIDE_BAR_WIDTH);
//    [landscapeBtn setImage:[UIImage imageNamed:@"FullScreenNormal"] forState:UIControlStateNormal];
//    [landscapeBtn setImage:[UIImage imageNamed:@"FullScreenHl"] forState:UIControlStateHighlighted];
//    [landscapeBtn setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
//    [landscapeBtn addTarget:self action:@selector(playFullScreenVideo) forControlEvents:UIControlEventTouchUpInside];
//    [sideBar addSubview:landscapeBtn];
//    landscapeBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
//    //landscapeBtn.backgroundColor = [UIColor redColor];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.enablePTZCtrl) {
        UITouch *touch = [touches anyObject];
        
        startPoint = [touch locationInView:self];
        
        swipeDirection = SwipeDirectionNone;
        
        if ([self.delegate respondsToSelector:@selector(videoWndBeginTouch)]) {
            [self.delegate videoWndBeginTouch];
        }
    }

}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.enablePTZCtrl) {
        UITouch *touch = [touches anyObject];
        
        CGPoint currentPoint = [touch locationInView:self];
        
        CGFloat deltaX = (currentPoint.x - startPoint.x);
        CGFloat deltaY = (currentPoint.y - startPoint.y);
        
        if (fabsf(deltaX) > MINDISTANCE && fabsf(deltaY) > MINDISTANCE) {
            if (deltaX > 0)
            {
                
                swipeDirection = deltaY > 0 ? SwipeDirectionRightDown : SwipeDirectionRightUp;
                
            }
            else {
                swipeDirection = deltaY > 0 ? SwipeDirectionLeftDown : SwipeDirectionLeftUp;
            }
        }
        else if (fabsf(deltaX) > MINDISTANCE) {
            swipeDirection = deltaX > 0 ? SwipeDirectionRight : SwipeDirectionLeft;
        }
        else if (fabsf(deltaY) > MINDISTANCE) {
            swipeDirection = deltaY > 0 ? SwipeDirectionDown : SwipeDirectionUp;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.enablePTZCtrl) {
        if (SwipeDirectionNone != swipeDirection  && [self.delegate respondsToSelector:@selector(videoWnd:swipeToDirection:)]) {
            [self.delegate videoWnd:self swipeToDirection:swipeDirection];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

@end
