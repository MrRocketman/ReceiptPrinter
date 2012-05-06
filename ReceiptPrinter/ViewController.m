//
//  ViewController.m
//  ReceiptPrinter
//
//  Created by James Adams on 4/27/12.
//  Copyright (c) 2012 Pencil Busters, Inc. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import "Qr.h"

#define HOST @"169.254.1.1"
#define HOST_PORT 2000
#define LINE_FEED 10
#define CARRIAGE_RETURN 13
#define COMMAND_FINISHED 5

@interface ViewController ()

- (void)connectToPrinter;
- (void)updateConnectButton;
- (void)printBitmap;
- (void)writeDataToSocket:(NSData *)data;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Setup our socket (GCDAsyncSocket).
	// The socket will invoke our delegate methods using the usual delegate paradigm.
	// However, it will invoke the delegate methods on a specified GCD delegate dispatch queue.
	// 
	// Now we can configure the delegate dispatch queue however we want.
	// We could use a dedicated dispatch queue for easy parallelization.
	// Or we could simply use the dispatch queue for the main thread.
	// 
	// The best approach for your application will depend upon convenience, requirements and performance.
	// 
	// For this simple example, we're just going to use the main thread.
	
	dispatch_queue_t mainQueue = dispatch_get_main_queue();
	socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
    
    [self connectToPrinter];
}

- (void)viewDidUnload
{
    receivedDataTextView = nil;
    dataToSendTextField = nil;
    dataToSendEndOfLineCharacterSegmentedControl = nil;
    statusLabel = nil;
    connectDisconnectButton = nil;
    printBitmapButton = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
    {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } 
    else
    {
        return YES;
    }
}

#pragma mark - Private Methods

- (void)connectToPrinter
{
    NSString *host = HOST;
    uint16_t hostPort = HOST_PORT;
    
    NSLog(@"Connecting to \"%@\" on port %hu...", host, hostPort);
    statusLabel.text = @"Connecting...";
    NSError *error = nil;
    if (![socket connectToHost:host onPort:hostPort error:&error])
    {
        NSLog(@"Error connecting: %@", error);
        statusLabel.text = @"Oops";
        connected = NO;
    }
    else
    {
        [socket readDataWithTimeout:-1 tag:0];
        connected = YES;
    }
}

- (void)updateConnectButton
{
    if(connected)
    {
        [connectDisconnectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    }
    else 
    {
        [connectDisconnectButton setTitle:@"Connect" forState:UIControlStateNormal];
    }
}

#pragma mark - UITextField Delegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField 
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UITextView Delegate

- (void)textViewDidChange:(UITextView *)textView
{
    
}

#pragma mark - IBActions

- (IBAction)endOfLineSegmentChange:(id)sender
{
    
}

- (IBAction)sendToPrinter:(id)sender
{
    NSString *endOfLineCharacter = @"";
    
    // CR Character
    if([dataToSendEndOfLineCharacterSegmentedControl selectedSegmentIndex] == 0)
    {
        endOfLineCharacter = [NSString stringWithFormat:@"%c", CARRIAGE_RETURN];
    }
    else if([dataToSendEndOfLineCharacterSegmentedControl selectedSegmentIndex] == 1)
    {
        endOfLineCharacter = [NSString stringWithFormat:@"%c", LINE_FEED];
    }
    
    NSData *requestData = [[NSString stringWithFormat:@"%@%@", [dataToSendTextField text], endOfLineCharacter] dataUsingEncoding:NSUTF8StringEncoding];
    [socket writeData:requestData withTimeout:-1 tag:0];
}

- (IBAction)connectDisconnectButtonPress:(id)sender 
{
    if(connected)
    {
        [socket disconnect];
    }
    else
    {
        [self connectToPrinter];
    }
}

- (IBAction)printBitmapButtonPress:(id)sender
{
    [self performSelectorInBackground:@selector(printBitmap) withObject:nil];
}

#pragma mark - Private Methods

- (void)printBitmap
{
    printingBitmap = YES;
    
    NSString *command = [NSString stringWithFormat:@"P08 V%d S%d\n", QrHeight, QrWidth];
    NSLog(@"Sending: %@", command);
    NSData *requestData = [command dataUsingEncoding:NSUTF8StringEncoding];
    [self performSelectorOnMainThread:@selector(writeDataToSocket:) withObject:requestData waitUntilDone:NO];
    
    for(int i = 0; i < (int)(QrWidth / 8.0 * QrHeight); i ++)
    {
        command = [NSString stringWithFormat:@"%02X", Qr[i]];
        NSLog(@"Sending: %@", command);
        requestData = [command dataUsingEncoding:NSUTF8StringEncoding];
        commandFinished = NO;
        [self performSelectorOnMainThread:@selector(writeDataToSocket:) withObject:requestData waitUntilDone:NO];
        [NSThread sleepForTimeInterval:0.005];
    }
    
    /*int i3 = 0;
    for(int i = 0; i < (int)(QrWidth / 8.0 * QrHeight / 16.0); i ++)
    {
        while(!commandFinished)
        {
            // Wait
        }
        
        command = [NSString stringWithFormat:@"P09"];
        for(int i2 = 0; i2 < QrWidth / 8; i2 ++)
        {
            i3 = i * (int)(QrWidth / 8) + i2;
            if(i3 > (int)(QrWidth / 8.0 * QrHeight) - 1)
                break;
            command = [NSString stringWithFormat:@"%@ V%02X", command, Qr[i3]];
        }
        command = [NSString stringWithFormat:@"%@\n", command];
        NSLog(@"Sending: %@", command);
        requestData = [command dataUsingEncoding:NSUTF8StringEncoding];
        commandFinished = NO;
        [self performSelectorOnMainThread:@selector(writeDataToSocket:) withObject:requestData waitUntilDone:NO];
    }
    
    if(commandFinished)
    {
        command = [NSString stringWithFormat:@"P10\n"];
        NSLog(@"Sending: %@", command);
        requestData = [command dataUsingEncoding:NSUTF8StringEncoding];
        [self performSelectorOnMainThread:@selector(writeDataToSocket:) withObject:requestData waitUntilDone:NO];
    }*/
}

- (void)writeDataToSocket:(NSData *)data
{
    commandFinished = NO;
    [socket writeData:data withTimeout:-1 tag:0];
}

#pragma mark - Socket Delegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSLog(@"didConnectToHost:%@ port:%hu", host, port);
	statusLabel.text = @"Connected";
    connected = YES;
    [self updateConnectButton];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSLog(@"didAcceptNewSocket:%@", newSocket);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	//NSLog(@"didWriteDataWithTag:%ld", tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSLog(@"didReadData:withTag:%ld", tag);
	
	NSString *httpResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSLog(@"Response:\n%@", httpResponse);
    
    for(int i = 0; i < [httpResponse length]; i ++)
    {
        if([httpResponse characterAtIndex:i] == COMMAND_FINISHED)
        {
            commandFinished = YES;
        }
    }
    
    [receivedDataTextView setText:[NSString stringWithFormat:@"%@%@", [receivedDataTextView text], httpResponse]];
    [receivedDataTextView scrollRangeToVisible:NSMakeRange([receivedDataTextView.text length], 0)];
    [socket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    NSLog(@"didReadPartialData:withTag:%ld", tag);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	NSLog(@"DidDisconnectWithError: %@", err);
    statusLabel.text = @"Disconnected";
    connected = NO;
    [self updateConnectButton];
}

@end
