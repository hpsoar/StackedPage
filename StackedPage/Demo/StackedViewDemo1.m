//
//  StackedViewDemo1.m
//  StackedPage
//
//  Created by HuangPeng on 8/18/14.
//  Copyright (c) 2014 HuangPeng. All rights reserved.
//

#import "StackedViewDemo1.h"
#import "StackedView.h"

@interface StackedPage1 : StackablePage {
    
}

@end


@implementation StackedPage1

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPage)];
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)selectPage {
    if (self.selected) {
        [self.delegate stackablePageRequiredToBeDeselected:self];
    }
    else {
        [self.delegate stackablePageRequiredToBeSelected:self];
    }
}

@end

@interface StackedViewDemo1 () <StackedViewDataSource, StackedViewDelegate, RefreshIndicatorViewDelegate>

@end

@implementation StackedViewDemo1 {
    NetworkStackedView *_stackedView;
    RefreshIndicatorView *_refreshIndicator;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // 1. create StackedView
    _stackedView = [[NetworkStackedView alloc] initWithFrame:NIRectShift(self.view.bounds, 0, 64)];
    _stackedView.delegate = self;
    _stackedView.dataSource = self;

    // 2. create RefreshIndicatorView
    _refreshIndicator = [[RefreshIndicatorView2 alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
    _refreshIndicator.backgroundColor = [UIColor orangeColor];
    _refreshIndicator.delegate = self;
    
    // 3. setup refresh
    _stackedView.refreshIndicatorView = _refreshIndicator;
    
    [self.view addSubview:_stackedView];
    
    [_stackedView reload];
}

#pragma mark - StackedViewDataSource
- (StackablePage *)stackView:(StackedView *)stackView pageForIndex:(NSInteger)index {
    StackablePage *page = [stackView dequeueReusablePage];
    if (page == nil) {
        page = [[StackedPage1 alloc] initWithFrame:CGRectMake(10, 0, 300, 100)];
        NSArray *colors = @[[UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor yellowColor]];
        static NSInteger index = 0;
        page.backgroundColor = colors[index];
        
        index++;
        if (index >= colors.count) {
            index = 0;
        }
    }
    return page;
}

- (NSInteger)numberOfPagesForStackView:(StackedView *)stackView {
    return 20;
}

#pragma mark - StackedViewDelegate
- (CGFloat)stackedHeightForPageAtIndex:(NSInteger)index {
    return 44.0;
}

- (CGFloat)expandedHeightForPageAtIndex:(NSInteger)index {
    return 360;
}

#pragma mark - RefreshIndicatorViewDelegate

- (void)refreshIndicatorViewBeginRefresh:(RefreshIndicatorView *)refreshIndicatorView {
    [self doRefresh];
}

- (void)doRefresh {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NIDPRINT(@"refresh finished");
        
        [_refreshIndicator finishedRefresh];
    });
}

@end
