AAPullToRefresh
===============

All around pull to refresh library.

![DemoGif](http://f.cl.ly/items/1H1r3g3g20241k3f0Y3z/demo3.gif)

## Requirement
- ARC.
- iOS 6 or higher(tested on iOS 6 and 7).

## Install
### CocoaPods
Add `pod 'AAPullToRefresh'` to your Podfile.

### Manually

1. Copy `AAPullToRefresh` directory to your project.

## Usage

    #import "AAPullToRefresh.h"
    ...
    AAPullToRefresh *tv = [self.scrollView addPullToRefreshPosition:AAPullToRefreshPositionTop ActionHandler:^(AAPullToRefresh *v){
        // do something...
        // then must call stopIndicatorAnimation method.
        [v performSelector:@selector(stopIndicatorAnimation) withObject:nil afterDelay:1.0f];
    }];
    
### Customization
#### Property
You can customize below properties.

    tv.imageIcon = [UIImage imageNamed:@"launchpad"];
    tv.borderColor = [UIColor whiteColor];
    tv.borderWidth = 3.0f;
    tv.threshold = 60.0f;
    tv.showPullToRefresh = NO; // also remove KVO observer if set to NO.

#### Method
    - (void)manuallyTriggered;    // Manually trigger the block.
    - (void)setSize:(CGSize)size; // Zoom in/out size.
    
## LICENSE
MIT
