//
//  ViewController.m
//  AAPullToRefreshDemo
//
//  Created by hyde on 2013/12/08.
//  Copyright (c) 2013年 r-plus. All rights reserved.
//

#import "ViewController.h"
#import "AAPullToRefresh.h"

@interface ViewController ()
@property (nonatomic, strong) UIView *thresholdView;
@property (nonatomic, strong) UIScrollView *scrollView;
@end

typedef enum ScrollDirection {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
    ScrollDirectionCrazy,
} ScrollDirection;

//Restricting diagonal scrolling
typedef NS_ENUM(NSInteger, JUSTVANBLOOM_SCROLLDIRECTION) {
    eScrollLeft = 0,
    eScrollRight = 1,
    eScrollTop = 2,
    eScrollBottom = 3,
    eScrollNone = 4
};

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.delegate = self;
    self.scrollView.maximumZoomScale = 2.0f;
    self.scrollView.contentSize = self.view.bounds.size;
    self.scrollView.alwaysBounceHorizontal = YES;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.backgroundColor = UIColor.lightGrayColor;
    [self.view addSubview:self.scrollView];
    
    CGRect rect = self.scrollView.bounds;
    rect.size.height = self.scrollView.contentSize.height;
    self.thresholdView = [[UIView alloc] initWithFrame:rect];
    self.thresholdView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.thresholdView.userInteractionEnabled = NO;
    self.thresholdView.backgroundColor = UIColor.whiteColor;
    [self.scrollView addSubview:self.thresholdView];
    
    // top
    AAPullToRefresh *tv = [self.scrollView addPullToRefreshPosition:AAPullToRefreshPositionTop actionHandler:^(AAPullToRefresh *v){
        NSLog(@"fire from top");
        [v performSelector:@selector(stopIndicatorAnimation) withObject:nil afterDelay:1.0f];
    }];
    tv.imageIcon = [UIImage imageNamed:@"launchpad"];
    tv.borderColor = [UIColor whiteColor];
    
    // bottom
    AAPullToRefresh *bv = [self.scrollView addPullToRefreshPosition:AAPullToRefreshPositionBottom actionHandler:^(AAPullToRefresh *v){
        NSLog(@"fire from bottom");
        [v performSelector:@selector(stopIndicatorAnimation) withObject:nil afterDelay:1.0f];
    }];
    bv.imageIcon = [UIImage imageNamed:@"launchpad"];
    bv.borderColor = [UIColor whiteColor];
    
    // left
    [self.scrollView addPullToRefreshPosition:AAPullToRefreshPositionLeft actionHandler:^(AAPullToRefresh *v){
        NSLog(@"fire from left");
        [v performSelector:@selector(stopIndicatorAnimation) withObject:nil afterDelay:1.0f];
    }];
    
    // right
    [self.scrollView addPullToRefreshPosition:AAPullToRefreshPositionRight actionHandler:^(AAPullToRefresh *v){
        NSLog(@"fire from right");
        [v performSelector:@selector(stopIndicatorAnimation) withObject:nil afterDelay:1.0f];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillLayoutSubviews
{
    CGRect rect = self.scrollView.bounds;
    rect.size.height = self.scrollView.contentSize.height;
    self.thresholdView.frame = rect;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.thresholdView;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint offset = self.scrollView.contentOffset;
    
    //Cool... Restricting diagonal scrolling
    jSwipeDirection = [self getScrollDirection:jPreviousTouchPoint endPoint:self.scrollView.contentOffset];
    switch (jSwipeDirection) {
        case eScrollLeft:
            self.scrollView.contentOffset = CGPointMake(offset.x, jPreviousTouchPoint.y);
            break;
            
        case eScrollRight:
            self.scrollView.contentOffset = CGPointMake(offset.x, jPreviousTouchPoint.y);
            break;
            
        case eScrollTop:
            self.scrollView.contentOffset = CGPointMake(jPreviousTouchPoint.x, offset.y);
            break;
            
        case eScrollBottom:
            self.scrollView.contentOffset = CGPointMake(jPreviousTouchPoint.x, offset.y);
            break;
            
        default:
            break;
    }
}

-(JUSTVANBLOOM_SCROLLDIRECTION) getScrollDirection : (CGPoint) startPoint endPoint:(CGPoint) endPoint
{
    JUSTVANBLOOM_SCROLLDIRECTION direction = eScrollNone;
    
    JUSTVANBLOOM_SCROLLDIRECTION xDirection;
    JUSTVANBLOOM_SCROLLDIRECTION yDirection;
    
    int xDirectionOffset = startPoint.x - endPoint.x;
    if(xDirectionOffset > 0)
        xDirection = eScrollLeft;
    else
        xDirection = eScrollRight;
    
    int yDirectionOffset = startPoint.y - endPoint.y;
    if(yDirectionOffset > 0)
        yDirection = eScrollTop;
    else
        yDirection = eScrollBottom;
    
    if(abs(xDirectionOffset) > abs(yDirectionOffset))
        direction = xDirection;
    else
        direction = yDirection;
    
    return direction;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    jPreviousTouchPoint = scrollView.contentOffset;
}

@end
