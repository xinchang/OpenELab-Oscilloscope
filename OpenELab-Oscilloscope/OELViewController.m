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
    plotView = [[OELPlotView alloc] initWithFrame:[[self view] frame]];
    [[self view]addSubview:plotView];
    [plotView startAnimation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
