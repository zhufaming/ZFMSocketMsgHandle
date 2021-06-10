//
//  SocketMsgHandle.m
//  CETWebSocket
//
//  Created by CET_朱发明 on 2021/5/31.
//

#import "SocketMsgHandle.h"


@interface SocketMsgHandle()<UNUserNotificationCenterDelegate>


@property (nonatomic,copy) NSString *notificationIdentifier;

@end


NSString *const KeyIdentifier = @"CETSocketMsg";
@implementation SocketMsgHandle

static SocketMsgHandle *_scocketHandle = nil;
+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _scocketHandle = [super allocWithZone:zone];
    });
    return _scocketHandle;
}

+ (instancetype)shareInstance{
    return  [[SocketMsgHandle alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.notificationIdentifier = KeyIdentifier;
        [self registerLocalNotificationCenter];
    }
    return self;
}

+ (void)registreSocktMsgHandleDelegate:(id<SocketMsgHandleDelegate>) delegate{
    [SocketMsgHandle shareInstance].delegate = delegate;
}

/// 注册本地通知
- (void)registerLocalNotificationCenter{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    //监听回调事件
    center.delegate = self;
    //iOS 10 使用以下方法注册，才能得到授权，注册通知以后，会自动注册 deviceToken，如果获取不到 deviceToken，Xcode8下要注意开启 Capability->Push Notification。
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        // Enable or disable features based on authorization.
    }];
    //获取当前的通知设置，UNNotificationSettings 是只读对象，不能直接修改，只能通过以下方法获取
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
    }];
    
//    [self pushLocalNotifactionWithFireTime:5];
}

// 前台调用
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0){
    if ([self.delegate respondsToSelector:@selector(socketNotificationCenter:willPresentNotification:)]) {
        [self.delegate socketNotificationCenter:center willPresentNotification:notification];
    }
//    NSLog(@"1--title---%@", notification.request.content.title);
//    NSLog(@"2--subtitle---%@", notification.request.content.subtitle);
//    NSLog(@"3--userInfo---%@", notification.request.content.userInfo);
//    NSLog(@"4--body---%@", notification.request.content.body);
    
    /// 展现
    if (@available(iOS 14.0, *)) {
        completionHandler(UNNotificationPresentationOptionList | UNNotificationPresentationOptionBanner);
    }else{
        completionHandler(UNNotificationPresentationOptionAlert);
    }
}

// The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from application:didFinishLaunchingWithOptions:.
// 后台点击通知后调用-- (前台、后台、启动)
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler __IOS_AVAILABLE(10.0) __WATCHOS_AVAILABLE(3.0) __TVOS_PROHIBITED{
    
//    NSLog(@"7--title---%@", response.notification.request.content.title);
//    NSLog(@"8--subtitle---%@", response.notification.request.content.subtitle);
//    NSLog(@"9--userInfo---%@", response.notification.request.content.userInfo);
//    NSLog(@"10--body---%@", response.notification.request.content.body);
    if ([self.delegate respondsToSelector:@selector(socketNotificationCenter:didReceiveNotificationResponse:)]) {
        [self.delegate socketNotificationCenter:center didReceiveNotificationResponse:response];
    }
    completionHandler();
}


// 发送通知具体方法
+ (void)pushLocalNotifactionWithFireTime:(NSInteger)alerTime Title:(NSString *)title Body:(NSString *)body UserInfo:(NSDictionary *)userInfo{
    // 使用 UNUserNotificationCenter 来管理通知
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        //需创建一个包含待通知内容的 UNMutableNotificationContent 对象，注意不是 UNNotificationContent ,此对象为不可变对象。
        UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
        content.title = [NSString localizedUserNotificationStringForKey:title arguments:nil];
        content.body = [NSString localizedUserNotificationStringForKey:body
                                                             arguments:nil];
       
        content.sound = [UNNotificationSound defaultSound];
        content.userInfo = userInfo;
        // 在 alertTime 后推送本地推送
        UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger
                                                      triggerWithTimeInterval:alerTime repeats:NO];
        
        UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:KeyIdentifier
                                                                              content:content trigger:trigger];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            
        }];
    }
}

@end
