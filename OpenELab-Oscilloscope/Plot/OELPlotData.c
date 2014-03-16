//
//  OELPlotData.c
//  OpenELab-Oscilloscope
//
//  Created by Xinchang LIU on 16/03/14.
//  Copyright (c) 2014 Xinchang LIU. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include "OELPlotData.h"

OELPlotData* OELPDInit(size_t s)
{
    OELPlotData* data = (OELPlotData*)malloc(sizeof(OELPlotData));
    if (data) {
        data->length = s;
        data->vertices = (Vertex*)calloc(s,sizeof(Vertex));
    }
    return data;
}

int OELPDRelease(OELPlotData* data)
{
    if (!data) {
        return 0;
    }
    free(data->vertices);
    free(data);
    data = NULL;
    return 1;
}

