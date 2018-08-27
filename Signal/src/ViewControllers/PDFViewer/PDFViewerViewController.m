//
//  PDFViewerViewController.m
//  Medxnote
//
//  Created by Jan Nemecek on 27/6/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import "PDFViewerViewController.h"
#import "SendExternalFileViewController.h"
#import <SignalServiceKit/DataSource.h>
#import "Signal-Swift.h"

@import PDFKit;

@interface PDFViewerViewController ()

@property (nonatomic, strong) PDFView *pdfView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation PDFViewerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareTapped)];
    self.navigationItem.rightBarButtonItem = share;
    [self setupPDF];
}

- (void)setupPDF {
    if (@available(iOS 11.0, *)) {
        _webView.hidden = true;
        _pdfView = [[PDFView alloc] init];
        _pdfView.translatesAutoresizingMaskIntoConstraints = false;
        [self.view addSubview:_pdfView];

        [_pdfView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor].active = true;
        [_pdfView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor].active = true;
        [_pdfView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor].active = true;
        [_pdfView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = true;

        PDFDocument *document = [[PDFDocument alloc] initWithURL:self.url];
        _pdfView.document = document;
    } else {
        // show error on older versions
        //        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unavailable", @"")
        //                                                                       message:NSLocalizedString(@"PDF viewer is unavailable on iOS 10 or earlier versions. Please upgrade your version of iOS to view PDFs", @"") preferredStyle:UIAlertControllerStyleAlert];
        //        [alert addAction:[[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:nil]]]
        
        // load using web view
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:self.url];
        [self.webView loadRequest:urlRequest];
    }
}

#pragma mark - Actions

- (void)shareTapped {
    NSString *filename = self.url.lastPathComponent;
    DataSource *_Nullable dataSource = [DataSourcePath dataSourceWithURL:_url];
    dataSource.sourceFilename = filename;
    NSString *utiType;
    NSError *typeError;
    [_url getResourceValue:&utiType forKey:NSURLTypeIdentifierKey error:&typeError];
    if (typeError)
        return;
    
    SignalAttachment *attachment = [SignalAttachment attachmentWithDataSource:dataSource dataUTI:utiType];
    SendExternalFileViewController *viewController = [SendExternalFileViewController new];
    viewController.attachment = attachment;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentViewController:navigationController animated:true completion:nil];
}

@end
