//
//  ImagesLoader.m
//  VirtualPet
//
//  Created by Ezequiel on 11/21/14.
//  Copyright (c) 2014 Ezequiel. All rights reserved.
//

#import "ImagesLoader.h"

@implementation ImagesLoader

+ (instancetype) sharedInstance
{
    static dispatch_once_t pred = 0;
    
    __strong static id _sharedObject = nil;
    
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    
    return _sharedObject;
}

- (void) loadPetArraysWithTag: (PetType)tag
{
    NSArray* arrayEat;
    NSArray* arrayExcescise;
    NSArray* arrayExhaust;
    switch (tag) {
        case TYPE_CIERVO:
            arrayEat = @[@"ciervo_comiendo_1",@"ciervo_comiendo_2",@"ciervo_comiendo_3",@"ciervo_comiendo_4"];
            arrayExcescise = @[@"ciervo_ejercicio_1", @"ciervo_ejercicio_2", @"ciervo_ejercicio_3", @"ciervo_ejercicio_4", @"ciervo_ejercicio_5"];
            arrayExhaust = @[@"ciervo_exhausto_1", @"ciervo_exhausto_2", @"ciervo_exhausto_3", @"ciervo_exhausto_4"];
            break;
        case TYPE_GATO:
            arrayEat = @[@"gato_comiendo_1",@"gato_comiendo_2",@"gato_comiendo_3",@"gato_comiendo_4"];
            arrayExcescise = @[@"gato_ejercicio_1", @"gato_ejercicio_2", @"gato_ejercicio_3", @"gato_ejercicio_4", @"gato_ejercicio_5"];
            arrayExhaust = @[@"gato_exhausto_1", @"gato_exhausto_2", @"gato_exhausto_3", @"gato_exhausto_4"];
            break;
        case TYPE_JIRAFA:
            arrayEat = @[@"jirafa_comiendo_1",@"jirafa_comiendo_2",@"jirafa_comiendo_3",@"jirafa_comiendo_4"];
            arrayExcescise = @[@"jirafa_ejercicio_1", @"jirafa_ejercicio_2", @"jirafa_ejercicio_3", @"jirafa_ejercicio_4", @"jirafa_ejercicio_5"];
            arrayExhaust = @[@"jirafa_exhausto_1", @"jirafa_exhausto_2", @"jirafa_exhausto_3", @"jirafa_exhausto_4"];
            break;
        case TYPE_LEON:
            arrayEat = @[@"leon_comiendo_1",@"leon_comiendo_2",@"leon_comiendo_3",@"leon_comiendo_4"];
            arrayExcescise = @[@"leon_ejercicio_1", @"leon_ejercicio_2", @"leon_ejercicio_3", @"leon_ejercicio_4", @"leon_ejercicio_5"];
            arrayExhaust = @[@"leon_exhausto_1", @"leon_exhausto_2", @"leon_exhausto_3", @"leon_exhausto_4"];
            break;
        default:
            break;
    }

    self.imgPetComiendo = [NSArray arrayWithArray:arrayEat];
    self.imgPetEjercicio = [NSArray arrayWithArray:arrayExcescise];
    self.imgPetExhausto = [NSArray arrayWithArray:arrayExhaust];
    
    self.imgSuperSaiyan = @[@"Super-1", @"Super-2", @"Super-3"];
}

@end
