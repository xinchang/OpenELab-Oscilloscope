//
//  OELPlotData.h
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 16/03/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#ifndef OpenELab_Oscilloscope_OELPlotData_h
#define OpenELab_Oscilloscope_OELPlotData_h
typedef struct {
    float point[3];
    float color[4];
} Vertex;

typedef struct {
    Vertex *vertices;
    size_t length;
} OELPlotData;

OELPlotData* OELPDInit(size_t);
int OELPDRelease(OELPlotData*);


#endif
