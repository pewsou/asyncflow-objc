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
//  Created by Boris Vigman on 05/04/2019.
//  Copyright © 2019-2023 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
#import "ASFKBase+Internal.h"
#import "ASFKBase+Statistics.h"
#import "ASFKSessionalFlow+Internal.h"

#include <atomic>
#include <deque>
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
    globalTPool=[ASFKGlobalThreadpool singleInstance];

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

-(ASFKPipelineSession*) _createNewSessionWithId:(ASFK_IDENTITY_TYPE)sessionId blkMode:(eASFKBlockingCallMode)blkMode{
    ASFKLog(@"creating new session for id %@",sessionId);
    ASFKPipelineSession* newseq=[[ASFKPipelineSession alloc]initWithSessionId:sessionId andSubsessionId:nil blkMode:blkMode];
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
-(std::uint64_t) getRunningSessionsCount{
    return [globalTPool  runningSessionsCount];
}
/*!
 @return number of paused sessions
 */
-(std::uint64_t) getPausedSessionsCount{
    return [globalTPool pausedSessionsCount];
}
#pragma mark - Flush/Resume/Cancel
-(void)flushAll{
    [lkNonLocal lock];
    [ctrlblocks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [globalTPool  flushSession:key];
    }];
//    for (id s in ctrlblocks) {
//        [globalTPool  flushSession:s];
//    }
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
-(BOOL) isBusy{
    NSInteger bcount=0;
    [lkNonLocal lock];
    for (id key in ctrlblocks) {
        ASFKControlBlock* res=[ctrlblocks objectForKey:key];
        id s=[res getCurrentSessionId];
        if([globalTPool  isBusySession:s]){
            ++bcount;
        }
    }
    [lkNonLocal unlock];
    return bcount>0?YES:NO;
}
-(BOOL)isReady{
    return YES;
}

-(std::uint64_t) itemsCountForSession:(id)sessionId{
    return [globalTPool itemsCountForSession:sessionId];
}
-(std::uint64_t) totalSessionsCount{
    return [globalTPool totalSessionsCount];
}

-(NSDictionary* _Nonnull) createSession:(ASFKSessionConfigParams*_Nullable) exparams sessionId:(id _Nullable ) sid {
    uint64 main_t1=[ASFKBase getTimestamp];
    dispatch_semaphore_wait(semHighLevelCall, DISPATCH_TIME_FOREVER);
    std::uint64_t count=[globalTPool  totalSessionsCount];
    if(count>ASFK_PRIVSYM_TP_SESSIONS_LIMIT){
        dispatch_semaphore_signal(semHighLevelCall);
        uint64 main_t2=[ASFKBase getTimestamp];
        double elapsed=(main_t2-main_t1)/1e9;
        ASFKLog(ASFK_STR_UP_LIMITS_REACHED_SES);
        return @{kASFKReturnCode:ASFK_RC_FAIL,
                 kASFKReturnResult:[NSNull null],
                 kASFKReturnSessionId:[NSNull null],
                 kASFKReturnStatsTimeSessionElapsedSec:@(elapsed),
                 kASFKReturnDescription:ASFK_STR_UP_LIMITS_REACHED_SES};
    }
    ASFKParamSet* params=[self _decodeSessionParams:exparams forSession:sid];
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
       || [params.procs count]<1
       || [params.procs count]>ASFK_PRIVSYM_TP_PROCS_PER_SESSION_LIMIT
       ){
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
    ASFKPipelineSession* seq=[self _createNewSessionWithId:params.sessionId blkMode:params.bcallMode];
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
-(NSDictionary*) _postArray:(ASFKParamSet*)params blocking:(BOOL) blk{
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

    ASFKPipelineSession* s=[self _resolveSessionforParams:params ];
    if(s){
        if(params.excond && [params.excond isKindOfClass:[ASFKExpirationCondition class]]){
            [s setExpirationCondition:params.excond];
        }

        BOOL res=[globalTPool postDataAsArray:params.input forSession:s.sessionId blocking:blk];

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
                 kASFKReturnDescription:ASFK_RC_DESCR_DEFERRED};
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
-(NSDictionary*) _postOrderedSet:(ASFKParamSet *)params blocking:(BOOL) blk{
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

    ASFKPipelineSession* s=[self _resolveSessionforParams:params ];
    if(s){
        //if(params.hasForeignProcs){
            
        if(params.excond && [params.excond isKindOfClass:[ASFKExpirationCondition class]]){
            [s setExpirationCondition:params.excond];
        }
        BOOL res=[globalTPool  postDataAsOrderedSet:params.input forSession:s.sessionId blocking:blk];

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
                 kASFKReturnDescription:ASFK_RC_DESCR_DEFERRED};
        
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
-(NSDictionary*) _postUnorderedSet:(ASFKParamSet *)params blocking:(BOOL) blk{
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
    //ASFKLog(@"Performing non-blocking call");
    
    ASFKPipelineSession* s=[self _resolveSessionforParams:params ];
    if(s){
        if(params.excond && [params.excond isKindOfClass:[ASFKExpirationCondition class]]){
            [s setExpirationCondition:params.excond];
        }
        
        BOOL res=[globalTPool postDataAsUnorderedSet:params.input forSession:s.sessionId blocking:blk];
        
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
                 kASFKReturnDescription:ASFK_RC_DESCR_DEFERRED};

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

-(NSDictionary*) _postDictionary:(ASFKParamSet*)params blocking:(BOOL) blk{
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

    ASFKPipelineSession* s=[self _resolveSessionforParams:params ];
    if(s){
            
        if(params.excond && [params.excond isKindOfClass:[ASFKExpirationCondition class]]){
            [s setExpirationCondition:params.excond];
        }

        BOOL res=[globalTPool  postDataAsDictionary:params.input forSession:s.sessionId blocking:blk];

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
                 kASFKReturnDescription:ASFK_RC_DESCR_DEFERRED};
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

@end


