//
//  PanelEditViewController.h
//  eLife
//
//  Created by mac mini on 14/10/30.
//  Copyright (c) 2014年 mac. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "BJGridItem.h"

@implementation BJGridItem
{
    UILabel *titleLabel;

}


@synthesize isEditing,isRemovable,index;
@synthesize delegate;
@synthesize imageView = imageView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizesSubviews = YES;
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pressedLong:)];
        [self addGestureRecognizer:longPress];
        longPress.minimumPressDuration = 0.3;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickItem:)];
        [self addGestureRecognizer:tap];
        
        NSInteger titleHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 20 : 40);
        NSInteger fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 13 : 15);
        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame)-titleHeight, CGRectGetWidth(frame), titleHeight)];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont systemFontOfSize:fontSize];
        titleLabel.textColor = [UIColor blackColor];
        [self addSubview:titleLabel];
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame)-titleHeight)];
        imageView.userInteractionEnabled = YES;
        [self sendSubviewToBack:imageView];
        [self addSubview:imageView];
        
        
        // place a remove button on top right corner for removing item from the board
        deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        float w = 44;
        float h = 44;
        
        [deleteButton setFrame:CGRectMake(CGRectGetWidth(frame)-w,0, w, h)];
        [deleteButton setImage:[UIImage imageNamed:@"PanelDel"] forState:UIControlStateNormal];
        [deleteButton setImageEdgeInsets:UIEdgeInsetsMake(-10, 10, 0, 0)];
        deleteButton.backgroundColor = [UIColor clearColor];
        [deleteButton addTarget:self action:@selector(removeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [deleteButton setHidden:YES];
        [self addSubview:deleteButton];
        
        
    }
    return self;
}


- (void)setTitle:(NSString *)title image:(UIImage *)image index:(NSInteger)aIndex removable:(BOOL)removable
{
   
    titleText = title;
    self.isEditing = NO;
    index = aIndex;
    self.isRemovable = removable;
    
    titleLabel.text = titleText;
    

    [imageView setImage:image];
    
    
}


- (NSString *)title
{
    return titleText;
}

- (void)layoutSubviews
{
   
}


#pragma mark - UI actions

- (void)clickItem:(id)sender {
    [delegate gridItemDidClicked:self];
}
- (void) pressedLong:(UILongPressGestureRecognizer *) gestureRecognizer{
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            point = [gestureRecognizer locationInView:self];
            [delegate gridItemDidEnterEditingMode:self withGestureRecognizer:gestureRecognizer];
            //放大这个item
            [self setAlpha:0.7];
           // NSLog(@"press long began");
            break;
        case UIGestureRecognizerStateEnded:
            
            //[self setAlpha:1.0];
            point = [gestureRecognizer locationInView:self];
            [delegate gridItemDidEndMoved:self withLocation:point moveGestureRecognizer:gestureRecognizer];

            //NSLog(@"press long ended");
            break;
        case UIGestureRecognizerStateFailed:
            //NSLog(@"press long failed");
            break;
        case UIGestureRecognizerStateChanged:
            //移动
            
            [delegate gridItemDidMoved:self withLocation:point moveGestureRecognizer:gestureRecognizer];
           // NSLog(@"press long changed");
            break;
        default:
            //NSLog(@"press long else");
            break;
    }

    
}

- (void) removeButtonClicked:(id) sender  {
    [delegate gridItemDidDeleted:self atIndex:index];
}

#pragma mark - Custom Methods

- (void) enableEditing {
    
    // make the remove button visible
    [deleteButton setHidden:NO];
    [self bringSubviewToFront:deleteButton];
    
    // put item in editing mode
    self.isEditing = YES;
    
  
    [self setAlpha:0.7];
    
}

- (void) disableEditing {

    [deleteButton setHidden:YES];
    [self setAlpha:1.0];
    self.isEditing = NO;
}



@end
