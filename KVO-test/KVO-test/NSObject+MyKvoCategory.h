//
//  NSObject+MyKvoCategory.h
//  KVO-test
//
//  Created by aliviya on 16/11/22.
//  Copyright © 2016年 coco. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^PGObservingBlock)(id observedObject, NSString *observedKey, id oldValue, id newValue);

@interface NSObject (MyKvoCategory)
- (void)PG_addObserver:(NSObject *)observer
                forKey:(NSString *)key
             withBlock:(PGObservingBlock)block;
- (void)PG_removeObserver:(NSObject *)observer forKey:(NSString *)key;
@end
