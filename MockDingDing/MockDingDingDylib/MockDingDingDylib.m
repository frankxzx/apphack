//  weibo: http://weibo.com/xiaoqing28
//  blog:  http://www.alonemonkey.com
//
//  MockDingDingDylib.m
//  MockDingDingDylib
//
//  Created by Xuzixiang on 2019/4/18.
//  Copyright (c) 2019 touchspring. All rights reserved.
//

#import "MockDingDingDylib.h"
#import <CaptainHook/CaptainHook.h>
#import <UIKit/UIKit.h>
#import <Cycript/Cycript.h>
#import <MDCycriptManager.h>
#import <CoreLocation/CoreLocation.h>

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

CHDeclareClass ( CLLocation )

static inline double DoubleRandomBetween(double smallNumber, double bigNumber) {
    double diff = bigNumber - smallNumber;
    double result = (((double) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
    return result;
}

static inline CLLocationCoordinate2D Coordinate2DRoundMake(CLLocationDegrees latitude, CLLocationDegrees longitude) {
    double range = 00.0000099999;
    CLLocationDegrees minlat = latitude;
    CLLocationDegrees maxlat = minlat + range;
    
    CLLocationDegrees minlon = longitude;
    CLLocationDegrees maxlon = minlon + range;
    CLLocationCoordinate2D result = CLLocationCoordinate2DMake(DoubleRandomBetween(minlat, maxlat), DoubleRandomBetween(minlon, maxlon));
    return result;
}

CHOptimizedMethod0 ( self , CLLocationCoordinate2D , CLLocation , coordinate ) {
    CLLocationCoordinate2D result = Coordinate2DRoundMake ( 31.50557 , 120.36226 );
    NSLog(@"%@", [NSString stringWithFormat:@"lat: %f; lon: %f", result.latitude, result.longitude]);
    return result;
}

CHConstructor {
    CHLoadLateClass ( CLLocation );
    CHClassHook ( 0 , CLLocation , coordinate );
}

CHDeclareClass ( AMapGeoFenceManager );

CHMethod ( 0 , BOOL , AMapGeoFenceManager , detectRiskOfFakeLocation ) {
    return NO ;
}

CHMethod ( 0 , BOOL , AMapGeoFenceManager , pausesLocationUpdatesAutomatically ) {
    return NO ;
}

CHConstructor{
    CHLoadLateClass ( AMapGeoFenceManager );
    CHClassHook ( 0 , AMapGeoFenceManager , detectRiskOfFakeLocation );
    CHClassHook ( 0 , AMapGeoFenceManager , pausesLocationUpdatesAutomatically );
}

CHDeclareClass ( AMapLocationManager );

CHMethod ( 0 , BOOL , AMapLocationManager , detectRiskOfFakeLocation ) {
    return NO ;
}

CHMethod ( 0 , BOOL , AMapLocationManager , pausesLocationUpdatesAutomatically ) {
    return NO ;
}

CHConstructor{
    CHLoadLateClass ( AMapLocationManager );
    CHClassHook ( 0 , AMapLocationManager , detectRiskOfFakeLocation );
    CHClassHook ( 0 , AMapLocationManager , pausesLocationUpdatesAutomatically );
}

CHDeclareClass ( DTALocationManager );

CHMethod ( 0 , BOOL , DTALocationManager , detectRiskOfFakeLocation ) {
    return NO ;
}

CHMethod ( 0 , BOOL , DTALocationManager , dt_pausesLocationUpdatesAutomatically ) {
    return NO ;
}

CHConstructor{
    CHLoadLateClass ( DTALocationManager );
    CHClassHook ( 0 , DTALocationManager , detectRiskOfFakeLocation );
    CHClassHook ( 0 , DTALocationManager , dt_pausesLocationUpdatesAutomatically );
}

