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
@property (weak, nonatomic) IBOutlet UIScrollView *iPadScrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *iPhoneScrollView;

@end

@implementation ViewController

static inline BOOL IsPad()
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIScrollView *scrollView = IsPad() ? self.iPadScrollView : self.iPhoneScrollView;
    scrollView.contentSize = CGSizeMake(scrollView.bounds.size.width, scrollView.bounds.size.height * 1.2f);
    scrollView.contentInset = UIEdgeInsetsMake(64,0,0,0);
    
    // top
    AAPullToRefresh *tv = [scrollView addPullToRefreshPosition:AAPullToRefreshPositionTop ActionHandler:^(AAPullToRefresh *v){
        NSLog(@"fire from top");
        [v performSelector:@selector(stopIndicatorAnimation) withObject:nil afterDelay:1.0f];
    }];
    tv.imageIcon = [UIImage imageNamed:@"launchpad"];
    tv.borderColor = [UIColor whiteColor];
    
    // bottom
    AAPullToRefresh *bv = [scrollView addPullToRefreshPosition:AAPullToRefreshPositionBottom ActionHandler:^(AAPullToRefresh *v){
        NSLog(@"fire from bottom");
        [v performSelector:@selector(stopIndicatorAnimation) withObject:nil afterDelay:1.0f];
    }];
    bv.imageIcon = [UIImage imageNamed:@"launchpad"];
    bv.borderColor = [UIColor whiteColor];
    
    // left
    [scrollView addPullToRefreshPosition:AAPullToRefreshPositionLeft ActionHandler:^(AAPullToRefresh *v){
        NSLog(@"fire from left");
        [v performSelector:@selector(stopIndicatorAnimation) withObject:nil afterDelay:1.0f];
    }];
    
    // right
    [scrollView addPullToRefreshPosition:AAPullToRefreshPositionRight ActionHandler:^(AAPullToRefresh *v){
        NSLog(@"fire from right");
        [v performSelector:@selector(stopIndicatorAnimation) withObject:nil afterDelay:1.0f];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
