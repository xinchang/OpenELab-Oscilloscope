//
//  OELViewController.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 06/03/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELViewController.h"

@interface OELViewController ()

@end

@implementation OELViewController
@synthesize plotView;
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    
}
-(void)viewDidAppear:(BOOL)animated
{

    CGRect frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, self.view.bounds.size.height);
    
    plotView = [[OELPlotView alloc] initWithFrame:frame];
    [[self view]addSubview:plotView];
    [plotView startAnimation];
    
//    frame = CGRectMake(self.view.bounds.origin.x+self.view.frame.size.width/2, self.view.bounds.origin.y, self.view.bounds.size.width/2, self.view.bounds.size.height/2);
//    plotView = [[OELPlotView alloc] initWithFrame:frame];
//    [[self view]addSubview:plotView];
//    [plotView startAnimation];
//    frame = CGRectMake(self.view.bounds.origin.x+self.view.frame.size.width/2, self.view.bounds.origin.y+self.view.bounds.size.height/2, self.view.bounds.size.width/2, self.view.bounds.size.height/2);
//    plotView = [[OELPlotView alloc] initWithFrame:frame];
//    [[self view]addSubview:plotView];
//    [plotView startAnimation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(NSUInteger)supportedInterfaceOrientations{
    
    NSLog(@"x= %f y= %f w= %f h=%f",self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    
    return UIInterfaceOrientationMaskLandscapeLeft;
    
}

- (BOOL)shouldAutorotate{
    return YES;
}

@end
