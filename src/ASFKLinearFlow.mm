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

//  Copyright © 2019-2022 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
#import "ASFKBase+Statistics.h"
#import "ASFKLinearFlow+Internal.h"
#import "ASFKBase+Internal.h"
#include <atomic>
@interface ASFKLinearFlow()

@end
@implementation ASFKLinearFlow{
    std::atomic<BOOL> itsIsReady;
}
-(id)init{
    self=[super init];
    if(self){
        [self _initLF];
    }
    return self;
}
-(id)initWithName:(NSString*)name{
    self=[super initWithName:name];
    if(self){
        [self _initLF];
    }
    return self;
}
-(void)_initLF{
    itsIsReady=YES;
    _backprocs=[[NSMutableArray alloc]init];
    lfProcs=_backprocs;
    sumproc=(id)^(id<ASFKControlCallback> controlBlock,NSDictionary* stats,id data){
        ASFKLog(@"ASFKLinearFlow: Stub summary");
        return data;
    };
    cancelproc=nil;
    progressProc=nil;
}
-(NSUInteger) getRoutinesCount{
    [lkNonLocal lock];
    NSUInteger count=[lfProcs count];
    [lkNonLocal unlock];
    return count;
}
-(NSArray<ASFKExecutableRoutine> *) getRoutines{
    [lkNonLocal lock];
    NSMutableArray<ASFKExecutableRoutine> * a=[NSMutableArray array];
    for (ASFKExecutableRoutine p in lfProcs) {
        [a addObject:[p copy]];
    }
    [lkNonLocal unlock];
    return a;
}
-(ASFKExecutableRoutineSummary) getSummaryRoutine{
    [lkNonLocal lock];
    ASFKExecutableRoutineSummary c=sumproc;
    [lkNonLocal unlock];
    return c;
}
-(ASFKCancellationRoutine) getCancellationHandler{
    [lkNonLocal lock];
    ASFKCancellationRoutine c=cancelproc;
    [lkNonLocal unlock];
    return c;
}
-(ASFKProgressRoutine) getProgressRoutine{
    [lkNonLocal lock];
    ASFKProgressRoutine p=progressProc;
    [lkNonLocal unlock];
    return p;
}
-(BOOL) setProgressRoutine:(ASFKProgressRoutine)pro{
    if(pro){
        dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
        itsIsReady=NO;
        [lkNonLocal lock];
        progressProc=nil;
        progressProc=pro;
        [lkNonLocal unlock];
        itsIsReady=YES;
        dispatch_semaphore_signal(semHighLevelCall);
    }else{
        EASFKLog(@"ASFKLinearFlow: Invalid Progress Handler provided");
        return NO;
    }
    return YES;
}
-(BOOL) addRoutine:(ASFKExecutableRoutine)proc{
    if(proc){
        dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
        itsIsReady=NO;
        [lkNonLocal lock];
        [_backprocs addObject:proc];
        [lkNonLocal unlock];
        itsIsReady=YES;
        dispatch_semaphore_signal(semHighLevelCall);
    }else{
        EASFKLog(@"ASFKLinearFlow: Invalid Routine provided");
        return NO;
    }
    
    return YES;
}
-(BOOL) addRoutines:(NSArray<ASFKExecutableRoutine>*)procs{
    if(procs && [procs count]>0){
        dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
        itsIsReady=NO;
        [lkNonLocal lock];
        [_backprocs addObjectsFromArray:procs];
        [lkNonLocal unlock];
        itsIsReady=YES;
        dispatch_semaphore_signal(semHighLevelCall);
    }else{
        EASFKLog(@"ASFKLinearFlow: Invalid Routine(s) provided");
        return NO;
    }
    return YES;
}
-(BOOL) setRoutinesFromArray:(NSArray<ASFKExecutableRoutine>*)someprocs{
       BOOL replaced=NO;
       dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
       itsIsReady=NO;
       [lkNonLocal lock];
       [_backprocs removeAllObjects];
       if(someprocs && [someprocs count]>0){
           [_backprocs addObjectsFromArray:someprocs];
           replaced=YES;
       }
       [lkNonLocal unlock];
       itsIsReady=YES;
       dispatch_semaphore_signal(semHighLevelCall);
       if(replaced==NO){
           WASFKLog(@"ASFKLinearFlow: Routines were removed");
       }
    return replaced;
}
-(BOOL) isReady{
    return itsIsReady;
}
-(BOOL) setSummary:(ASFKExecutableRoutineSummary)summary{
    if(summary){
        dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
        itsIsReady=NO;
        [lkNonLocal lock];
        sumproc=nil;
        sumproc=summary;
        [lkNonLocal unlock];
        itsIsReady=YES;
        dispatch_semaphore_signal(semHighLevelCall);
    }else{
        EASFKLog(@"ASFKLinearFlow: Invalid Routine provided");
        return NO;
    }
    return YES;
}

-(BOOL) setCancellationHandler:(ASFKCancellationRoutine)ch{
    if(ch){
        dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
        itsIsReady=NO;
        [lkNonLocal lock];
        cancelproc=nil;
        cancelproc=ch;
        [lkNonLocal unlock];
        itsIsReady=YES;
        dispatch_semaphore_signal(semHighLevelCall);
    }
    else{
        EASFKLog(@"ASFKLinearFlow: Invalid Cancellation Handler provided");
        return NO;
    }
    return YES;
}

#pragma mark - Non-blocking methods
-(NSDictionary*) castOrderedSet:(NSOrderedSet*)set session:(id)sessionId exParam:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[self _decodeExParams:ex forSession:nil];
    params=[self _convertInputOrderedSet:set to:params];
    params.sessionId=sessionId;
    dispatch_semaphore_signal(semHighLevelCall);
    NSDictionary* res= [self _castOrderedSet:params];
    
    return res;
}
-(NSDictionary*) castUnorderedSet:(NSSet*)set session:(id)sessionId exParam:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[self _decodeExParams:ex forSession:nil ];
    params=[self _convertInputUnorderedSet:set to:params];
    params.sessionId=sessionId;
    dispatch_semaphore_signal(semHighLevelCall);
    NSDictionary* res= [self _castUnorderedSet:params];
    
    return res;
}
-(NSDictionary*) castArray:(NSArray*)array session:(id)sessionId exParam:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[self _decodeExParams:ex forSession:nil];
    params=[self _convertInputArray:array to:params];
    dispatch_semaphore_signal(semHighLevelCall);
    params.sessionId=sessionId;
    
    NSDictionary* res= [self _castArray:params];
    
    return res;
}

-(NSDictionary*) castDictionary:(NSDictionary*)dictionary session:(id)sessionId exParam:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[self _decodeExParams:ex forSession:nil];
    params=[self _convertInputDictionary:dictionary to:params];
    dispatch_semaphore_signal(semHighLevelCall);
    params.sessionId=sessionId;
    NSDictionary* res= [self _castDictionary:params];
    
    return res;
}

-(NSDictionary*) castObject:(id)uns session:(id)sessionId exParam:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[self _decodeExParams:ex forSession:nil];
    params=[self _convertInput:uns to:params];
    params.sessionId=sessionId;
    dispatch_semaphore_signal(semHighLevelCall);
    NSDictionary* res= [self _castArray:params];
    return res;
}
#pragma mark - Blocking methods
-(NSDictionary*) callOrderedSet:(NSOrderedSet*)set session:(id)sessionId exParam:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[self _decodeExParams:ex forSession:nil];
    params=[self _convertInputOrderedSet:set to:params];
    params.sessionId=sessionId;
    dispatch_semaphore_signal(semHighLevelCall);
    NSDictionary* res= [self _callOrderedSet:params];
    
    return res;
}
-(NSDictionary*) callUnorderedSet:(NSSet*)set session:(id)sessionId exParam:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[self _decodeExParams:ex forSession:nil];
    params=[self _convertInputUnorderedSet:set to:params];
    params.sessionId=sessionId;
    dispatch_semaphore_signal(semHighLevelCall);
    
    NSDictionary* res= [self _callUnorderedSet:params];
    
    return res;
}

-(NSDictionary*) callArray:(NSArray*)array session:(id)sessionId exParam:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[self _decodeExParams:ex forSession:nil];
    params=[self _convertInputArray:array to:params];
    params.sessionId=sessionId;
    dispatch_semaphore_signal(semHighLevelCall);
    NSDictionary* res= [self _callArray:params];
    
    return res;
}

-(NSDictionary*) callDictionary:(NSDictionary*)dictionary session:(id)sessionId exParam:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[self _decodeExParams:ex forSession:nil];
    params=[self _convertInputDictionary:dictionary to:params];
    params.sessionId=sessionId;
    dispatch_semaphore_signal(semHighLevelCall);
    NSDictionary* res= [self _callDictionary:params];

    return res;
}

-(NSDictionary*) callObject:(id)uns session:(id)sessionId exParam:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[self _decodeExParams:ex forSession:nil];
    params=[self _convertInput:uns to:params];
    params.sessionId=sessionId;
    dispatch_semaphore_signal(semHighLevelCall);
    NSDictionary* res= [self _callArray:params];
    return res;
}

- (NSDictionary *)stepBlockingWithData:(id)data {
    NSDictionary* result=nil;
    if([data isKindOfClass:[NSDictionary class]]){
        result=[self callDictionary:data session:nil exParam:nil];
    }else if([data isKindOfClass:[NSArray class]]){
        result=[self callArray:data session:nil exParam:nil];
    }else{
        result=[self callObject:data session:nil exParam:nil];
    }
    return result;
}

- (NSDictionary *)stepNonblockingWithData:(id)data {
    NSDictionary* result=nil;
    if([data isKindOfClass:[NSDictionary class]]){
        
    }else if([data isKindOfClass:[NSArray class]]){
        
    }else{
        
    }
    return result;
}
#pragma mark - private methods

-(ASFKParamSet*) _decodeExParams:(ASFKExecutionParams*)ex forSession:(id)sessionId{
    ASFKParamSet* expar=[ASFKParamSet new];
    if(ex){
        expar.summary = ex->SummaryRoutine?ex->SummaryRoutine:sumproc;
        expar.procs = [NSMutableArray array];
        NSArray* prarr=ex->procs;
        if(prarr==nil || [prarr count]==0 || [prarr isKindOfClass:[NSNull class]]){
            prarr=_backprocs;
        }
        for (ASFKExecutableRoutine p in prarr){
            [expar.procs addObject:[p copy]];
        };
        expar.cancProc = ex->cancellationProc?ex->cancellationProc:cancelproc;
        expar.excond=ex->expCondition;
        expar.progress = ex->progressProc?ex->progressProc:progressProc;
        if(sessionId){
            expar.sessionId=sessionId;
        }
        else{
            expar.sessionId=nil;
        }
    }
    return expar;
}
@end
