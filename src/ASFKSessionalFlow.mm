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

//  Created by Boris Vigman on 28/02/2019.
//  Copyright © 2019-2023 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
#import "ASFKBase+Statistics.h"
#import "ASFKSessionalFlow+Internal.h"
#import "ASFKBase+Internal.h"
#include <atomic>
@interface ASFKSessionalFlow()

@end
@implementation ASFKSessionalFlow{
    std::atomic<std::int64_t> itsSessionsLimit;
    std::atomic<std::int64_t> itsSessionItemsLimit;
    std::atomic<std::int64_t> itsProcsPerSessionLimit;
    std::atomic<BOOL> itsIsReady;
}
-(id)init{
    self=[super init];
    if(self){
        [self _initSeF];
    }
    return self;
}
-(id)initWithName:(NSString*)name{
    self=[super initWithName:name];
    if(self){
        [self _initSeF];
    }
    return self;
}
-(void) _initSeF{
    itsIsReady=YES;
    _backprocs=[[NSMutableArray alloc]init];
    lfProcs=_backprocs;
    sumProc=(id)^(id<ASFKControlCallback> controlBlock,NSDictionary* stats,id data){
        ASFKLog(@"ASFKLinearFlow: Stub summary");
        return data;
    };
    cancellationHandler=nil;
    progressProc=nil;
    itsSessionsLimit=ASFK_PRIVSYM_TP_SESSIONS_LIMIT;
    itsSessionItemsLimit=ASFK_PRIVSYM_TP_ITEMS_PER_SESSION_LIMIT;
    itsProcsPerSessionLimit=ASFK_PRIVSYM_TP_PROCS_PER_SESSION_LIMIT;
    semHighLevelCall=dispatch_semaphore_create(1);

}
-(std::uint64_t) getRoutinesCount{
    [lkNonLocal lock];
    std::uint64_t count=[lfProcs count];
    [lkNonLocal unlock];
    return count;
}
-(std::uint64_t) getDataItemsCount{
    return 0;
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
    ASFKExecutableRoutineSummary c=sumProc;
    [lkNonLocal unlock];
    return c;
}
-(ASFKCancellationRoutine) getCancellationHandler{
    [lkNonLocal lock];
    ASFKCancellationRoutine c=cancellationHandler;
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
-(BOOL) replaceRoutinesFromArray:(NSArray<ASFKExecutableRoutine>*)someprocs{
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
-(BOOL) setOnPauseNotification:(ASFKOnPauseNotification)notification{
    if(notification){
        dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
        itsIsReady=NO;
        [lkNonLocal lock];
        onPauseProc=notification;
        [lkNonLocal unlock];
        itsIsReady=YES;
        dispatch_semaphore_signal(semHighLevelCall);
    }
    else{
        EASFKLog(@"ASFKLinearFlow: Invalid Routine provided");
        return NO;
    }
    return YES;
}
-(BOOL) setSummary:(ASFKExecutableRoutineSummary)summary{
    if(summary){
        dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
        itsIsReady=NO;
        [lkNonLocal lock];
        sumProc=nil;
        sumProc=summary;
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
        cancellationHandler=nil;
        cancellationHandler=ch;
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
-(NSDictionary*) castOrderedSet:(NSOrderedSet*)set session:(id)sessionId exParams:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[ASFKParamSet new];
    params.sessionId=sessionId;
    params=[self _convertInputOrderedSet:set to:params];
    dispatch_semaphore_signal(semHighLevelCall);
    NSDictionary* res= [self _postOrderedSet:params blocking:NO];
    
    return res;
}
-(NSDictionary*) castUnorderedSet:(NSSet*)set session:(id)sessionId exParams:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[ASFKParamSet new];
    params.sessionId=sessionId;
    params=[self _convertInputUnorderedSet:set to:params];
    dispatch_semaphore_signal(semHighLevelCall);
    NSDictionary* res= [self _postUnorderedSet:params blocking:NO];
    
    return res;
}
-(NSDictionary*) castArray:(NSArray*)array session:(id)sessionId exParams:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[ASFKParamSet new];
    params.sessionId=sessionId;
    params=[self _convertInputArray:array to:params];
    dispatch_semaphore_signal(semHighLevelCall);
    
    NSDictionary* res= [self _postArray:params blocking:NO];
    
    return res;
}

-(NSDictionary*) castDictionary:(NSDictionary*)dictionary session:(id)sessionId exParams:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[ASFKParamSet new];
    params.sessionId=sessionId;
    params=[self _convertInputDictionary:dictionary to:params];
    dispatch_semaphore_signal(semHighLevelCall);
    NSDictionary* res= [self _postDictionary:params blocking:NO];
    
    return res;
}

-(NSDictionary*) castObject:(id)uns session:(id)sessionId exParams:(ASFKExecutionParams*)ex{
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[ASFKParamSet new];
    params.sessionId=sessionId;
    params=[self _convertInput:uns to:params];
    dispatch_semaphore_signal(semHighLevelCall);
    NSDictionary* res= [self _postArray:params blocking:NO];
    return res;
}
#pragma mark - Blocking methods
-(NSDictionary*) callOrderedSet:(NSOrderedSet*)set session:(id)sessionId exParams:(ASFKExecutionParams*)ex{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    
    return @{};
}
-(NSDictionary*) callUnorderedSet:(NSSet*)set session:(id)sessionId exParams:(ASFKExecutionParams*)ex{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    
    return @{};
}

-(NSDictionary*) callArray:(NSArray*)array session:(id)sessionId exParams:(ASFKExecutionParams*)ex{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    
    return @{};
}

-(NSDictionary*) callDictionary:(NSDictionary*)dictionary session:(id)sessionId exParams:(ASFKExecutionParams*)ex{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    
    return @{};
}

-(NSDictionary*) callObject:(id)uns session:(id)sessionId exParams:(ASFKExecutionParams*)ex{
    DASFKLog(ASFK_STR_VER_UNAVAIL_OP);
    
    return @{};
}

#pragma mark - private methods
-(ASFKParamSet*) _decodeSessionParams:(ASFKSessionConfigParams*)ex forSession:(id)sessionId{
    ASFKParamSet* expar=[ASFKParamSet new];
    if(ex){
        expar.summary = ex->summaryRoutine?ex->summaryRoutine:sumProc;
        expar.procs = [NSMutableArray array];
        NSArray* prarr=ex->procs;
        if(prarr==nil || [prarr count]==0 || [prarr isKindOfClass:[NSNull class]]){
            prarr=_backprocs;
        }
        for (ASFKExecutableRoutine p in prarr){
            [expar.procs addObject:[p copy]];
        };
        
        expar.onPause = ex->onPauseProc?ex->onPauseProc:onPauseProc;
        expar.cancProc = ex->cancellationProc?ex->cancellationProc:cancellationHandler;
        expar.excond=ex->expCondition;
        expar.progress = ex->progressProc?ex->progressProc:progressProc;
        expar.sessionId=sessionId;
        expar.bcallMode=ex->blockCallMode;
    }
    
    return expar;
}
-(ASFKParamSet*) _decodeExParams:(ASFKSessionConfigParams*)ex forSession:(id)sessionId{
    ASFKParamSet* expar=[ASFKParamSet new];
    if(ex){
        expar.summary = ex->summaryRoutine?ex->summaryRoutine:sumProc;
        expar.procs = [NSMutableArray array];
        NSArray* prarr=ex->procs;
        if(prarr==nil || [prarr count]==0 || [prarr isKindOfClass:[NSNull class]]){
            prarr=_backprocs;
        }
        for (ASFKExecutableRoutine p in prarr){
            [expar.procs addObject:[p copy]];
        };

        expar.onPause = ex->onPauseProc?ex->onPauseProc:onPauseProc;
        expar.cancProc = ex->cancellationProc?ex->cancellationProc:cancellationHandler;
        expar.excond=ex->expCondition;
        expar.progress = ex->progressProc?ex->progressProc:progressProc;
        expar.sessionId=sessionId;
    }

    return expar;
}
@end
