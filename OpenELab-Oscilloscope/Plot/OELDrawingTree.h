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
//    -(OELDrawingTree*) getOELDrawingTree;
@end

@interface OELDrawingTree : NSObject
{
    id<OELDrawingTreeDelegate> owner;
    BOOL visible;
    NSMutableArray *children;
}
@property(nonatomic,readwrite) id<OELDrawingTreeDelegate> owner;
@property(nonatomic,readwrite) NSMutableArray *children;
@property(nonatomic,readwrite) BOOL visible;
-(id)initWithDelegate: (id<OELDrawingTreeDelegate>)delegate;
-(void)drawTree;


@end
