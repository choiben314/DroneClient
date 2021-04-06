//
//  DJIUtils.h
//  DroneClient
//
//  Created by Ben Choi on 3/31/21.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJISDK.h>

#ifndef DJIUtils_h
#define DJIUtils_h


@interface DJIUtils : NSObject
+(NSString *)formattingSeconds:(NSUInteger) seconds;
+(DJIFlightController*) fetchFlightController;
+(DJIBattery*) fetchBattery;
+(DJICamera*) fetchCamera;
+(bool)gpsStatusIsGood:(DJIGPSSignalLevel) signalStatus;
+(int8_t)getGNSSSignal:(DJIGPSSignalLevel) signalStatus;
+(int8_t)getWindLevel:(DJIFlightWindWarning) windWarning;
+(UInt8)getFlightMode:(DJIFlightMode) flightMode;
@end


#endif /* DJIUtils_h */

//- (void)setCoreTelemetryKeyedParameters {
//    DJIKey * isFlyingKey = [DJIFlightControllerKey keyWithParam: DJIFlightControllerParamIsFlying];
//    [[DJISDKManager keyManager] startListeningForChangesOnKey: isFlyingKey
//                                                 withListener: self
//                                               andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
//                                                   if (newKeyedValue) {
//                                                       BOOL isFlying = [newKeyedValue.value boolValue];
//                                                       self->_isFlying = isFlying;
//                                                   }
//                                               }];
//    DJIKey * aircraftLocationKey = [DJIFlightControllerKey keyWithParam: DJIFlightControllerParamAircraftLocation];
//    [[DJISDKManager keyManager] startListeningForChangesOnKey: aircraftLocationKey
//                                                 withListener: self
//                                               andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
//                                                   if (newKeyedValue) {
//                                                       CLLocation *aircraftLocation = (CLLocation *)(newKeyedValue.value);
//                                                       self->_latitude = aircraftLocation.coordinate.latitude;
//                                                       self->_longitude = aircraftLocation.coordinate.longitude;
//                                                       self->_HAG = aircraftLocation.altitude;
//                                                   }
//                                               }];
//    DJIKey * takeoffLocationAltitudeKey = [DJIFlightControllerKey keyWithParam: DJIFlightControllerParamTakeoffLocationAltitude];
//    [[DJISDKManager keyManager] startListeningForChangesOnKey: takeoffLocationAltitudeKey
//                                                 withListener: self
//                                               andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
//                                                   if (newKeyedValue) {
//                                                       double takeoffLocationAltitude = [newKeyedValue.value doubleValue];
//                                                       self->_altitude = takeoffLocationAltitude + self->_HAG;
//                                                   }
//                                               }];
//    DJIKey * velocityKey = [DJIFlightControllerKey keyWithParam: DJIFlightControllerParamVelocity];
//    [[DJISDKManager keyManager] startListeningForChangesOnKey: velocityKey
//                                                 withListener: self
//                                               andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
//                                                   if (newKeyedValue) {
//                                                       DJISDKVector3D *velocity = (DJISDKVector3D *)(newKeyedValue.value);
//                                                       self->_velocity_n = velocity.x;
//                                                       self->_velocity_e = velocity.y;
//                                                       self->_velocity_d = velocity.z;
//                                                   }
//                                               }];
//    DJIKey * attitudeKey = [DJIFlightControllerKey keyWithParam: DJIFlightControllerParamAttitude];
//    [[DJISDKManager keyManager] startListeningForChangesOnKey: attitudeKey
//                                                 withListener: self
//                                               andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
//                                                   if (newKeyedValue) {
//                                                       DJIAttitude *attitude = (__bridge DJIAttitude *)(newKeyedValue.value);
//                                                       self->_yaw = attitude->yaw;
//                                                       self->_pitch = attitude->pitch;
//                                                       self->_roll = attitude->roll;
//                                                   }
//                                               }];
//}
//
//- (void)setExtendedTelemetryKeyedParameters {
//
//}

//        DJIKey * batteryOneKey = [DJIBatteryKey keyWithIndex:0 andParam:DJIBatteryParamChargeRemainingInPercent];
//        DJIKey * batteryTwoKey = [DJIBatteryKey keyWithIndex:1 andParam:DJIBatteryParamChargeRemainingInPercent];
//        [[DJISDKManager keyManager] startListeningForChangesOnKey: batteryOneKey
//                                                     withListener: self

        
//        DJIBattery *battery = [((DJIAircraft*)[DJISDKManager product]).batteries objectAtIndex:0];
//        DJIBattery *battery2 = [((DJIAircraft*)[DJISDKManager product]).batteries objectAtIndex:1];

//        if (battery != nil) {
//            [battery setDelegate:self];
//        }
//        if (battery2 != nil) {
//            [battery2 setDelegate:self];
//        }
