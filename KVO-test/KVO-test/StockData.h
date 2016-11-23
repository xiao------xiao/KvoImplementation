//
//  StockData.h
//  KVO实践
//
//  Created by aliviya on 16/11/22.
//  Copyright © 2016年 coco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StockData : NSObject
{
    NSString *stockName;

}
@property (nonatomic,copy)NSString *price;

@end
