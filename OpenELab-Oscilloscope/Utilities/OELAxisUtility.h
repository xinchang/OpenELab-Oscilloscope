//
//  OELAxisUtility.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 01/06/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OELAxisUtility : NSObject
{
    
    CGSize screenSize;
    float range[2];
    float leftMargin;
    float topMargin;
    float rightMargin;
    float bottomMargin;

    
    float xReferences[11];
    float yReferences[11];
    
}
@property(readwrite,nonatomic)    CGSize screenSize;
@property(readwrite,nonatomic) CGRect realRect;
@property(readwrite,nonatomic) float leftMargin;
@property(readwrite,nonatomic) float topMargin;
@property(readwrite,nonatomic) float rightMargin;
@property(readwrite,nonatomic) float bottomMargin;
@property(readwrite,nonatomic) float xAxis;
@property(readwrite,nonatomic) float yAxis;
-(id)init;

-(float)getLeftAxisCoordinate;
-(float)getRightAxisCoordinate;
-(float)getTopAxisCoordinate;
-(float)getBottomtAxisCoordinate;

-(float*)getXAxisReferences;
-(float*)getYAxisReferences;

@end
