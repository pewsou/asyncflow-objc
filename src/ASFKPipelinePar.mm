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
//
//  Copyright © 2019-2022 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
#import "ASFKBase+Internal.h"
#import "ASFKBase+Statistics.h"
#import "ASFKLinearFlow+Internal.h"
#include <atomic>
#include <deque>
#import "ASFKGlobalThreadpool.h"
#import "ASFKPipelineSession.h"
@interface ASFKPipelinePar()
@end
@implementation ASFKPipelinePar{
    std::atomic<long> qos;
    std::atomic<BOOL> isOnline;
    ASFKGlobalThreadpool* globalTPool;
}

-(id)init{
    self = [super init];
    if(self){
        //_defaultSessionId=[ASFKBase generateIdentity];
        [self _initPipeline];
    }
    return self;
}
-(id)initWithName:(NSString*)name{
    self = [super initWithName:name];
    if(self){
        [self _initPipeline];
    }
    return self;
}
-(void) _initPipeline{
    isOnline=NO;
    globalTPool=[ASFKGlobalThreadpool sharedManager];

}

-(ASFKPipelineSession*) _resolveSessionforParams:(ASFKParamSet*)ps {
    ASFKThreadpoolSession* s=nil;
    if(ps.sessionId != nil && NO==[ps.sessionId isKindOfClass:[NSNull class]]){
        s=[globalTPool getThreadpoolSessionWithId:ps.sessionId];
        
        if(s && [s isKindOfClass:[ASFKPipelineSession class]]){
            return (ASFKPipelineSession*)s;
        }
        else{
            EASFKLog(@"Session %@ not found; probably wrong ID submitted",ps.sessionId);
            return nil;
        }
    }
    else
        
    {
        
        return nil;
    }
}

-(ASFKPipelineSession*) _createNewSessionWithId:(ASFK_IDENTITY_TYPE)sessionId{
    ASFKLog(@"creating new session for id %@",sessionId);
    ASFKPipelineSession* newseq=[[ASFKPipelineSession alloc]initWithSessionId:sessionId andSubsessionId:nil];
    newseq.sessionId=[[newseq getControlBlock]sessionId];
    newseq->cancellationProc = (id)^(id sessionId){
        if(sessionId){
            [lkNonLocal lock];
            [ctrlblocks removeObjectForKey:sessionId];
            [lkNonLocal unlock];
        }
    };
    return newseq;
}
-(ASFKPipelineSession*) _prepareSession:(ASFKPipelineSession*)seq withParams:(ASFKParamSet*) params {
    [seq replaceRoutinesWithArray:params.procs];
    [seq setSummary:params.summary];
    [seq setCancellationHandler:params.cancProc];
    seq->onPauseNotification=params.onPause;
    [self registerSession:[seq getControlBlock]];
    return seq;
}
-(void) setQualityOfService:(long)newqos{
    if(
       newqos==QOS_CLASS_USER_INTERACTIVE ||
       newqos==QOS_CLASS_UTILITY ||
       newqos==QOS_CLASS_BACKGROUND
       ){
        qos=newqos;
    }else{
        WASFKLog(@"ASFKPipelinePar: Invalid Class of Service provided; setting to BACKGROUND");
        qos=QOS_CLASS_BACKGROUND;
    }
}

/*!
 @return number of running sessions
 */
-(long long) getRunningSessionsCount{
    return [globalTPool  runningSessionsCount];
}
/*!
 @return number of paused sessions
 */
-(long long) getPausedSessionsCount{
    return [globalTPool pausedSessionsCount];
}
#pragma mark - Flush/Resume/Cancel
-(void)flushAll{
    [lkNonLocal lock];
    for (id s in ctrlblocks) {
        [globalTPool  flushSession:s];
    }
    [lkNonLocal unlock];
}

-(void) flushSession:(ASFK_IDENTITY_TYPE)sessionId{
    [globalTPool flushSession:sessionId];
}

/*!
 @brief pauses all sessions created by this instance.
 */
-(void)pauseAll{
    [lkNonLocal lock];
    for (id s in ctrlblocks) {
        [globalTPool  pauseSession:s];
    }
    [lkNonLocal unlock];
}
/*!
 @brief pauses session for given session ID.
 */
-(void)pauseSession:(ASFK_IDENTITY_TYPE)sessionId{
    [globalTPool pauseSession:sessionId];
}

/*!
 @brief resumes all sessions created by this instance.
 */
-(void)resumeAll{
    [lkNonLocal lock];
    for (id s in ctrlblocks) {
        [globalTPool  resumeSession:s];
    }
    [lkNonLocal unlock];
}
-(void)resumeSession:(ASFK_IDENTITY_TYPE)sessionId{
    [globalTPool resumeSession:sessionId];
}
-(void)cancelAll{
    [lkNonLocal lock];
    for (id s in ctrlblocks) {
        [globalTPool  cancelSession:s];
    }
    [lkNonLocal unlock];
    [self forgetAllSessions];
}

-(void)cancelSession:(NSString*)sessionId{
    [globalTPool cancelSession:sessionId];
    if(sessionId){
        [self forgetSession:sessionId];
    }
}
#pragma mark - Queries
-(BOOL) isPausedSession:(ASFK_IDENTITY_TYPE)sessionId{
    return [globalTPool  isPausedSession:sessionId];
}

-(BOOL)isBusySession:(id)sessionId{
    return [globalTPool  isBusySession:sessionId];
}
//-(BOOL) isBusy{
//    return NO;
//}
-(BOOL)isReady{
    return YES;
}

-(long long) itemsCountForSession:(id)sessionId{
    return [globalTPool itemsCountForSession:sessionId];
}


-(NSDictionary* _Nonnull) createSession:(ASFKExecutionParams*_Nullable) exparams sessionId:(id _Nullable ) sid {
    uint64 main_t1=[ASFKBase getTimestamp];
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    ASFKParamSet* params=[self _decodeExParams:exparams forSession:sid];
    if(!params.summary)
    {
        params.summary = sumProc;
    }
    if(!params.procs || [params.procs count]==0)
    {
        params.procs = [_backprocs copy];
    }
    if(!params.cancProc){
        params.cancProc = cancellationHandler;
    }

    //test params
    if(params.procs==nil
       || [params.procs isKindOfClass:[NSNull class]]
       || [params.procs count]<1){
        dispatch_semaphore_signal(semHighLevelCall);
        uint64 main_t2=[ASFKBase getTimestamp];
        double elapsed=(main_t2-main_t1)/1e9;
        ASFKLog(@"ASFKPipelinePar:Some of input parameters are invalid");
        return @{kASFKReturnCode:ASFK_RC_FAIL,
                 kASFKReturnResult:[NSNull null],
                 kASFKReturnSessionId:[NSNull null],
                 kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
                 kASFKReturnDescription:ASFK_STR_INVALID_PARAM};
    }
    if(!sid){
        params.sessionId=[ASFKBase generateIdentity];
    }
    else{
        params.sessionId=sid;
    }
    //create new session
    ASFKPipelineSession* seq=[self _createNewSessionWithId:params.sessionId];
    //configure session
    ASFKPipelineSession* s=[self _prepareSession:seq withParams:params];
    //set Expiration Condition
    if(params.excond && [params.excond isKindOfClass:[ASFKExpirationCondition class]]){
        [s setExpirationCondition:params.excond];
    }else{
        [s setExpirationCondition:nil];
    }
    
    //pass session to execution
    BOOL res=[globalTPool addSession:s withId:s.sessionId];
    dispatch_semaphore_signal(semHighLevelCall);
    
    uint64 main_t2=[ASFKBase getTimestamp];
    double elapsed=(main_t2-main_t1)/1e9;
    if(res==YES){
        return @{kASFKReturnCode:ASFK_RC_SUCCESS,
                 kASFKReturnResult:[NSNull null],
                 kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
                 kASFKReturnSessionId:s.sessionId,
                 kASFKReturnDescription:ASFK_RC_DESCR_DEFERRED};
    }
    return @{kASFKReturnCode:ASFK_RC_FAIL,
             kASFKReturnResult:[NSNull null],
             kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
             kASFKReturnSessionId:s.sessionId,
             kASFKReturnDescription:ASFK_RC_DESCR_IMPROPER};
}
-(NSArray*) getSessions{
    NSArray* sessions=@[];
    [lkNonLocal lock];
    sessions=[ctrlblocks allKeys];
    [lkNonLocal unlock];
    return sessions;
}

#pragma mark - Non-blocking methods
-(NSDictionary*) _castArray:(ASFKParamSet*)params{
    __block uint64 main_t1=[ASFKBase getTimestamp];
    DASFKLog(@"ASFKPipelinePar:Object %@: trying to push data items",self.itsName);

    if (
        params.sessionId==nil
        ||[params.sessionId isKindOfClass:[NSNull class]]
        ||params.input==nil
        ||[params.input isKindOfClass:[NSNull class]]
        ||[params.input count]<1
        ){
        uint64 main_t2=[ASFKBase getTimestamp];
        double elapsed=(main_t2-main_t1)/1e9;
        EASFKLog(@"ASFKPipelinePar:Some of input parameters are invalid for session %@",params.sessionId);
        return @{kASFKReturnCode:ASFK_RC_FAIL,
                 kASFKReturnResult:[NSNull null],
                 kASFKReturnSessionId:[NSNull null],
                 kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
                 kASFKReturnDescription:ASFK_STR_INVALID_PARAM};
    }
    ASFKLog(@"Performing non-blocking call");

    ASFKPipelineSession* s=[self _resolveSessionforParams:params ];
    if(s){
        //if(params.hasForeignProcs){
            if(params.excond && [params.excond isKindOfClass:[ASFKExpirationCondition class]]){
                [s setExpirationCondition:params.excond];
            }

            [globalTPool postDataAsArray:params.input forSession:s.sessionId];

            uint64 main_t2=[ASFKBase getTimestamp];
            double elapsed=(main_t2-main_t1)/1e9;
            
            return @{kASFKReturnCode:ASFK_RC_SUCCESS,
                     kASFKReturnResult:[NSNull null],
                     kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
                     kASFKReturnSessionId:s.sessionId,
                     kASFKReturnDescription:ASFK_RC_DESCR_DEFERRED};
        //}
    }
    uint64 main_t2=[ASFKBase getTimestamp];
    double elapsed=(main_t2-main_t1)/1e9;
    EASFKLog(@"ASFKPipelinePar:Some of input parameters are invalid for session %@",params.sessionId);
    
    return @{kASFKReturnCode:ASFK_RC_FAIL,
             kASFKReturnResult:[NSNull null],
             kASFKReturnSessionId:[NSNull null],
             kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
             kASFKReturnDescription:@"Some of input parameters are invalid: missing data or Routines or summary"};

}
-(NSDictionary*) _castOrderedSet:(ASFKParamSet *)params{
    __block uint64 main_t1=[ASFKBase getTimestamp];
    DASFKLog(@"ASFKPipelinePar:Object %@: trying to push data items",self.itsName);

    if (
        params.sessionId==nil
        ||[params.sessionId isKindOfClass:[NSNull class]]
        ||params.input==nil
        ||[params.input isKindOfClass:[NSNull class]]
        ||[params.input count]<1
        
        ){

        uint64 main_t2=[ASFKBase getTimestamp];
        double elapsed=(main_t2-main_t1)/1e9;
        EASFKLog(@"ASFKPipelinePar:Some of input parameters are invalid for session %@",params.sessionId);
        return @{kASFKReturnCode:ASFK_RC_FAIL,
                 kASFKReturnResult:[NSNull null],
                 kASFKReturnSessionId:[NSNull null],
                 kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
                 kASFKReturnDescription:ASFK_STR_INVALID_PARAM};
    }
    ASFKLog(@"Performing non-blocking call");

    ASFKPipelineSession* s=[self _resolveSessionforParams:params ];
    if(s){
        //if(params.hasForeignProcs){
            
            if(params.excond && [params.excond isKindOfClass:[ASFKExpirationCondition class]]){
                [s setExpirationCondition:params.excond];
            }
            [globalTPool  postDataAsOrderedSet:params.input forSession:s.sessionId];

            uint64 main_t2=[ASFKBase getTimestamp];
            double elapsed=(main_t2-main_t1)/1e9;
            
            return @{kASFKReturnCode:ASFK_RC_SUCCESS,
                     kASFKReturnResult:[NSNull null],
                     kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
                     kASFKReturnSessionId:s.sessionId,
                     kASFKReturnDescription:ASFK_RC_DESCR_DEFERRED};
        //}
    }
    uint64 main_t2=[ASFKBase getTimestamp];
    double elapsed=(main_t2-main_t1)/1e9;
    EASFKLog(@"ASFKPipelinePar:Some of input parameters are invalid for session %@",params.sessionId);
    
    return @{kASFKReturnCode:ASFK_RC_FAIL,
             kASFKReturnResult:[NSNull null],
             kASFKReturnSessionId:[NSNull null],
             kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
             kASFKReturnDescription:@"Some of input parameters are invalid: missing data or Routines or summary"};
}
-(NSDictionary*) _castUnorderedSet:(ASFKParamSet *)params{
    __block uint64 main_t1=[ASFKBase getTimestamp];
    DASFKLog(@"ASFKPipelinePar:Object %@: trying to push data items",self.itsName);

    if (
        params.sessionId==nil
        ||[params.sessionId isKindOfClass:[NSNull class]]
        ||params.input==nil
        ||[params.input isKindOfClass:[NSNull class]]
        ||[params.input count]<1
        
        ){

        uint64 main_t2=[ASFKBase getTimestamp];
        double elapsed=(main_t2-main_t1)/1e9;
        EASFKLog(@"ASFKPipelinePar:Some of input parameters are invalid for session %@",params.sessionId);
        return @{kASFKReturnCode:ASFK_RC_FAIL,
                 kASFKReturnResult:[NSNull null],
                 kASFKReturnSessionId:[NSNull null],
                 kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
                 kASFKReturnDescription:ASFK_STR_INVALID_PARAM};
    }
    ASFKLog(@"Performing non-blocking call");

    ASFKPipelineSession* s=[self _resolveSessionforParams:params];
    if(s){
       // if(params.hasForeignProcs){
            
            if(params.excond && [params.excond isKindOfClass:[ASFKExpirationCondition class]]){
                [s setExpirationCondition:params.excond];
            }

            [globalTPool  postDataAsUnorderedSet:params.input forSession:s.sessionId];
            
            uint64 main_t2=[ASFKBase getTimestamp];
            double elapsed=(main_t2-main_t1)/1e9;
            
            return @{kASFKReturnCode:ASFK_RC_SUCCESS,
                     kASFKReturnResult:[NSNull null],
                     kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
                     kASFKReturnSessionId:s.sessionId,
                     kASFKReturnDescription:ASFK_RC_DESCR_DEFERRED};
        //}
    }
    uint64 main_t2=[ASFKBase getTimestamp];
    double elapsed=(main_t2-main_t1)/1e9;
    EASFKLog(@"ASFKPipelinePar:Some of input parameters are invalid for session %@",params.sessionId);
    
    return @{kASFKReturnCode:ASFK_RC_FAIL,
             kASFKReturnResult:[NSNull null],
             kASFKReturnSessionId:[NSNull null],
             kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
             kASFKReturnDescription:@"Some of input parameters are invalid: missing data or Routines or summary"};
}

-(NSDictionary*) _castDictionary:(ASFKParamSet*)params{
    __block uint64 main_t1=[ASFKBase getTimestamp];
    DASFKLog(@"ASFKPipelinePar:Object %@: trying to push data items",self.itsName);

    if (
        params.sessionId==nil
        ||[params.sessionId isKindOfClass:[NSNull class]]
        ||params.input==nil
        ||[params.input isKindOfClass:[NSNull class]]
        ||[params.input count]<1
        
        
        ){
        
        uint64 main_t2=[ASFKBase getTimestamp];
        double elapsed=(main_t2-main_t1)/1e9;
        EASFKLog(@"ASFKPipelinePar:Some of input parameters are invalid for session %@",params.sessionId);
        return @{kASFKReturnCode:ASFK_RC_FAIL,
                 kASFKReturnResult:[NSNull null],
                 kASFKReturnSessionId:[NSNull null],
                 kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
                 kASFKReturnDescription:ASFK_STR_INVALID_PARAM};
    }
    ASFKLog(@"Performing non-blocking call");

    ASFKPipelineSession* s=[self _resolveSessionforParams:params ];
    if(s){
            
            if(params.excond && [params.excond isKindOfClass:[ASFKExpirationCondition class]]){
                [s setExpirationCondition:params.excond];
            }

            [globalTPool  postDataAsDictionary:params.input forSession:s.sessionId];

            uint64 main_t2=[ASFKBase getTimestamp];
            double elapsed=(main_t2-main_t1)/1e9;
            
            return @{kASFKReturnCode:ASFK_RC_SUCCESS,
                     kASFKReturnResult:[NSNull null],
                     kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
                     kASFKReturnSessionId:s.sessionId,
                     kASFKReturnDescription:ASFK_RC_DESCR_DEFERRED};
        //}
    }
    uint64 main_t2=[ASFKBase getTimestamp];
    double elapsed=(main_t2-main_t1)/1e9;
    EASFKLog(@"ASFKPipelinePar:Some of input parameters are invalid for session %@",params.sessionId);
    
    return @{kASFKReturnCode:ASFK_RC_FAIL,
             kASFKReturnResult:[NSNull null],
             kASFKReturnSessionId:[NSNull null],
             kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
             kASFKReturnDescription:@"Some of input parameters are invalid: missing data or Routines or summary"};
}
#pragma mark - Blocking methods
-(NSDictionary*) _callArray:(ASFKParamSet*)params{
    MASFKLog(@"Pipelining in blocking call not allowed for this data type");
    return @{kASFKReturnCode:ASFK_RC_FAIL,
             kASFKReturnResult:[NSNull null],
             kASFKReturnSessionId:[NSNull null],
             kASFKReturnStatsTimeSessionElapsedSec:@(0),
             kASFKReturnDescription:@"Pipelining in blocking call not allowed for this data type"};
    
}

-(NSDictionary*) _callDictionary:(ASFKParamSet*)params{
    MASFKLog(@"Pipelining in blocking call not allowed for this data type");
    return @{kASFKReturnCode:ASFK_RC_FAIL,
             kASFKReturnResult:[NSNull null],
             kASFKReturnSessionId:[NSNull null],
             kASFKReturnStatsTimeSessionElapsedSec:@(0),
             kASFKReturnDescription:@"Pipelining in blocking call not allowed for this data type"};
  
}
-(NSDictionary*) _callIndexSet:(ASFKParamSet *)params{
    MASFKLog(@"Pipelining in blocking call not allowed for this data type");
    return @{kASFKReturnCode:ASFK_RC_FAIL,
             kASFKReturnResult:[NSNull null],
             kASFKReturnSessionId:[NSNull null],
             kASFKReturnStatsTimeSessionElapsedSec:@(0),
             kASFKReturnDescription:@"Pipelining in blocking call not allowed for this data type"};
}
-(NSDictionary*) _callOrderedSet:(ASFKParamSet *)params{
    MASFKLog(@"Pipelining in blocking call not allowed for this data type");
    return @{kASFKReturnCode:ASFK_RC_FAIL,
             kASFKReturnResult:[NSNull null],
             kASFKReturnSessionId:[NSNull null],
             kASFKReturnStatsTimeSessionElapsedSec:@(0),
             kASFKReturnDescription:@"Pipelining in blocking call not allowed for this data type"};
}
-(NSDictionary*) _callUnorderedSet:(ASFKParamSet *)params{
    MASFKLog(@"Pipelining in blocking call not allowed for this data type");
    return @{kASFKReturnCode:ASFK_RC_FAIL,
             kASFKReturnResult:[NSNull null],
             kASFKReturnSessionId:[NSNull null],
             kASFKReturnStatsTimeSessionElapsedSec:@(0),
             kASFKReturnDescription:@"Pipelining in blocking call not allowed for this data type"};
}
@end


