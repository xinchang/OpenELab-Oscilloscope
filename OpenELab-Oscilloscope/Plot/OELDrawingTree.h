//
//  OELDrawingTree.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 31/05/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//


#import <Foundation/Foundation.h>

@class OELDrawingTree;

@protocol OELDrawingTreeDelegate <NSObject>
    -(void)oELDraw;
    -(OELDrawingTree*) getOELDrawingTree;
@end

@interface OELDrawingTree : NSObject
{
    id<OELDrawingTreeDelegate> owner;
    NSMutableArray *children;
}
@property(nonatomic,readwrite) id<OELDrawingTreeDelegate> owner;
@property(nonatomic,readwrite) NSMutableArray *children;
-(id)init;
-(void)drawTree;


@end
