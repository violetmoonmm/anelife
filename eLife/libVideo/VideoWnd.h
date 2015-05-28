//
//  VideoWnd.h
//  iDMSS
//
//  Created by Flying on 11-6-21.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _SwipeDirection
{
    SwipeDirectionNone      = 0,
    SwipeDirectionUp        = 1,
    SwipeDirectionDown      = 2,
    SwipeDirectionLeft      = 3,
    SwipeDirectionRight     = 4,
    SwipeDirectionLeftUp    = 5,
    SwipeDirectionRightUp   = 6,
    SwipeDirectionLeftDown  = 7,
    SwipeDirectionRightDown = 8
    
} SwipeDirection;


@class VideoWnd;

@protocol VideoWndDelegate <NSObject>

- (void)videoWnd:(VideoWnd *)videoWnd swipeToDirection:(SwipeDirection)direction;

@end


@interface VideoWnd : UIView {
    
    CGPoint startPoint;
    SwipeDirection swipeDirection;
    
//    UISwipeGestureRecognizer
}

@property (nonatomic,assign) id<VideoWndDelegate> delegate;

@property (nonatomic,assign) BOOL enablePTZCtrl;

@end
