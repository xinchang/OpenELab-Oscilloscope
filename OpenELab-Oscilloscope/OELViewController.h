//
//  OELViewController.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 06/03/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Plot/OELPlotView.h"

@interface OELViewController : UIViewController
{
    OELPlotView *plotView;
}

@property(nonatomic,retain)    OELPlotView *plotView;

@end
