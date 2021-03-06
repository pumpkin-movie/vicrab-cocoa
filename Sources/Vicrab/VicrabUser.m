//
//  VicrabUser.m
//  Vicrab
//
//  Created by Daniel Griesser on 05/05/2017.
//  Copyright © 2017 Vicrab. All rights reserved.
//

#if __has_include(<Vicrab/Vicrab.h>)

#import <Vicrab/VicrabUser.h>
#import <Vicrab/NSDictionary+VicrabSanitize.h>

#else
#import "VicrabUser.h"
#import "NSDictionary+VicrabSanitize.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation VicrabUser

- (instancetype)initWithUserId:(NSString *)userId {
    self = [super init];
    if (self) {
        self.userId = userId;
    }
    return self;
}

- (instancetype)init {
    return [super init];
}

- (NSDictionary<NSString *, id> *)serialize {
    NSMutableDictionary *serializedData = [[NSMutableDictionary alloc] init];
    
    [serializedData setValue:self.userId forKey:@"id"];
    [serializedData setValue:self.email forKey:@"email"];
    [serializedData setValue:self.username forKey:@"username"];
    [serializedData setValue:[self.extra vicrab_sanitize] forKey:@"extra"];
    
    return serializedData;
}


@end

NS_ASSUME_NONNULL_END
