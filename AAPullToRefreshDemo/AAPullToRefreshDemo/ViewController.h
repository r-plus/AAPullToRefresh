//
//  ViewController.h
//  AAPullToRefreshDemo
//
//  Created by hyde on 2013/12/08.
//  Copyright (c) 2013年 r-plus. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIScrollViewDelegate>
{
    CGPoint jPreviousTouchPoint;
    int jSwipeDirection;
}

@end
