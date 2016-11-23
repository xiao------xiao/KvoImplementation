//
//  ViewController.m
//  KVO-test
//
//  Created by aliviya on 16/11/22.
//  Copyright © 2016年 coco. All rights reserved.
//

#import "ViewController.h"
#import "StockData.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "NSObject+MyKvoCategory.h"
@interface ViewController ()
{
    StockData *stockForKVO;
    UILabel *myLabel;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    stockForKVO = [[StockData alloc] init];
    [stockForKVO setValue:@"searph" forKey:@"stockName"];
    
    [stockForKVO setValue:@"10.0"forKey:@"price"];
    [stockForKVO PG_addObserver:self forKey:@"price" withBlock:^(id observedObject, NSString *observedKey, id oldValue, id newValue) {
        NSLog(@"newValue---%@,oldvalue --- %@",newValue,oldValue);
        dispatch_async(dispatch_get_main_queue(), ^{
              myLabel.text = [stockForKVO valueForKey:@"price"];
        }) ;
    }];
    
    myLabel = [[UILabel alloc]initWithFrame:CGRectMake(100, 100, 100, 30 )];
    myLabel.textColor = [UIColor redColor];
    myLabel.text = [stockForKVO valueForKey:@"price"];
    [self.view addSubview:myLabel];
    
    UIButton * b = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    b.backgroundColor = [UIColor blueColor];
    b.frame = CGRectMake(0, 0, 100, 30);
    
    [b addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:b];
 
}

-(void) buttonAction
{
    [stockForKVO setPrice:@"20.0"];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)dealloc
{
    [stockForKVO PG_removeObserver:self forKey:@"price"];
}
@end
