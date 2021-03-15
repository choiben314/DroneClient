//
//  LiveViewController.m
//  DroneClient
//
//  Created by Ben Choi on 2/24/21.
//

#import "LiveViewController.h"
#import "Constants.h"

@interface LiveViewController ()<DJISDKManagerDelegate, DJIBatteryDelegate, DJIFlightControllerDelegate>

@end

@implementation LiveViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self configureConnectionToProduct];
//    [[DJIVideoPreviewer instance] setView:self.fpvPreviewView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [[DJIVideoPreviewer instance] setView:nil];
//    [[DJISDKManager videoFeeder].primaryVideoFeed removeListener:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self connectToServer];
}

#pragma mark TCP Connection

- (void) sendMessage:(NSString *)message {
    NSLog(@"SKDLJFKDSJFLSDF");
    _serverConnectionStatusLabel.text = @"Server Status: Writing...";
    NSString *response  = [NSString stringWithFormat:@"%@", message];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
    _serverConnectionStatusLabel.text = @"Server Status: Connected";
}

- (IBAction)sendDebugMessage:(id)sender {
    [self sendMessage:TEST_MESSAGE];
}

- (void) messageReceived:(NSString *)message {
    [messages addObject:message];
    NSLog(@"%@", message);
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {

    NSLog(@"stream event %lu", streamEvent);

    switch (streamEvent) {

        case NSStreamEventOpenCompleted: {
            NSLog(@"Stream opened");
            _serverConnectionStatusLabel.text = @"Server Status: Connected";
            break;
        }
        case NSStreamEventHasBytesAvailable:
            _serverConnectionStatusLabel.text = @"Server Status: Reading from server";
            if (theStream == inputStream)
            {
                uint8_t buffer[1024];
                NSInteger len;

                while ([inputStream hasBytesAvailable])
                {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0)
                    {
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];

                        if (nil != output)
                        {
                            _serverConnectionStatusLabel.text = @"Server Status: Connected";
                            NSLog(@"server said: %@", output);
                            [self messageReceived:output];
                        }
                    }
                }
            }
            break;

        case NSStreamEventHasSpaceAvailable:
            NSLog(@"Stream has space available now");
            break;

        case NSStreamEventErrorOccurred:
             NSLog(@"%@",[theStream streamError].localizedDescription);
            break;

        case NSStreamEventEndEncountered:

            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            _serverConnectionStatusLabel.text = @"Server Status: Not Connected";
            NSLog(@"close stream");
            break;
        default:
            NSLog(@"Unknown event");
    }

}

- (void)connectToServer {
    _serverConnectionStatusLabel.text = @"Server Status: Connecting...";
    NSLog(@"Setting up connection to %@ : %i", ipAddress, [port intValue]);
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef) ipAddress, [port intValue], &readStream, &writeStream);

    messages = [[NSMutableArray alloc] init];

    [self open];
}

- (void)disconnect {
    _serverConnectionStatusLabel.text = @"Server Status: Disconnecting...";
    [self close];
}

- (void)open {

    NSLog(@"Opening streams.");

    outputStream = (__bridge NSOutputStream *)writeStream;
    inputStream = (__bridge NSInputStream *)readStream;

    [outputStream setDelegate:self];
    [inputStream setDelegate:self];

    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    [outputStream open];
    [inputStream open];
}

- (void)close {
    NSLog(@"Closing streams.");
    [inputStream close];
    [outputStream close];
    [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream setDelegate:nil];
    [outputStream setDelegate:nil];
    inputStream = nil;
    outputStream = nil;
}

#pragma mark DJI Methods

- (void) configureConnectionToProduct
{
    _uavConnectionStatusLabel.text = @"UAV Status: Connecting...";
#if ENABLE_DEBUG_MODE
        [DJISDKManager enableBridgeModeWithBridgeAppIP:@"10.30.51.91"];
#else
        [DJISDKManager startConnectionToProduct];
#endif
        [[DJISDKManager videoFeeder].primaryVideoFeed addListener:self withQueue:nil];
        [[DJIVideoPreviewer instance] start];
}

- (NSString *)formattingSeconds:(NSUInteger)seconds
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    NSString *formattedTimeString = [formatter stringFromDate:date];
    return formattedTimeString;
}

- (DJICamera*) fetchCamera {
    
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

- (DJIFlightController*) fetchFlightController {
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).flightController;
    }
    
    return nil;
}

- (DJIBattery*) fetchBattery {
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).battery;
    }
    
    return nil;
}

- (bool)gpsStatusIsGood:(DJIGPSSignalLevel)signalStatus {
    switch (signalStatus) {
        case DJIGPSSignalLevel5:
            _batteryTwoState.text = @"five";
            return YES;
        case DJIGPSSignalLevel4:
            _batteryTwoState.text = @"four";
            return YES;
        case DJIGPSSignalLevel3:
            _batteryTwoState.text = @"three";
        case DJIGPSSignalLevel2:
            _batteryTwoState.text = @"two";
        case DJIGPSSignalLevel1:
            _batteryTwoState.text = @"one";
        case DJIGPSSignalLevel0:
            _batteryTwoState.text = @"zero";
        case DJIGPSSignalLevelNone:
            _batteryTwoState.text = @"nnnone";
        default:
            return NO;
    }
}

#pragma mark DJISDKManagerDelegate Method
- (void)productConnected:(DJIBaseProduct *)product
{
    if (product){
        _uavConnectionStatusLabel.text = @"UAV Status: Connected";
        
//        DJICamera *camera = [self fetchCamera];
//        if (camera != nil) {
//            camera.delegate = self;
//            _serverConnectionStatusLabel.text = @"Video Connected";
//        }
        DJIFlightController* flightController = [self fetchFlightController];
        if (flightController) {
            flightController.delegate = self;
        }

//        DJIKey * altitudeKey = [DJIFlightControllerKey keyWithParam:DJIFlightControllerParamTakeoffLocationAltitude];
//
//        DJIKey * locationKey = [DJIFlightControllerKey keyWithParam:DJIFlightControllerParamCompassHeading];
//        [[DJISDKManager keyManager] startListeningForChangesOnKey: altitudeKey
//                                                     withListener: self
//                                                   andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
//                                                       if (newKeyedValue) {
//                                                           float newAltitude = [newKeyedValue.value floatValue];
//                                                           self.batteryOneState.text = [NSString stringWithFormat: @"Altitude: %.2f", newAltitude];
//                                                       }
//                                                   }];
//
//        DJIKey * compassHeadingKey = [DJIFlightControllerKey keyWithParam: DJIFlightControllerParamCompassHeading];
//        [[DJISDKManager keyManager] startListeningForChangesOnKey: compassHeadingKey
//                                                     withListener: self
//                                                   andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
//                                                       if (newKeyedValue) {
//                                                           float newCompassHeading = [newKeyedValue.value floatValue];
//                                                           self.batteryTwoState.text = [NSString stringWithFormat: @"Compass Heading: %.2f", newCompassHeading];
//                                                       }
//                                                   }];
//
//        DJIKey * batteryOneKey = [DJIBatteryKey keyWithIndex:0 andParam:DJIBatteryParamChargeRemainingInPercent];
//        DJIKey * batteryTwoKey = [DJIBatteryKey keyWithIndex:1 andParam:DJIBatteryParamChargeRemainingInPercent];
//        [[DJISDKManager keyManager] startListeningForChangesOnKey: batteryOneKey
//                                                     withListener: self
//                                                   andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
//                                                       if (newKeyedValue) {
//                                                           double newBatteryOne = [newKeyedValue.value doubleValue];
//                                                           self.aircraftLocationState.text = [NSString stringWithFormat: @"Battery: %f", newBatteryOne];
//                                                       }
//                                                   }];
        
//        DJIKey * homeLocationKey = [DJIFlightControllerKey keyWithParam: DJIFlightControllerParamHomeLocation];
//        [[DJISDKManager keyManager] startListeningForChangesOnKey: homeLocationKey
//                                                     withListener: self
//                                                   andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
//                                                       if (newKeyedValue) {
////                                                           DJIRCGPSData *newRCGPSData = (__bridge DJIRCGPSData *)(newKeyedValue.value);
////                                                           self.aircraftLocationState.text = [NSString stringWithFormat: @"Coordinates: (%.2f, %.2f)", newRCGPSData->location.latitude, newRCGPSData->location.longitude];
//                                                           CLLocation *newLocation = newKeyedValue.value;
//                                                           self.aircraftLocationState.text = [NSString stringWithFormat: @"Location: (%.2f, %.2f)", newLocation.altitude, newLocation.coordinate.longitude];
//                                                       }
//                                                   }];
        
//        DJIKey * attitudeDataKey = [DJIFlightControllerKey keyWithParam: DJIFlightControllerParamAttitude];
//        [[DJISDKManager keyManager] startListeningForChangesOnKey: attitudeDataKey
//                                                     withListener: self
//                                                   andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
//                                                       if (newKeyedValue) {
//                                                           DJIAttitude *newAttitude = (__bridge DJIAttitude *)(newKeyedValue.value);
//                                                           self.aircraftLocationState.text = [NSString stringWithFormat: @"Pitch: %.2f, Roll: %.2f, Yaw: %.2f", newAttitude->pitch, newAttitude->roll, newAttitude->yaw];
//                                                       }
//                                                   }];
        
//        [[DJISDKManager keyManager] startListeningForChangesOnKey: locationKey
//                                                     withListener: self
//                                                   andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
//
//                                                       //This block is called ONLY when the altitude value is changed
//                                                       if (newKeyedValue) {
//                                                           CLLocation *newLocation = (CLLocation *) newKeyedValue.value;
//                                                           _batteryTwoState.text = [NSString stringWithFormat: @"Latitude: %.2f", newLocation.coordinate.latitude];
//                                                       } else {
//                                                           CLLocation *newLocation = (CLLocation *) oldKeyedValue.value;
//                                                           _batteryTwoState.text = [NSString stringWithFormat: @"Latitude: %.2f", newLocation.coordinate.latitude];
//                                                       }
//                                                   }];
        
//        DJIKey * chargeRemainingOfBattery2Key = [DJIFlightControllerKey keyWithParam: DJIFlightControllerParamCompassHeading];

//        [[DJISDKManager keyManager] getValueForKey:locationKey withCompletion:^(DJIKeyedValue * _Nullable keyedValue, NSError * _Nullable error) {
//            CLLocation *newLocation = (CLLocation *) keyedValue.value;
//            _batteryTwoState.text = [NSString stringWithFormat: @"Latitude: %.2f", newLocation.coordinate.latitude];
//        }];
        
//        [[DJISDKManager keyManager] getValueForKey:chargeRemainingOfBattery2Key withCompletion:^(DJIKeyedValue * _Nullable keyedValue, NSError * _Nullable error) {
//            DJIBatteryAggregationState *batteryChargeValue = keyedValue.value;
//            _batteryTwoState.text = [NSString stringWithFormat: @"Battery 2 %%: %ld", batteryChargeValue.voltage * 100];
//            double value = [keyedValue.value doubleValue];
//            _batteryTwoState.text = [NSString stringWithFormat: @"Compass heading: %f", value];
//        }];
        
//        DJIBattery *battery = [((DJIAircraft*)[DJISDKManager product]).batteries objectAtIndex:0];
//        DJIBattery *battery2 = [((DJIAircraft*)[DJISDKManager product]).batteries objectAtIndex:1];

//        if (battery != nil) {
//            [battery setDelegate:self];
//        }
//        if (battery2 != nil) {
//            [battery2 setDelegate:self];
//        }
    }
}

#pragma mark - DJIVideoFeedListener

//-(void)videoFeed:(DJIVideoFeed *)videoFeed didUpdateVideoData:(NSData *)videoData {
//    [[DJIVideoPreviewer instance] push:(uint8_t *)videoData.bytes length:(int)videoData.length];
//}

//#pragma mark - DJICameraDelegate
//
//-(void) camera:(DJICamera*)camera didUpdateSystemState:(DJICameraSystemState*)systemState
//{
//    _batteryOneState.text = @"WOEFJOKWEF";
//}
//
//- (void)camera:(DJICamera *_Nonnull)camera
//    didReceiveVideoData:(nonnull uint8_t *)videoBuffer
//                 length:(size_t)size
//{
//    _batteryOneState.text = @"WOEFJOKWEF";
//}

#pragma mark - DJIBatteryDelegate

//- (void)battery:(DJIBattery *_Nonnull)battery didUpdateState:(DJIBatteryState *_Nonnull)state
//{
//    _batteryOneState.text = [NSString stringWithFormat:@"Battery 1 %%: %0.2lu", state.chargeRemainingInPercent];
//    _batteryTwoState.text = [NSString stringWithFormat:@"Battery 2 %%: %0.2lu", state.chargeRemainingInPercent];
//}

- (void)productDisconnected
{
    _uavConnectionStatusLabel.text = @"UAV Status: Not Connected";
}

#pragma mark - DJIFlightControllerDelegate

- (void)flightController:(DJIFlightController *)fc didUpdateState:(DJIFlightControllerState *)state
{
    //Update the drone location and heading
    NSDate *currentTime = [NSDate date];
    if([self gpsStatusIsGood:state.GPSSignalLevel])
    {
        CLLocation* location = [[CLLocation alloc] initWithCoordinate:state.aircraftLocation.coordinate altitude:state.altitude horizontalAccuracy:0.0 verticalAccuracy:0.0 timestamp:currentTime];
//        double radianYaw = RADIAN(state.attitude.yaw);
        
//        [self.delegate recievedLocation:location withYaw:radianYaw];
//        self.hasRecievedLocation = YES;
    }
    
//    [self subscribeToDevices];
    
    
//    double lateralSpeed = sqrtf(state.velocityX*state.velocityX + state.velocityY*state.velocityY);
//    [self.delegate setLateralSpeed:lateralSpeed];
//
//    double heightMeters = state.altitude;
//    [self.delegate setHeight:heightMeters];
    
    
    if([self gpsStatusIsGood:state.GPSSignalLevel])
    {
        CLLocation* homeLoc = [[CLLocation alloc] initWithCoordinate:state.homeLocation.coordinate altitude:0 horizontalAccuracy:0.0 verticalAccuracy:0.0 timestamp:currentTime];
        CLLocation* curLoc = [[CLLocation alloc] initWithCoordinate:state.aircraftLocation.coordinate altitude:state.altitude horizontalAccuracy:0.0 verticalAccuracy:0.0 timestamp:currentTime];
        
        CLLocationDistance distMeters = [homeLoc distanceFromLocation:curLoc];
        _aircraftLocationState.text = [NSString stringWithFormat: @"Lat: %.2f, Lon: %.2f, Alt: %.2f", state.aircraftLocation.coordinate.latitude, state.aircraftLocation.coordinate.longitude, state.altitude];
        _batteryOneState.text = [NSString stringWithFormat: @"Satellite count: %d", state.satelliteCount];
    } else {
        _batteryOneState.text = [NSString stringWithFormat: @"Satellite count: %d", state.satelliteCount];
    }
//    if(NULL != self.takeOffTime) {
//        NSTimeInterval elapsedTime = [currentTime timeIntervalSinceDate:self.takeOffTime];
//        [self.delegate setFlightTime:elapsedTime];
//    }
    
    //Set our flight mode depending on whether the vehicle is flying
//    if (state.areMotorsOn || state.isFlying) {
//        [self.delegate goFlightMode];
//    } else {
//        [self.delegate goPlanningMode];
//    }
}
//- (void)flightController:(DJIFlightController *_Nonnull)fc didUpdateState:(DJIFlightControllerState *_Nonnull)state
//{
//    _batteryOneState.text = [NSString stringWithFormat: @"Altitude: %.2f", state.aircraftLocation.coordinate.latitude];
//}

//- (void)flightController:(DJIFlightController *_Nonnull)fc didUpdateState:(DJIFlightControllerState *_Nonnull)state {
//
//    CLLocation *myCurrentLocation = state.aircraftLocation;
//    _batteryTwoState.text = [NSString stringWithFormat: @"Latitude: %.2f", myCurrentLocation.coordinate.latitude];
//}
@end
