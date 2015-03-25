//
//  TodayViewController.m
//  Used Space
//
//  Created by LbsLogin on 25/03/15.
//  Copyright (c) 2015 RIL. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

// Macro for NSUserDefaults key
#define RATE_KEY @"kUDRateUsed"
#define kWClosedHeight   37.0
#define kWExpandedHeight 106.0

@interface TodayViewController () <NCWidgetProviding>
@property (strong, nonatomic) IBOutlet UILabel *percentLabel;
@property (strong, nonatomic) IBOutlet UILabel *detailsLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *barView;
@property (nonatomic, assign) unsigned long long fileSystemSize;
@property (nonatomic, assign) unsigned long long freeSize;
@property (nonatomic, assign) unsigned long long usedSize;
@property (nonatomic, assign) double usedRate;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self updateInterface];
    [self setPreferredContentSize:CGSizeMake(0.0, kWClosedHeight)];
    [self.detailsLabel setAlpha:0.0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    [self updateSizes];
    
    double newRate = (double)self.usedSize / (double)self.fileSystemSize;
    
    if (newRate - self.usedRate < 0.0001) {
        completionHandler(NCUpdateResultNoData);
    } else {
        [self setUsedRate:newRate];
        [self updateInterface];
        completionHandler(NCUpdateResultNewData);
    }
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)margins{
    margins.bottom = 10.0;
    return margins;
}

- (void)updateSizes
{
    // Retrieve the attributes from NSFileManager
    NSDictionary *dict = [[NSFileManager defaultManager]
                          attributesOfFileSystemForPath:NSHomeDirectory()
                          error:nil];
    
    // Set the values
    self.fileSystemSize = [[dict valueForKey:NSFileSystemSize]
                           unsignedLongLongValue];
    self.freeSize       = [[dict valueForKey:NSFileSystemFreeSize]
                           unsignedLongLongValue];
    self.usedSize       = self.fileSystemSize - self.freeSize;
}

- (double)usedRate
{
    return [[[NSUserDefaults standardUserDefaults]
             valueForKey:RATE_KEY] doubleValue];
}

- (void)setUsedRate:(double)usedRate
{
    NSUserDefaults *defaults =
    [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithDouble:usedRate]
                forKey:RATE_KEY];
    [defaults synchronize];
}

- (void)updateInterface
{
    double rate = self.usedRate; // retrieve the cached value
    self.percentLabel.text =
    [NSString stringWithFormat:@"%.1f%%", (rate * 100)];
    self.barView.progress = rate;
}

-(void)updateDetailsLabel{
    NSByteCountFormatter *formatter =
    [[NSByteCountFormatter alloc] init];
    [formatter setCountStyle:NSByteCountFormatterCountStyleFile];
    
    self.detailsLabel.text =
    [NSString stringWithFormat:
     @"Used:\t%@\nFree:\t%@\nTotal:\t%@",
     [formatter stringFromByteCount:self.usedSize],
     [formatter stringFromByteCount:self.freeSize],
     [formatter stringFromByteCount:self.fileSystemSize]];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self updateDetailsLabel];
    [self setPreferredContentSize:CGSizeMake(0.0, kWExpandedHeight)];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [coordinator animateAlongsideTransition:
     ^(id<UIViewControllerTransitionCoordinatorContext> context){
         [self.detailsLabel setAlpha:1.0];
     } completion:nil];
}

@end
