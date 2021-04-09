//
//  ConnectionController.m
//  DroneClient
//
//  Created by Ben Choi on 2/24/21.
//

#import "ConnectionController.h"
#import "DJIUtils.h"
#import "Constants.h"
#import "DroneComms.hpp"
#import "VideoPreviewerSDKAdapter.h"

@interface ConnectionController ()<DJISDKManagerDelegate, DJICameraDelegate, DJIBatteryDelegate, DJIBatteryAggregationDelegate, DJIFlightControllerDelegate, NSStreamDelegate, DJIVideoFeedListener>

@end

@implementation ConnectionController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self configureConnectionToProduct];
//    UIView *newView = [[UIView alloc] initWithFrame:CGRectMake(0,0,1280,720)];
    [[DJIVideoPreviewer instance] setView:self.fpvPreviewView];
    NSLog(@"debug: width %f", self.fpvPreviewView.frame.size.width);
    NSLog(@"debug: height %f", self.fpvPreviewView.frame.size.height);
//    [[DJIVideoPreviewer instance] setView:newView];
//    [self.fpvPreviewView addSubview:newView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[DJIVideoPreviewer instance] setView:nil];
    [[DJISDKManager videoFeeder].primaryVideoFeed removeListener:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self connectToServer];
}

#pragma mark TCP Connection

- (void) sendPacket:(DroneInterface::Packet *)packet {
    NSData *data = [[NSData alloc] initWithBytesNoCopy:packet->m_data.data() length:packet->m_data.size() freeWhenDone:false];
    const unsigned char *bytes= (const unsigned char *)(data.bytes);
    [outputStream write:bytes maxLength:[data length]];
}

- (void) sendPacket_CoreTelemetry {
    DroneInterface::Packet_CoreTelemetry packet_core;
    DroneInterface::Packet packet;
    
//    packet_core.isFlying = self->_isFlying;
//    packet_core.Latitude = self->_Latitude;
//    packet_core.Longitude = self->_Longitude;
//    packet_core.Altitude = self->_Altitude;
//    packet_core.HAG = self->_HAG;
//    packet_core.V_N = self->_velocity_n;
//    packet_core.V_N = self->_velocity_e;
//    packet_core.V_D = self->_velocity_d;
//    packet_core.Yaw = self->_yaw;
//    packet_core.Pitch = self->_pitch;
//    packet_core.Roll = self->_roll;
    
    packet_core.IsFlying = 1;
    packet_core.Latitude = 40.34555;
    packet_core.Longitude = 123.3333333;
    packet_core.Altitude = 1233;
    packet_core.HAG = 123;
    packet_core.V_N = 123.4;
    packet_core.V_E = 11.11123;
    packet_core.V_D = 333;
    packet_core.Yaw = 11;
    packet_core.Pitch = 0;
    packet_core.Roll = -23.4;
    
    packet_core.Serialize(packet);
    
    [self sendPacket:&packet];
}

- (void) sendPacket_ExtendedTelemetry {
    DroneInterface::Packet_ExtendedTelemetry packet_extended;
    DroneInterface::Packet packet;
    
    packet_extended.GNSSSatCount = self->_GNSSSatCount;
    packet_extended.GNSSSignal = self->_GNSSSignal;
    packet_extended.MaxHeight =self->_max_height;
    packet_extended.MaxDist = self->_max_dist;
    packet_extended.BatLevel = self->_bat_level;
    packet_extended.BatWarning = self->_bat_warning;
    packet_extended.WindLevel = self->_wind_level;
    packet_extended.DJICam = self->_dji_cam;
    packet_extended.FlightMode = self->_flight_mode;
    packet_extended.MissionID = self->_mission_id;
    packet_extended.DroneSerial = std::string([self->_drone_serial UTF8String]);
    
    packet_extended.Serialize(packet);
    
    [self sendPacket:&packet];
}

- (void) sendPacket_Image {
    DroneInterface::Packet_Image packet_image;
    DroneInterface::Packet packet;
    
    packet_image.TargetFPS = 30;
    
}

- (void) sendPacket_MessageString:(NSString*)msg ofType:(UInt8)type {
    DroneInterface::Packet_MessageString packet_msg;
    DroneInterface::Packet packet;
    
    packet_msg.Type = type;
    packet_msg.Message = std::string([msg UTF8String]);
    
    packet_msg.Serialize(packet);
    
    [self sendPacket: &packet];
}

- (IBAction)sendDebugMessage:(id)sender {
    [self sendPacket_CoreTelemetry];
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

- (void) configureConnectionToProduct {
    _uavConnectionStatusLabel.text = @"UAV Status: Connecting...";
#if ENABLE_DEBUG_MODE
    [DJISDKManager enableBridgeModeWithBridgeAppIP:@"10.0.0.76"];
#else
    [DJISDKManager startConnectionToProduct];
#endif
    [[DJISDKManager videoFeeder].primaryVideoFeed addListener:self withQueue:nil];
//    [[DJIVideoPreviewer instance] registFrameProcessor:self];
//    [[DJIVideoPreviewer instance] setEnableHardwareDecode:true];
//    [[DJIVideoPreviewer instance] setEnableFastUpload:true];
//    self.previewerAdapter = [VideoPreviewerSDKAdapter adapterWithDefaultSettings];
//    [self.previewerAdapter start];
//    [[DJIVideoPreviewer instance] registFrameProcessor:self];
//    [[DJIVideoPreviewer instance] setEnableHardwareDecode:true];
//    [[DJIVideoPreviewer instance] setEnableFastUpload:true];
//    [[DJIVideoPreviewer instance] setEncoderType:H264EncoderType_H1_Inspire2];
//    [[DJIVideoPreviewer instance] setType:DJIVideoPreviewerTypeNone];
//
    [[DJIVideoPreviewer instance] start];
}
//
//- (void) videoProcessFrame:(VideoFrameYUV *)frame {
//    if ((frame->cv_pixelbuffer_fastupload != nil)) {
//        NSLog(@"HELLOHELLO");
//        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef) frame->cv_pixelbuffer_fastupload;
////        if (*self->_pixelBuffer) {
////            CVPixelBufferRelease(*self->_pixelBuffer);
////        }
//        *self->_pixelBuffer = pixelBuffer;
////        CVPixelBufferRetain(pixelBuffer);
//        
//        UIImage *frame = [self imageFromPixelBuffer:*self->_pixelBuffer];
////
////        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
////        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.png"];
////
////        [UIImagePNGRepresentation(frame) writeToFile:filePath atomically:YES];
//    } else {
//        NSLog(@"SADSAD");
//    }
////    dispatch_async(dispatch_get_main_queue(), ^{
////        self.showImageButton.enabled = self->_pixelBuffer != nil;
////    });
//}
//
//- (BOOL)videoProcessorEnabled {
//    return YES;
//}

- (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef {
    CVImageBufferRef imageBuffer =  pixelBufferRef;
    CIImage* sourceImage = [[CIImage alloc] initWithCVPixelBuffer:imageBuffer options:nil];
    CGSize size = sourceImage.extent.size;
    UIGraphicsBeginImageContext(size);
    CGRect rect;
    rect.origin = CGPointZero;
    rect.size = size;
    UIImage *remImage = [UIImage imageWithCIImage:sourceImage];
    [remImage drawInRect:rect];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

#pragma mark DJISDKManagerDelegate Method

- (void)productConnected:(DJIBaseProduct *)product
{
    if (product){
        _uavConnectionStatusLabel.text = @"UAV Status: Connected";
        
        DJIFlightController* flightController = [DJIUtils fetchFlightController];
        if (flightController) {
            flightController.delegate = self;
        }
        
        DJICamera *camera = [DJIUtils fetchCamera];
        if (camera != nil) {
            camera.delegate = self;
        }
        
        DJIBattery *battery = [DJIUtils fetchBattery];
        if (battery != nil) {
            battery.delegate = self;
        }
        
        [flightController getSerialNumberWithCompletion:^(NSString * serialNumber, NSError * error) {
            self->_drone_serial = serialNumber;
        }];
        
    }
    
    //[self setCoreTelemetryKeyedParameters];
}

- (void)productDisconnected
{
    _uavConnectionStatusLabel.text = @"UAV Status: Not Connected";
}

#pragma mark - DJIVideoFeedListener

-(void)videoFeed:(DJIVideoFeed *)videoFeed didUpdateVideoData:(NSData *)videoData {
    [[DJIVideoPreviewer instance] push:(uint8_t *)videoData.bytes length:(int)videoData.length];
}

#pragma mark - DJICameraDelegate

-(void) camera:(DJICamera*)camera didUpdateSystemState:(DJICameraSystemState*)systemState
{
    if (systemState.mode == DJICameraModePlayback ||
        systemState.mode == DJICameraModeMediaDownload) {
        if (self->needToSetMode) {
            self->needToSetMode = NO;
            [camera setMode:DJICameraModeShootPhoto withCompletion:^(NSError * _Nullable error) {
            }];
        }
    }
}

- (void)camera:(DJICamera *_Nonnull)camera
    didReceiveVideoData:(nonnull uint8_t *)videoBuffer
                 length:(size_t)size
{
    
}

#pragma mark - DJIBatteryDelegate
- (void)battery:(DJIBattery *)battery didUpdateState:(DJIBatteryState *)state
{
    NSLog(@"reeewtf");
    self->_bat_level = state.chargeRemainingInPercent;
}

#pragma mark - DJIBatteryAggregationDelegate
- (void) batteriesDidUpdateState:(DJIBatteryAggregationState *)state {
    NSLog(@"reee");
    self->_bat_level = state.chargeRemainingInPercent;
}

#pragma mark - DJIFlightControllerDelegate

- (void)flightController:(DJIFlightController *)fc didUpdateState:(DJIFlightControllerState *)state
{
    self->_GNSSSignal = [DJIUtils getGNSSSignal:[state GPSSignalLevel]];
    if([DJIUtils gpsStatusIsGood:[state GPSSignalLevel]])
    {
        self->_latitude = state.aircraftLocation.coordinate.latitude;
        self->_longitude = state.aircraftLocation.coordinate.longitude;
        self->_HAG = state.aircraftLocation.altitude;
        self->_altitude = state.takeoffLocationAltitude + self->_HAG;
        
    }
    
    self->_isFlying = state.isFlying ? 1 : 0;
    self->_velocity_n = state.velocityX;
    self->_velocity_e = state.velocityY;
    self->_velocity_d = state.velocityZ;
    self->_yaw = state.attitude.yaw;
    self->_pitch = state.attitude.pitch;
    self->_roll = state.attitude.roll;
    
    self->_GNSSSatCount = state.satelliteCount;
    self->_max_height = state.hasReachedMaxFlightHeight ? 1 : 0;
    self->_max_dist = state.hasReachedMaxFlightRadius ? 1 : 0;
    if (state.isLowerThanSeriousBatteryWarningThreshold) {
        self->_bat_warning = 2;
    } else {
        if (state.isLowerThanBatteryWarningThreshold) {
            self->_bat_warning = 1;
        } else {
            self->_bat_warning = 0;
        }
    }
    self->_wind_level = [DJIUtils getWindLevel:[state windWarning]];
    self->_flight_mode = [DJIUtils getFlightMode:[state flightMode]];
    
    self->_dji_cam = 2;
    self->_mission_id = 0;
}

@end
