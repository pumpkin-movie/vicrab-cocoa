//
//  VicrabSwizzle.m
//  Vicrab
//
//  Created by Daniel Griesser on 31/05/2017.
//  Copyright © 2017 Vicrab. All rights reserved.
//  Original implementation by Yan Rabovik on 05.09.13 https://github.com/rabovik/RSSwizzle


#if __has_include(<Vicrab/Vicrab.h>)

#import <Vicrab/VicrabSwizzle.h>

#else
#import "VicrabSwizzle.h"
#endif

#import <objc/runtime.h>
#include <pthread.h>

#pragma mark - Swizzling

#pragma mark └ VicrabSwizzleInfo

typedef IMP (^VicrabSwizzleImpProvider)(void);

@interface VicrabSwizzleInfo ()
@property(nonatomic, copy) VicrabSwizzleImpProvider impProviderBlock;
@property(nonatomic, readwrite) SEL selector;
@end

@implementation VicrabSwizzleInfo

- (VicrabSwizzleOriginalIMP)getOriginalImplementation {
    NSAssert(_impProviderBlock, nil);
    // Casting IMP to VicrabSwizzleOriginalIMP to force user casting.
    return (VicrabSwizzleOriginalIMP) _impProviderBlock();
}

@end


#pragma mark └ VicrabSwizzle

@implementation VicrabSwizzle

static void swizzle(Class classToSwizzle,
        SEL selector,
        VicrabSwizzleImpFactoryBlock factoryBlock) {
    Method method = class_getInstanceMethod(classToSwizzle, selector);

    NSCAssert(NULL != method,
            @"Selector %@ not found in %@ methods of class %@.",
            NSStringFromSelector(selector),
            class_isMetaClass(classToSwizzle) ? @"class" : @"instance",
            classToSwizzle);

    static pthread_mutex_t gLock = PTHREAD_MUTEX_INITIALIZER;

    // To keep things thread-safe, we fill in the originalIMP later,
    // with the result of the class_replaceMethod call below.
    __block IMP originalIMP = NULL;

    // This block will be called by the client to get original implementation and call it.
    VicrabSwizzleImpProvider originalImpProvider = ^IMP {
        // It's possible that another thread can call the method between the call to
        // class_replaceMethod and its return value being set.
        // So to be sure originalIMP has the right value, we need a lock.

        pthread_mutex_lock(&gLock);

        IMP imp = originalIMP;

        pthread_mutex_unlock(&gLock);

        if (NULL == imp) {
            // If the class does not implement the method
            // we need to find an implementation in one of the superclasses.
            Class superclass = class_getSuperclass(classToSwizzle);
            imp = method_getImplementation(class_getInstanceMethod(superclass, selector));
        }

        return imp;
    };

    VicrabSwizzleInfo *swizzleInfo = [VicrabSwizzleInfo new];
    swizzleInfo.selector = selector;
    swizzleInfo.impProviderBlock = originalImpProvider;

    // We ask the client for the new implementation block.
    // We pass swizzleInfo as an argument to factory block, so the client can
    // call original implementation from the new implementation.
    id newIMPBlock = factoryBlock(swizzleInfo);

    const char *methodType = method_getTypeEncoding(method);

    IMP newIMP = imp_implementationWithBlock(newIMPBlock);

    // Atomically replace the original method with our new implementation.
    // This will ensure that if someone else's code on another thread is messing
    // with the class' method list too, we always have a valid method at all times.
    //
    // If the class does not implement the method itself then
    // class_replaceMethod returns NULL and superclasses's implementation will be used.
    //
    // We need a lock to be sure that originalIMP has the right value in the
    // originalImpProvider block above.

    pthread_mutex_lock(&gLock);

    originalIMP = class_replaceMethod(classToSwizzle, selector, newIMP, methodType);

    pthread_mutex_unlock(&gLock);
}


static NSMutableDictionary *swizzledClassesDictionary() {
    static NSMutableDictionary *swizzledClasses;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzledClasses = [NSMutableDictionary new];
    });
    return swizzledClasses;
}

static NSMutableSet *swizzledClassesForKey(const void *key) {
    NSMutableDictionary *classesDictionary = swizzledClassesDictionary();
    NSValue *keyValue = [NSValue valueWithPointer:key];
    NSMutableSet *swizzledClasses = [classesDictionary objectForKey:keyValue];
    if (!swizzledClasses) {
        swizzledClasses = [NSMutableSet new];
        [classesDictionary setObject:swizzledClasses forKey:keyValue];
    }
    return swizzledClasses;
}

+ (BOOL)swizzleInstanceMethod:(SEL)selector
                      inClass:(Class)classToSwizzle
                newImpFactory:(VicrabSwizzleImpFactoryBlock)factoryBlock
                         mode:(VicrabSwizzleMode)mode
                          key:(const void *)key {
    NSAssert(!(NULL == key && VicrabSwizzleModeAlways != mode),
            @"Key may not be NULL if mode is not VicrabSwizzleModeAlways.");

    @synchronized (swizzledClassesDictionary()) {
        if (key) {
            NSSet *swizzledClasses = swizzledClassesForKey(key);
            if (mode == VicrabSwizzleModeOncePerClass) {
                if ([swizzledClasses containsObject:classToSwizzle]) {
                    return NO;
                }
            } else if (mode == VicrabSwizzleModeOncePerClassAndSuperclasses) {
                for (Class currentClass = classToSwizzle;
                     nil != currentClass;
                     currentClass = class_getSuperclass(currentClass)) {
                    if ([swizzledClasses containsObject:currentClass]) {
                        return NO;
                    }
                }
            }
        }

        swizzle(classToSwizzle, selector, factoryBlock);

        if (key) {
            [swizzledClassesForKey(key) addObject:classToSwizzle];
        }
    }

    return YES;
}

+ (void)swizzleClassMethod:(SEL)selector
                   inClass:(Class)classToSwizzle
             newImpFactory:(VicrabSwizzleImpFactoryBlock)factoryBlock {
    [self swizzleInstanceMethod:selector
                        inClass:object_getClass(classToSwizzle)
                  newImpFactory:factoryBlock
                           mode:VicrabSwizzleModeAlways
                            key:NULL];
}

@end
