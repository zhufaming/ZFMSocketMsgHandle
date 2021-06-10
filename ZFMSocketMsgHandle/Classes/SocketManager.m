//
//  SocketManager.m
//  EnergyManagement
//
//  Created by CET_朱发明 on 2021/3/15.
//  Copyright © 2021 cet. All rights reserved.
//

#import "SocketManager.h"
#import "SRWebSocket.h"
#import <UserNotifications/UserNotifications.h>

typedef void(^ConnectSuccess)(void);
typedef void(^ConnectFaile)(NSError *error);
typedef void(^VoidBlock)(void);

@interface SocketManager()<SRWebSocketDelegate>

@property (nonatomic,strong) SRWebSocket *webSocket;

@property (nonatomic,copy) ConnectSuccess connectSuccess;
@property (nonatomic,copy) ConnectFaile connectFail;

@property (nonatomic,strong) NSTimer *heartBeatTimer;

/// 连接地址
@property (nonatomic,copy) NSString* urlStr;

@property (nonatomic,copy) VoidBlock apiImpl;

@end


@implementation SocketManager

static SocketManager *_scocketManager = nil;

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _scocketManager = [super allocWithZone:zone];
    });
    return _scocketManager;
}
 
+ (instancetype)sharedsocket{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _scocketManager = [[self alloc] init];
    });
    return _scocketManager;
}

- (void)setAddress:(NSString *)urlStr{
    self.urlStr = urlStr;
    self.webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:self.urlStr]];
    self.webSocket.delegate = self;
}

- (void)connection:(void(^)(void))success fail:(void(^)(NSError *error))fail
{
    self.connectSuccess = success;
    self.connectFail = fail;
    if (self.webSocket) {
        [self.webSocket open];
    }else{
        [self reConnect];
    }
}

- (void)close{
    if (self.webSocket){
        //断开连接
        [self.webSocket close];
        self.webSocket = nil;
        //断开连接时销毁心跳
        [self cancelHeartBeat];
    }
}


/// 注册
//- (void)serviceRegister{
//    UserModel *user = [UserManager getUser];
//    /// 做判断 ，主要是在连接中的时候，APP 用户信息 退出登录
//    if (user && user.userId > 0) {
//        NSDictionary *params = @{@"userId":@(user.userId),@"tags":@[@(user.userId)]};
//        HttpRequest *req = [HttpRequest requestWithPath:@"/messageServer/v1/service/web/client" Method:HTTTP_METHOD_POST Params:params];
//        req.isLoading = NO;
//        [[HttpService startRequest:req] subscribeNext:^(HttpResponse *resp) {
//
//        }];
//    }
//}

- (void)serviceRegister:(void (^)(void))apiImpl{
    self.apiImpl = apiImpl;
}

//初始化心跳
- (void)creatHeartBeat{
    
    [self cancelHeartBeat];
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof(self) weakSelf = self;
        //心跳设置为 40s 与 Web一致
        weakSelf.heartBeatTimer = [NSTimer timerWithTimeInterval:40.0
                                                 target:self
                                               selector:@selector(sendHeaderBeat)
                                               userInfo:nil
                                                repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:weakSelf.heartBeatTimer forMode:NSRunLoopCommonModes];
    });
}

- (void)sendHeaderBeat{
    [self sendData:@"heart"];
}

//取消心跳
- (void)cancelHeartBeat{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.heartBeatTimer) {
            [self.heartBeatTimer invalidate];
            self.heartBeatTimer = nil;
        }
    });
}

//重连
- (void)reConnect
{
    [self close];
    /// 再次测试
    self.webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:_urlStr]];
    self.webSocket.delegate = self;
    [self.webSocket open];
}


///发送数据
- (void)sendData:(id)data {
    
    dispatch_queue_t queue =  dispatch_queue_create("send.queue", NULL);
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^{
        if (weakSelf.webSocket) {
            // 只有 SR_OPEN 开启状态才能调 send 方法，不然要崩
            if (weakSelf.webSocket.readyState == SR_OPEN) {
                [weakSelf.webSocket send:data];
                
            }else if (weakSelf.webSocket.readyState == SR_CLOSING || weakSelf.webSocket.readyState == SR_CLOSED) {
                // websocket 断开
                [self reConnect];
            }
//            else if (weakSelf.webSocket.readyState == SR_CONNECTING) {
//                NSLog(@"正在连接中");
//                [self reConnect];
//
//            }
        }
    });
}


#pragma mark webSocket 代理
- (void)webSocketDidOpen:(SRWebSocket*)webSocket{

    NSLog(@"连接成功.....");
    /// 自己服务器注册
    if (self.apiImpl) {
        self.apiImpl();
    }else{
        NSLog(@"未实现服务器注册方法");
    }
    /// 开启心跳
    [self creatHeartBeat];
    
    if (self.connectSuccess) {
        self.connectSuccess();
    }
    
}


- (void)webSocket:(SRWebSocket*)webSocket didReceiveMessage:(id)message{
    NSLog(@"收到消息了:%@",message);
    if (self.delegate && [self.delegate respondsToSelector:@selector(socketdidReceiveMessage:)]) {
        [self.delegate socketdidReceiveMessage:message];
    }
    
//   /// 推送本地消息
//    UNMutableNotificationContent *notiyContent = [UNMutableNotificationContent new];
//    notiyContent.title = @"报警";
//    notiyContent.body = @"xx";
//    notiyContent.userInfo = message;
//    notiyContent.sound = UNNotificationSound.defaultSound;
//
//    /// 触发器
//    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0 repeats:NO];
//
//    /// 触发器创建通知请求 Identifier添加通知的标识符，可以用于移除，更新等操作
//    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"CET" content:notiyContent trigger:trigger];
//
//    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
//    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
//
//    }];
    
}

- (void)webSocket:(SRWebSocket*)webSocket didFailWithError:(NSError*)error{
    NSLog(@"连接失败.....");
    if (self.connectFail) {
        self.connectFail(error);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    NSLog(@"连接断开.....%ld--%@",code,reason);
}

@end
