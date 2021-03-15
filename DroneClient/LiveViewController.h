//
//  LiveViewController.h
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

@interface LiveViewController : UIViewController
{
    @public NSString *ipAddress;
    @public NSString *port;
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;

    NSInputStream   *inputStream;
    NSOutputStream  *outputStream;

    NSMutableArray  *messages;
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


