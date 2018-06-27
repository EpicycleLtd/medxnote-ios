//
//  PDFViewerViewController.m
//  Medxnote
//
//  Created by Jan Nemecek on 27/6/18.
//  Copyright © 2018 Open Whisper Systems. All rights reserved.
//

#import "PDFViewerViewController.h"

@import PDFKit;

@interface PDFViewerViewController ()

@property (nonatomic, strong) PDFView *pdfView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation PDFViewerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleDone target:self action:@selector(done)];
    self.navigationItem.rightBarButtonItem = item;
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

- (void)done {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
