//
//  OELDrawingTree.m
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 31/05/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#import "OELDrawingTree.h"

@implementation OELDrawingTree
@synthesize owner,children,visible;
-(id)initWithDelegate:(id<OELDrawingTreeDelegate>)delegate;
{
    if((self = [super init])) {
        owner = delegate;
        visible = YES;
        children = [[NSMutableArray alloc]init];
    }
    return self;
    
}

-(void)drawTree
{
    [owner oELDraw];
    for (OELDrawingTree* del in children) {
        if ([del visible])
            [del drawTree];
    }
}
@end
