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
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(10, 70, 60, 40)];
    [btn setTitle:@"Demo1" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(demo1) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)demo1 {
    StackedViewDemo1 *controller = [StackedViewDemo1 new];
    [self.navigationController pushViewController:controller animated:YES];
}
@end
