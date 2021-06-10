//
//  SocketMsgHandle.h
//  CETWebSocket
//
//  Created by CET_朱发明 on 2021/5/31.
//
/**
    消息处理类
 */

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SocketMsgHandleDelegate<NSObject>

/// 应用在前台收到推送
/// @param center 消息中心
/// @param notification 消息
- (void)socketNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification;

/// iOS 10 Support--- 点击通知(前台、后台、启动)
/// @param center 通知中心
/// @param response UNNotificationResponse
- (void)socketNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response;

@end

@interface SocketMsgHandle : NSObject

/// 本地消息通知的唯一标识符
@property (nonatomic,copy,readonly) NSString *notificationIdentifier;

@property (nonatomic,weak) id<SocketMsgHandleDelegate> delegate;


/// 数据按本地通知处理 - 适配ios10 以上
/// @param alerTime 几秒后展示
/// @param title 标题
/// @param body 内容
/// @param userInfo 附加详细展示
+ (void)pushLocalNotifactionWithFireTime:(NSInteger)alerTime Title:(NSString *)title Body:(NSString *)body UserInfo:(NSDictionary *)userInfo;


/// 快速初始化方法
/// @param delegate 实现协议的对象
+ (void)registreSocktMsgHandleDelegate:(id<SocketMsgHandleDelegate>) delegate;

@end

NS_ASSUME_NONNULL_END
