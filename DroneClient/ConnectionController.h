//
//  ConnectionController.h
//  DroneClient
//
//  Created by Ben Choi on 2/24/21.
//

#import <UIKit/UIKit.h>
#import <DJISDK/DJISDK.h>
#import <DJIWidget/DJIVideoPreviewer.h>

#define WeakRef(__obj) __weak typeof(self) __obj = self
#define WeakReturn(__obj) if(__obj ==nil)return;
#define ENABLE_DEBUG_MODE 1

NS_ASSUME_NONNULL_BEGIN

@interface ConnectionController : UIViewController
{
    @public NSString *ipAddress;
    @public NSString *port;
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;

    NSInputStream   *inputStream;
    NSOutputStream  *outputStream;

    NSMutableArray  *messages;
    
    // Core Telemetry
    UInt8 _isFlying;
    double _latitude;
    double _longitude;
    double _altitude;
    double _HAG;
    float _velocity_n;
    float _velocity_e;
    float _velocity_d;
    double _yaw;
    double _pitch;
    double _roll;
    
    // Extended Telemetry
    UInt16 _GNSSSatCount;
    UInt8 _GNSSSignal;
    UInt8 _max_height;
    UInt8 _max_dist;
    UInt8 _bat_level;
    UInt8 _bat_warning;
    UInt8 _wind_level;
    UInt8 _dji_cam;
    UInt8 _flight_mode;
    UInt16 _mission_id;
    NSString *_drone_serial;
}
@property (nonatomic, strong) DJICamera* camera;
@property (weak, nonatomic) IBOutlet UIView *fpvPreviewView;
@property (weak, nonatomic) IBOutlet UILabel *serverConnectionStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *uavConnectionStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryOneState;
@property (weak, nonatomic) IBOutlet UILabel *batteryTwoState;
@property (weak, nonatomic) IBOutlet UILabel *aircraftLocationState;
@property (weak, nonatomic) IBOutlet UIButton *debugButton;

@end

NS_ASSUME_NONNULL_END


