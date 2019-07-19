//
//  ASFKNonForkable+Private.m
//  Async
//
//  Created by Boris Vigman on 14/04/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import "ASFKNonForkable+Private.h"

@implementation ASFKCombination (Private)
-(void) setStoredProcedures:(NSMutableArray*)procedures andEnds:(NSMutableArray*)ends{
    self.procedures=procedures;
    self.ends=ends;
}
@end
