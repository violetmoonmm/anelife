//
//  PanelEditViewController.h
//  eLife
//
//  Created by mac mini on 14/10/30.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum{
    BJGridItemNormalMode = 0,
    BJGridItemEditingMode = 1,
}BJMode;
@protocol BJGridItemDelegate;
@interface BJGridItem : UIView{

    NSString *titleText;
    BOOL isEditing;
    BOOL isRemovable;
    UIButton *deleteButton;
//    UIButton *button;
    NSInteger index;
    CGPoint point;//long press point
}
@property(nonatomic) BOOL isEditing;
@property(nonatomic) BOOL isRemovable;
@property(nonatomic) NSInteger index;
@property(assign,nonatomic)id<BJGridItemDelegate> delegate;

@property (nonatomic,strong,readonly) UIImageView *imageView;

- (void)setTitle:(NSString *)title image:(UIImage *)image index:(NSInteger)aIndex removable:(BOOL)removable;
- (void) enableEditing;
- (void) disableEditing;

- (NSString *)title;

@end
@protocol BJGridItemDelegate <NSObject>

@required
- (void) gridItemDidClicked:(BJGridItem *) gridItem;
- (void)gridItemDidEnterEditingMode:(BJGridItem *)gridItem withGestureRecognizer:(UILongPressGestureRecognizer *)recognizer;
- (void) gridItemDidDeleted:(BJGridItem *) gridItem atIndex:(NSInteger)index;
- (void) gridItemDidMoved:(BJGridItem *) gridItem withLocation:(CGPoint)point moveGestureRecognizer:(UILongPressGestureRecognizer*)recognizer;
- (void) gridItemDidEndMoved:(BJGridItem *) gridItem withLocation:(CGPoint)point moveGestureRecognizer:(UILongPressGestureRecognizer*) recognizer;
@end