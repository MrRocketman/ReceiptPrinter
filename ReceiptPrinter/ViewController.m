//
//  ViewController.m
//  ReceiptPrinter
//
//  Created by James Adams on 4/27/12.
//  Copyright (c) 2012 Pencil Busters, Inc. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

#define HOST @"169.254.1.1"
#define PORT 2000

@interface ViewController ()

- (void)connectToPrinter;

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
    
    NSString *host = HOST;
    uint16_t port = PORT;
	
	dispatch_queue_t mainQueue = dispatch_get_main_queue();
	socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
    
    NSLog(@"Connecting to \"%@\" on port %hu...", host, port);
    statusLabel.text = @"Connecting...";
    
    NSError *error = nil;
    if (![socket connectToHost:host onPort:port error:&error])
    {
        NSLog(@"Error connecting: %@", error);
        statusLabel.text = @"Oops";
    }
}

- (void)viewDidUnload
{
    receivedDataTextView = nil;
    dataToSendTextField = nil;
    dataToSendEndOfLineCharacterSegmentedControl = nil;
    statusLabel = nil;
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

- (void)connectToPrinter
{
    
}

#pragma mark - UITextField Delegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
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
    //[dataToSendTextField text];
}

#pragma mark - Socket Delegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSLog(@"socket:%p didConnectToHost:%@ port:%hu", sock, host, port);
	statusLabel.text = @"Connected";

}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
	statusLabel.text = @"Connected + Secure";
	
	NSString *requestStr = @"Host";
	NSData *requestData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
	
	//[sock writeData:requestData withTimeout:-1 tag:0];
	//[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	NSLog(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSLog(@"socket:%p didReadData:withTag:%ld", sock, tag);
	
	NSString *httpResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	NSLog(@"HTTP Response:\n%@", httpResponse);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	NSLog(@"socketDidDisconnect:%p withError: %@", sock, err);
    statusLabel.text = @"Disconnected";
}

@end
