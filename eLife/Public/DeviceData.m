//
//  DeviceData.m
//  eLife
//
//  Created by mac on 14-4-2.
//  Copyright (c) 2014年 mac. All rights reserved.
//

#import "DeviceData.h"

@implementation SHDevice

- (id)init
{
    if (self = [super init]) {
        
        _serviceList = [NSMutableArray array];
    }
    
    return self;
}

- (NSInteger)maxRange
{
    id components = self.range;
    if ([components isKindOfClass:[NSArray class]]) {
        if ([components count] == 2) {
            
            NSInteger max = [[components objectAtIndex:1] integerValue];
            
            return max;
        }
    }
    return 0;
}

- (NSInteger)minRange
{
    id components = self.range;
    if ([components isKindOfClass:[NSArray class]]) {
        if ([components count] == 2) {
            
            NSInteger min = [[components objectAtIndex:0] integerValue];
            
            return min;
        }
    }
    return 0;
    
}

@end


@implementation SHGatewayStatus



@end

@implementation SHGateway

- (id)init
{
    if (self = [super init]) {
        _roomArray = [NSMutableArray array];
        _deviceArray = [NSMutableArray array];
        _sceneModeArray = [NSMutableArray array];
        _alarmZoneArray = [NSMutableArray array];
        _ipcArray = [NSMutableArray array];
        _ammeterArray = [NSMutableArray array];
        _envMonitorArray = [NSMutableArray array];
        _authUserArray = [NSMutableArray array];
        
        _status = [[SHGatewayStatus alloc] init];
    }
    
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[SHGateway class]]) {
        SHGateway *gateway = (SHGateway *)object;
        
        if ([self.serialNumber isEqualToString:gateway.serialNumber]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)isOnline
{
    return self.status.localOnline || self.status.remoteOnline;
}

- (void)putDeviceIntoRoom
{
    for (SHRoom *room in _roomArray)
    {
        [room.deviceArray removeAllObjects];
        
        for (SHDevice *device in _deviceArray)
        {
            if ([device.roomId isEqualToString:room.layoutId]) {
                [room.deviceArray addObject:device];
            }
        }
    }
}


- (NSArray *)devicesForType:(NSString *)deviceType
{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    for (SHDevice *device in self.deviceArray)
    {
        if ([device.type isEqualToString:deviceType]) {
            [tempArray addObject:device];
        }
    }
    
    return tempArray;
}

- (NSString *)roomNameForDevice:(SHDevice *)device
{
    NSString *roomName = @"";
    
    
    if ([device.roomName length] > 0) {
        return device.roomName;
    }
    
    
    for (SHRoom *room in self.roomArray)
    {
        if ([room.layoutId isEqualToString:device.roomId]) {
            roomName = room.layoutName;
            device.roomName = roomName;
            break;
        }
    }
    
    return roomName;

}


@end

@implementation UpnpService

@synthesize type,serviceId,subscrible,controlUrl,eventUrl;

@end

@implementation SHLayout


@end

@implementation SHFloor


@end

@implementation SHRoom


- (id)init
{
    if (self = [super init]) {
        _deviceArray = [NSMutableArray arrayWithCapacity:1];
    }
    
    return self;
}

@end

@implementation SHVideoDevice

- (NSString *)videoUrl
{
    if ([self.ip length] > 0) {
        return [NSString stringWithFormat:@"rtsp://%@:%d",self.ip,self.port];
    }
   
    
    return nil;
    
}

- (NSString *)pubVideoUrl
{
    if ([self.pubIp length] > 0) {
        return [NSString stringWithFormat:@"rtsp://%@:%d",self.pubIp,self.pubPort];
    }
   
    
    return nil;
    
}

@end

@implementation SHStateBase

- (id)init
{
    if (self = [super init]) {
        //_online = YES;
    }
    
    return self;
}

@end

@implementation SHLightState

@end

@implementation SHDimmerLightState



@end

@implementation SHCurtainState

@end

@implementation SHAirconditionState

@end

@implementation SHGroundHeatState



@end

@implementation SHBgdMusicState


@end

@implementation SHAlarmZoneState



@end

@implementation SHAmmeterState



@end



@implementation SHAlarmZone



@end

@implementation SHSceneMode



@end


