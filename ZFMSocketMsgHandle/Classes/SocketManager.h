//
//  SocketManager.h
//  EnergyManagement
//
//  Created by CET_朱发明 on 2021/3/15.
//  Copyright © 2021 cet. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@protocol SocketManagerDelegate <NSObject>

- (void)socketdidReceiveMessage:(id)message;

@end

@interface SocketManager : NSObject

@property (nonatomic,weak) id<SocketManagerDelegate> delegate;

+ (instancetype)sharedsocket;

- (void)setAddress:(NSString *)urlStr;

- (void)connection:(void(^)(void))success fail:(void(^)(NSError *error))fail;

- (void)close;

/// 服务器注册 由使用方实现
/// @param apiImpl 实现block
- (void)serviceRegister:(void (^)(void))apiImpl;

@end

NS_ASSUME_NONNULL_END
