//
//  OELAxisUtility.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 01/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELAxisUtility.h"

@implementation OELAxisUtility
@synthesize screenSize,realRect;
@synthesize leftMargin,rightMargin,topMargin,bottomMargin,xAxis,yAxis;
-(id)init{
    if(self = [super init])
    {
        range[0]=0;
        range[1]=1;
        
        screenSize =CGSizeMake(1, 0.75);
        topMargin = 0;
        leftMargin = 0;
        rightMargin = 0;
        bottomMargin = 0;
        
        
        
    }
    return self;
}
-(float)getLeftAxisCoordinate{
    return -screenSize.width + leftMargin;
}
-(float)getRightAxisCoordinate{
    return screenSize.width - rightMargin;
}


-(float)getTopAxisCoordinate{
    return screenSize.height - topMargin;
}

-(float)getBottomtAxisCoordinate{
    return -screenSize.height + bottomMargin;
}

-(float*)getXAxisReferences{
    float left = [self getLeftAxisCoordinate];
    float increment = ([self getRightAxisCoordinate] - left)/10;
    for (int i = 0; i<11; i++) {
        xReferences[i] = left +i*increment;
    }
    return xReferences;
}

-(float*)getYAxisReferences;{
    float bottom = [self getBottomtAxisCoordinate];
    float increment = ([self getTopAxisCoordinate] - bottom)/10;
    for (int i = 0; i<11; i++) {
        yReferences[i] = bottom +i*increment;
    }
    return yReferences;
}

@end
