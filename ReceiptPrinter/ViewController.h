//
//  ViewController.h
//  ReceiptPrinter
//
//  Created by James Adams on 4/27/12.
//  Copyright (c) 2012 Pencil Busters, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GCDAsyncSocket;

@interface ViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>
{
    __weak IBOutlet UITextView *receivedDataTextView;
    __weak IBOutlet UITextField *dataToSendTextField;
    __weak IBOutlet UISegmentedControl *dataToSendEndOfLineCharacterSegmentedControl;
    __weak IBOutlet UILabel *statusLabel;
    __weak IBOutlet UIButton *connectDisconnectButton;
    __weak IBOutlet UIButton *printBitmapButton;
    BOOL connected;
    
    BOOL commandFinished;
    BOOL printingBitmap;
    
    GCDAsyncSocket *socket;
}

- (IBAction)endOfLineSegmentChange:(id)sender;
- (IBAction)sendToPrinter:(id)sender;
- (IBAction)connectDisconnectButtonPress:(id)sender;
- (IBAction)printBitmapButtonPress:(id)sender;

@end
