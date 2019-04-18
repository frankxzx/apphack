//  weibo: http://weibo.com/xiaoqing28
//  blog:  http://www.alonemonkey.com
//
//  MockWechatDylib.m
//  MockWechatDylib
//
//  Created by Xuzixiang on 2019/4/18.
//  Copyright (c) 2019 touchspring. All rights reserved.
//

#import "MockWechatDylib.h"
#import <CaptainHook/CaptainHook.h>
#import <UIKit/UIKit.h>
#import <Cycript/Cycript.h>
#import <MDCycriptManager.h>
#import <objc/runtime.h>
#import <objc/message.h>

CHConstructor{
    printf(INSERT_SUCCESS_WELCOME);
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        
#ifndef __OPTIMIZE__
        CYListenServer(6666);

        MDCycriptManager* manager = [MDCycriptManager sharedInstance];
        [manager loadCycript:NO];

        NSError* error;
        NSString* result = [manager evaluateCycript:@"UIApp" error:&error];
        NSLog(@"result: %@", result);
        if(error.code != 0){
            NSLog(@"error: %@", error.localizedDescription);
        }
#endif
        
    }];
}


CHDeclareClass(CustomViewController)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

//add new method
CHDeclareMethod1(void, CustomViewController, newMethod, NSString*, output){
    NSLog(@"This is a new method : %@", output);
}

#pragma clang diagnostic pop

CHOptimizedClassMethod0(self, void, CustomViewController, classMethod){
    NSLog(@"hook class method");
    CHSuper0(CustomViewController, classMethod);
}

CHOptimizedMethod0(self, NSString*, CustomViewController, getMyName){
    //get origin value
    NSString* originName = CHSuper(0, CustomViewController, getMyName);
    
    NSLog(@"origin name is:%@",originName);
    
    //get property
    NSString* password = CHIvar(self,_password,__strong NSString*);
    
    NSLog(@"password is %@",password);
    
    [self newMethod:@"output"];
    
    //set new property
    self.newProperty = @"newProperty";
    
    NSLog(@"newProperty : %@", self.newProperty);
    
    //change the value
    return @"Xuzixiang";
    
}

//add new property
CHPropertyRetainNonatomic(CustomViewController, NSString*, newProperty, setNewProperty);

CHConstructor{
    CHLoadLateClass(CustomViewController);
    CHClassHook0(CustomViewController, getMyName);
    CHClassHook0(CustomViewController, classMethod);
    
    CHHook0(CustomViewController, newProperty);
    CHHook1(CustomViewController, setNewProperty);
}

/**
 *  修改微信步数#52000
 **/

static int StepCount = 1234;
static NSString *StepCountKey = @"StepCount";
static NSString *HookSettingsFile = @"HookSettings.txt";

CHDeclareClass(WCDeviceStepObject)

//宏格式：参数的个数，返回值的类型，类的名称，selector的名称，selector的类型，selector对应的参数的变量名。
CHMethod(0, unsigned int, WCDeviceStepObject, m7StepCount) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    if (!docDir){ return StepCount;}
    NSString *path = [docDir stringByAppendingPathComponent:HookSettingsFile];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    int value = ((NSNumber *)dict[StepCountKey]).intValue;
    if (value < 0) {
        return CHSuper(0, WCDeviceStepObject, m7StepCount);
    }
    return value;
}

CHDeclareClass(CMessageMgr);

CHMethod(2, void, CMessageMgr, AsyncOnAddMsg, id, arg1, MsgWrap, id, arg2) {
    CHSuper(2, CMessageMgr, AsyncOnAddMsg, arg1, MsgWrap, arg2);
    Ivar uiMessageTypeIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_uiMessageType");
    ptrdiff_t offset = ivar_getOffset(uiMessageTypeIvar);
    unsigned char *stuffBytes = (unsigned char *)(__bridge void *)arg2;
    NSUInteger m_uiMessageType = * ((NSUInteger *)(stuffBytes + offset));

    Ivar nsFromUsrIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_nsFromUsr");
    id m_nsFromUsr = object_getIvar(arg2, nsFromUsrIvar);

    Ivar nsContentIvar = class_getInstanceVariable(objc_getClass("CMessageWrap"), "m_nsContent");
    id m_nsContent = object_getIvar(arg2, nsContentIvar);

    if (m_uiMessageType == 1) {
        //普通消息

        //微信的服务中心
        Class mmServiceCenterClass = NSClassFromString(@"MMServiceCenter");
        id MMServiceCenter = [mmServiceCenterClass performSelector:@selector(defaultCenter)];

        //通讯录管理器
        id contactManager = ((id (*)(id, SEL, Class))objc_msgSend)(MMServiceCenter, @selector(getService:),objc_getClass("CContactMgr"));
        id selfContact = ((id (*)(id, SEL))(void *) objc_msgSend)((id)contactManager, @selector(getSelfContact));

        Ivar nsUsrNameIvar = class_getInstanceVariable([selfContact class], "m_nsUsrName");
        id m_nsUsrName = object_getIvar(selfContact, nsUsrNameIvar);
        BOOL isMesasgeFromMe = NO;
        if ([m_nsFromUsr isEqualToString:m_nsUsrName]) {
            //发给自己的消息
            isMesasgeFromMe = YES;
        }

        if (isMesasgeFromMe)
        {
            if ([m_nsContent rangeOfString:@"修改微信步数#"].location != NSNotFound) {
                NSArray *array = [m_nsContent componentsSeparatedByString:@"#"];
                if (array.count == 2) {
                    StepCount = ((NSNumber *)array[1]).intValue;
                    NSLog(@"微信步数已修改为 : %d", StepCount);
                }
            } else if([m_nsContent rangeOfString:@"恢复微信步数"].location != NSNotFound) {
                StepCount = -1;
                NSLog(@"微信步数已经恢复");
            }
            // save to file
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *docDir = [paths objectAtIndex:0];
            if (!docDir){ return;}
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            NSString *path = [docDir stringByAppendingPathComponent:HookSettingsFile];
            dict[StepCountKey] = [NSNumber numberWithInt:StepCount];
            [dict writeToFile:path atomically:YES];
        }
    }
}


__attribute__((constructor)) static void entry() {
    NSLog(@"微信步数燥起来!");
    CHLoadLateClass(WCDeviceStepObject);
    CHClassHook(0, WCDeviceStepObject,m7StepCount);
    
    CHLoadLateClass(CMessageMgr);
    CHClassHook(2, CMessageMgr, AsyncOnAddMsg, MsgWrap);
}



