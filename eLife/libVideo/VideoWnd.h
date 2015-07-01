//
//  VideoWnd.h
//  iDMSS
//
//  Created by Flying on 11-6-21.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Util.h"


@class VideoWnd;

@protocol VideoWndDelegate <NSObject>

- (void)videoWndBeginTouch;
- (void)videoWnd:(VideoWnd *)videoWnd swipeToDirection:(SwipeDirection)direction;
- (void)videoWnd:(VideoWnd *)videoWnd scale:(CGFloat)scaleFactor;

@end


@interface VideoWnd : UIView {
    
    CGPoint startPoint;
    SwipeDirection swipeDirection;
    
//    UISwipeGestureRecognizer
}

@property (nonatomic,assign) id<VideoWndDelegate> delegate;

@property (nonatomic,assign) BOOL enablePTZCtrl;

@end
