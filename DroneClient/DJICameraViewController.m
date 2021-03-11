//
//  DJICameraViewController.m
//  DroneClient
//
//  Created by Ben Choi on 2/24/21.
//

#import "DJICameraViewController.h"

@interface DJICameraViewController ()<DJIFlightControllerDelegate>

@end

@implementation DJICameraViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[DJIVideoPreviewer instance] setView:self.fpvPreviewView];
    [self registerApp];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[DJIVideoPreviewer instance] setView:nil];
    [[DJISDKManager videoFeeder].primaryVideoFeed removeListener:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Custom Methods

- (void)showAlertViewWithTitle:(NSString *)title withMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)registerApp
{
    //Please enter your App key in the "DJISDKAppKey" key in info.plist file.
    [DJISDKManager registerAppWithDelegate:self];
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

#pragma mark DJISDKManagerDelegate Method
- (void)productConnected:(DJIBaseProduct *)product
{
    if(product){
        DJICamera *camera = [self fetchCamera];
        if (camera != nil) {
            camera.delegate = self;
            _videoConnectionStatus.text = @"Video Connected";
        }
        DJIFlightController *fc = ((DJIAircraft*)[DJISDKManager product]).flightController;
        if (fc != nil) {
            fc.delegate = self;
        }
        //Create Flightcontroller altitude key object
        DJIKey * altitudeKey = [DJIFlightControllerKey keyWithParam:DJIFlightControllerParamTakeoffLocationAltitude];
        
        DJIKey * locationKey = [DJIFlightControllerKey keyWithParam:DJIFlightControllerParamCompassHeading];
        [[DJISDKManager keyManager] startListeningForChangesOnKey: altitudeKey
                                                     withListener: self
                                                   andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
                                                       if (newKeyedValue) {
                                                           float newAltitude = [newKeyedValue.value floatValue];
                                                           self.batteryOneState.text = [NSString stringWithFormat: @"Altitude: %.2f", newAltitude];
                                                       }
                                                   }];
        
        DJIKey * compassHeadingKey = [DJIFlightControllerKey keyWithParam: DJIFlightControllerParamCompassHeading];
        [[DJISDKManager keyManager] startListeningForChangesOnKey: compassHeadingKey
                                                     withListener: self
                                                   andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
                                                       if (newKeyedValue) {
                                                           float newCompassHeading = [newKeyedValue.value floatValue];
                                                           self.batteryTwoState.text = [NSString stringWithFormat: @"Compass Heading: %.2f", newCompassHeading];
                                                       }
                                                   }];
        
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
        
        DJIKey * homeLocationKey = [DJIFlightControllerKey keyWithParam: DJIFlightControllerParamHomeLocation];
        [[DJISDKManager keyManager] startListeningForChangesOnKey: homeLocationKey
                                                     withListener: self
                                                   andUpdateBlock: ^(DJIKeyedValue * _Nullable oldKeyedValue, DJIKeyedValue * _Nullable newKeyedValue) {
                                                       if (newKeyedValue) {
//                                                           DJIRCGPSData *newRCGPSData = (__bridge DJIRCGPSData *)(newKeyedValue.value);
//                                                           self.aircraftLocationState.text = [NSString stringWithFormat: @"Coordinates: (%.2f, %.2f)", newRCGPSData->location.latitude, newRCGPSData->location.longitude];
                                                           CLLocation *newLocation = newKeyedValue.value;
                                                           self.aircraftLocationState.text = [NSString stringWithFormat: @"Location: (%.2f, %.2f)", newLocation.altitude, newLocation.coordinate.longitude];
                                                       }
                                                   }];
        
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

- (void)appRegisteredWithError:(NSError *)error
{
    NSString* message = @"Register App Successed!";
    if (error) {
        message = @"Register App Failed! Please enter your App Key and check the network.";
    }else
    {
        NSLog(@"registerAppSuccess");
        
#if ENABLE_DEBUG_MODE
        [DJISDKManager enableBridgeModeWithBridgeAppIP:@"10.30.51.91"];
#else
        [DJISDKManager startConnectionToProduct];
#endif
        [[DJISDKManager videoFeeder].primaryVideoFeed addListener:self withQueue:nil];
        [[DJIVideoPreviewer instance] start];
        
    }
    
    [self showAlertViewWithTitle:@"Register App" withMessage:message];
}

#pragma mark - DJIVideoFeedListener
-(void)videoFeed:(DJIVideoFeed *)videoFeed didUpdateVideoData:(NSData *)videoData {
    [[DJIVideoPreviewer instance] push:(uint8_t *)videoData.bytes length:(int)videoData.length];
}

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

#pragma mark - DJIFlightControllerDelegate

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
