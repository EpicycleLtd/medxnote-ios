//
//  QRCodeViewController.m
//  Medxnote
//
//  Created by Jan Nemecek on 5/5/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

@import AVFoundation;

#import "QRCodeViewController.h"

@interface QRCodeViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UIView *videoPreviewView;
@property AVCaptureSession *captureSession;
@property AVCaptureVideoPreviewLayer *videoPreviewLayer;

@end

@implementation QRCodeViewController

#pragma mark - Init

+ (QRCodeViewController *)viewControllerWithDelegate:(id<QRCodeViewDelegate>)delegate {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"QRCode" bundle:nil];
    QRCodeViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"QRCodeView"];
    vc.delegate = delegate;
    return vc;
}

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSError *error;
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        // TODO: handle error
    }
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:input];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeCode128Code]];
    
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:self.videoPreviewView.layer.bounds];
    [self.videoPreviewView.layer addSublayer:_videoPreviewLayer];
    
    [_captureSession startRunning];
}

- (void)stopReading {
    [_captureSession stopRunning];
    _captureSession = nil;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([metadataObj.type isEqualToString:AVMetadataObjectTypeQRCode] || [metadataObj.type isEqualToString:AVMetadataObjectTypeCode128Code]) {
            [self stopReading];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Got data %@", metadataObj.stringValue);
                [self.delegate didFinishScanningQRCodeWithString:metadataObj.stringValue];
                [self dismissViewControllerAnimated:true completion:nil];
            });
        }
    }
}
- (IBAction)cancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
