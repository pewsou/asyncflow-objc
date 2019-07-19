//
//  ASFKMapBase.m
//  Async
//
//  Created by bv on 17/07/2019.
//  Copyright © 2019 bv. All rights reserved.
//

#import "ASFKMapBase.h"

@implementation ASFKMapBase
-(NSArray*) runOnArray:(NSArray*)array{
    return [self runOnArray:array withProcedures:self.procs withSummary:self.sumproc];
}
-(NSArray*) runOnArray:(NSArray*)array withSummary:(ASFKExecutableProcedureSummary)summary{
    return [self runOnArray:array withProcedures:self.procs withSummary:summary];
}
-(NSArray*) runOnArray:(NSArray*)array withProcedures:(NSArray<ASFKExecutableProcedure>*) procs{
    return [self runOnArray:array withProcedures:procs withSummary:self.sumproc];
}
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary{
    return [self runOnDictionary:dictionary withProcedures:self.procs withSummary:self.sumproc];
}
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs{
    return [self runOnDictionary:dictionary withProcedures:procs withSummary:self.sumproc];
}
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary withSummary:(ASFKExecutableProcedureSummary)summary{
    return [self runOnDictionary:dictionary withProcedures:self.procs withSummary:summary];
}
-(id) runOnUnspecified:(id)uns{
    return [self runOnUnspecified:uns withProcedures:self.procs withSummary:self.sumproc];
}
-(id) runOnUnspecified:(id)uns withSummary:(ASFKExecutableProcedureSummary)summary{
    return [self runOnUnspecified:uns withProcedures:self.procs withSummary:summary];
}
-(id) runOnUnspecified:(NSDictionary*)uns withProcedures:(NSArray<ASFKExecutableProcedure>*) procs{
    return [self runOnUnspecified:uns withProcedures:procs withSummary:self.sumproc];
}
-(id) runOnUnspecified:(id)uns withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary{
    return [self runOnUnspecified:uns withProcedures:procs withSummary:summary];
}

-(void*) runOnUnspecifiedC:(void*)uns {
    return uns;
}

-(void*) runOnUnspecifiedC:(void*)uns withSummary:(ASFKExecutableProcedureSummaryCStyle)summary{
    return uns;
}
@end
