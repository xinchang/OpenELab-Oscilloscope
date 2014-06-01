//
//  OELDrawingTree.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 31/05/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELDrawingTree.h"

@implementation OELDrawingTree
@synthesize owner,children;
-(id)init
{
    if((self = [super init])) {
        children = [[NSMutableArray alloc]init];
    }
    return self;
    
}

-(void)drawTree
{
    [owner oELDraw];
    for (id<OELDrawingTreeDelegate> del in children) {
        [[del getOELDrawingTree] drawTree];
    }
}
@end
