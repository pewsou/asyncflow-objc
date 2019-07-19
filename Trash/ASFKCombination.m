//
//  AsyncForkingFlow.m
//  Async
//
//  Created by Boris Vigman on 13/04/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import "ASFKCombination.h"
#import "ASFKNonForkable+Private.h"

@interface ASFKCombination ()

@end
@implementation ASFKCombination
-(id)init{
    self=[super init];
    if(self){
        self.procedures=[[NSMutableArray alloc]init];
    }
    return self;
}
-(BOOL) storeProcedure:(ASFKExecutableProcedure)proc{
    if(block ){
        [self.procedures addObject:proc];
        
        NSLog(@"Procedure added with final method");
        return YES;
    }
    NSLog(@"Procedure not added");
    return NO;
}
-(void) runStoredProceduresWithParams:(void*)params withSummary:(ASFKExecutableProcedureSummary)summary{
    
}
-(void) runStoredProceduresWithSummaryProc:(ASFKExecutableProcedureSummary)summary{
    
}
-(void) runProcedure:(ASFKExecutableProcedure)proc withParams:(void*)params withSummary:(ASFKExecutableProcedureSummary)summary{
    
}
@end
