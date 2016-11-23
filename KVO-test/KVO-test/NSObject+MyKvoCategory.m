//
//  NSObject+MyKvoCategory.m
//  KVO-test
//
//  Created by aliviya on 16/11/22.
//  Copyright © 2016年 coco. All rights reserved.
//

#import "NSObject+MyKvoCategory.h"
#import <objc/runtime.h>
#import <objc/message.h>
NSString *const kPGKVOClassPrefix = @"PGKVOClassPrefix_";
NSString *const kPGKVOAssociatedObservers = @"PGKVOAssociatedObservers";


#pragma mark - PGObservationInfo
@interface PGObservationInfo : NSObject

@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) PGObservingBlock block;
@end
@implementation PGObservationInfo

- (instancetype)initWithObserver:(NSObject *)observer Key:(NSString *)key block:(PGObservingBlock)block
{
    self = [super init];
    if (self) {
        _observer = observer;
        _key = key;
        _block = block;
    }
    return self;
}

@end

@implementation NSObject (MyKvoCategory)

- (void)PG_addObserver:(NSObject *)observer
                forKey:(NSString *)key
             withBlock:(PGObservingBlock)block
{
    unsigned int ivaCount ;
    Ivar * ivars = class_copyIvarList([self class], &ivaCount);
    BOOL hasIvar = NO;
    for (int i = 0; i<ivaCount; i++) {
        // 取出i位置对应的成员变量
        Ivar ivar = ivars[i];
        // 查看成员变量
        const  char *name = ivar_getName(ivar);
        printf("name -- %s",name);
        NSString *nameiVar = [NSString stringWithFormat:@"%s",name];
        if ([nameiVar isEqualToString:[NSString stringWithFormat:@"_%@",key]]) {
            hasIvar = YES;
            SEL newSelector = NSSelectorFromString(setterForGetter(key));
            const char *types = ivar_getTypeEncoding(ivar);
            class_addMethod([self class], newSelector, (IMP)kvo_setter, types);
            
            SEL setterSelector = NSSelectorFromString(setterForGetterOrgin(key));
            Method setterMethod = class_getInstanceMethod([self class], setterSelector);
            Method newMethod = class_getInstanceMethod([self class], newSelector);
            method_exchangeImplementations(setterMethod, newMethod);
            
        }
        
        
    }
    if (!hasIvar) {
        NSLog(@"没有这个属性");
        return;
    }
    
    PGObservationInfo *info = [[PGObservationInfo alloc] initWithObserver:observer Key:key block:block];
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kPGKVOAssociatedObservers));
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge const void *)(kPGKVOAssociatedObservers), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject:info];
}
static NSString * setterForGetterOrgin(NSString *getter)
{
    if (getter.length <= 0) {
        return nil;
    }
    
    // upper case the first letter
    NSString *firstLetter = [[getter substringToIndex:1] uppercaseString];
    NSString *remainingLetters = [getter substringFromIndex:1];
    
    // add 'set' at the begining and ':' at the end
    NSString *setter = [NSString stringWithFormat:@"set%@%@:", firstLetter, remainingLetters];
    
    return setter;
}
static NSString * setterForGetter(NSString *getter)
{
    if (getter.length <= 0) {
        return nil;
    }
    
    // upper case the first letter
    NSString *firstLetter = [[getter substringToIndex:1] uppercaseString];
    NSString *remainingLetters = [getter substringFromIndex:1];
    
    // add 'set' at the begining and ':' at the end
    NSString *setter = [NSString stringWithFormat:@"zyset%@%@:", firstLetter, remainingLetters];
    
    return setter;
}

#pragma mark - Helpers
static NSString * getterForSetter(NSString *setter)
{
    if (setter.length <=0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    
    // remove 'set' at the begining and ':' at the end
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:range];
    
    // lower case the first letter
    NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                       withString:firstLetter];
    
    return key;
}


#pragma mark - Overridden Methods
static void kvo_setter(id self, SEL _cmd, id newValue)
{
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getterForSetter(setterName);
    
    NSLog(@"diaoyong fangfa --%@",getterName);
    
    id oldValue = [self valueForKey:getterName];
    // look up observers and call the blocks
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kPGKVOAssociatedObservers));
    for (PGObservationInfo *each in observers) {
        if ([each.key isEqualToString:getterName]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                each.block(self, getterName, oldValue, newValue);
            });
        }
    }
    NSString *ivarname = [NSString stringWithFormat:@"_%@",getterName];
    const char *aa = [ivarname UTF8String];
    Ivar ivar = class_getInstanceVariable([self class], aa);
    object_setIvar(self, ivar, newValue);
    
    
}

- (void)PG_removeObserver:(NSObject *)observer forKey:(NSString *)key
{
    NSMutableArray* observers = objc_getAssociatedObject(self, (__bridge const void *)(kPGKVOAssociatedObservers));
    
    PGObservationInfo *infoToRemove;
    for (PGObservationInfo* info in observers) {
        if (info.observer == observer && [info.key isEqual:key]) {
            infoToRemove = info;
            break;
        }
    }
    
    [observers removeObject:infoToRemove];
}
@end
