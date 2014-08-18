//
//  ViewController.m
//  StackedPage
//
//  Created by HuangPeng on 8/18/14.
//  Copyright (c) 2014 HuangPeng. All rights reserved.
//

#import "ViewController.h"
#import "StackedViewDemo1.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor redColor];
    
    StackedViewDemo1 *controller = [StackedViewDemo1 new];
    [self.navigationController pushViewController:controller animated:YES];
    
}

@end
