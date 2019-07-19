/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.
 
 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
//  ASFKNonForkable.m
//  Async
//
//  Created by Boris Vigman on 28/06/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
#import "ASFKControlBlock+Private.h"
@interface ASFKNonForkable()
@property (readwrite) NSMutableArray *procs;
@property (readwrite) NSMutableArray *cprocs;
@property (readwrite) ASFKExecutableProcedureSummary sumproc;
@property (readwrite) ASFKExecutableProcedureSummaryCStyle csumcproc;
@property (readwrite) ASFKControlBlock* controlData;
@end
@implementation ASFKNonForkable

-(id) init{
    self=[super init];
    if(self){
        self.cprocs=[[NSMutableArray alloc]init];
        self.procs=[[NSMutableArray alloc]init];
        self.sumproc=nil;
        self.csumcproc=nil;
        self.enabledNonBlockingExecution=NO;
        self.controlData=[[ASFKControlBlock alloc]init];;
    }
    return self;
}
-(void) storeProcedure:(ASFKExecutableProcedure)proc{
    if(proc){
        [self.procs addObject:proc];
    }else{
        NSLog(@"ASFKNonForkable: Invalid procedure provided");
    }
}
-(void) storeProcedureC:(ASFKExecutableProcedureCStyle)proc{
    if(proc){
        [self.cprocs addObject:proc];
    }else{
        NSLog(@"ASFKNonForkable: Invalid procedure provided");
    }
}
-(void) storeProcedures:(NSArray*)procs{
    if(procs){
        self.procs=[NSMutableArray arrayWithArray:procs];
    }
}
-(void) storeProceduresC:(NSArray*)cprocs{
    if(cprocs){
        self.cprocs=[NSMutableArray arrayWithArray:cprocs];
    }
}
-(void) storeSummaryC:(ASFKExecutableProcedureSummaryCStyle)summary;{
    if(summary){
        self.csumcproc=summary;
    }else{
        NSLog(@"ASFKNonForkable: Invalid procedure provided");
    }
}
-(void) storeSummary:(ASFKExecutableProcedureSummary)summary{
    if(summary){
        self.sumproc=summary;
    }else{
        NSLog(@"ASFKNonForkable: Invalid procedure provided");
    }
}


- (void)execWithParam:(id)param {
    
}

- (void)execWithParamCStyle:(void *)param {
    
}

@end
