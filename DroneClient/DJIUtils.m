//
//  DJIUtils.m
//  DroneClient
//
//  Created by Ben Choi on 3/31/21.
//

#import "DJIUtils.h"

@implementation DJIUtils

+ (NSString *)formattingSeconds:(NSUInteger)seconds
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSString *formattedTimeString = [formatter stringFromDate:date];
    return formattedTimeString;
}

+ (DJICamera*) fetchCamera {
    
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).camera;
    }else if ([[DJISDKManager product] isKindOfClass:[DJIHandheld class]]){
        return ((DJIHandheld *)[DJISDKManager product]).camera;
    }
    
    return nil;
}

+ (DJIFlightController*) fetchFlightController {
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).flightController;
    }
    
    return nil;
}

+ (DJIBattery*) fetchBattery {
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).battery;
    }
    
    return nil;
}

+ (bool)gpsStatusIsGood:(DJIGPSSignalLevel)signalStatus {
    switch (signalStatus) {
        case DJIGPSSignalLevel5:
            return YES;
        case DJIGPSSignalLevel4:
            return YES;
        case DJIGPSSignalLevel3:
        case DJIGPSSignalLevel2:
        case DJIGPSSignalLevel1:
        case DJIGPSSignalLevel0:
        case DJIGPSSignalLevelNone:
        default:
            return NO;
    }
}

@end
