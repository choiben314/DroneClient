//
//  TCPViewController.h
//  DroneClient
//
//  Created by Ben Choi on 2/17/21.
//

#import <UIKit/UIKit.h>

#ifndef TCPViewController_h
#define TCPViewController_h


#endif /* TCPViewController_h */

@interface TCPViewController : UIViewController<NSStreamDelegate>
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;

    NSInputStream   *inputStream;
    NSOutputStream  *outputStream;

    NSMutableArray  *messages;
}
@property (weak, nonatomic) IBOutlet UITextField *ipAddressText;
@property (weak, nonatomic) IBOutlet UITextField *portText;
@property (weak, nonatomic) IBOutlet UITextField *dataToSendText;
@property (weak, nonatomic) IBOutlet UITextView *dataRecievedTextView;
@property (weak, nonatomic) IBOutlet UILabel *connectedLabel;


@end
