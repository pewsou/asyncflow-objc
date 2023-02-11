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

#import "ASFKBase+Internal.h"
#include <atomic>
#include <vector>

struct ThreadpoolConfig{
    long share;
    long residue;
    long actualThreadsCount;
    long requiredThreadsCount;
};

struct ThreadpoolConfigRange{
    long lowBound;
    long length;
};
@interface ASFKGlobalThreadpool()
@property NSUInteger threadsLimit;
@end
@implementation ASFKGlobalThreadpool{
    NSMutableDictionary* runningSessions;
    NSArray* onlineSessions;
    NSMutableArray* killedSessions;
    NSMutableDictionary* pausedSessions;
    NSMutableDictionary* allSessions;
    ThreadpoolConfig tpcfg;
    NSLock* lkMutexL1;
    //NSLock* lkMutexL2;
    //NSLock* lkMutexL1;

    NSCondition* lkCond;
    std::atomic<BOOL> shouldSleep;
    std::atomic<long> busyCount;
    std::atomic<long> qos;
    std::vector<ThreadpoolConfigRange> vectProc2Bounds;
}
#pragma mark Singleton Methods
+ (ASFKGlobalThreadpool *)singleInstance {
    static ASFKGlobalThreadpool *singleInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleInstance = [[self alloc] init];
    });
    return singleInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        runningSessions=[NSMutableDictionary dictionary];
        onlineSessions=[NSArray array];
        killedSessions=[NSMutableArray array];
        pausedSessions=[NSMutableDictionary new];
        allSessions=[NSMutableDictionary new];
        lkMutexL1=[NSLock new];
        //lkMutexL2=[NSLock new];
        lkCond=[NSCondition new];
        self.threadsLimit=1;
        shouldSleep=YES;
        busyCount=0;
        qos=ASFK_PRIVSYM_QOS_CLASS;
        NSUInteger pr=[[NSProcessInfo processInfo] activeProcessorCount]*ASFK_PRIVSYM_TP_LOAD_FACTOR;
        if(self.threadsLimit<1||self.threadsLimit>pr ){
            ASFKLog(@"ASFKGlobalThreadpool: Requested number of threads is unavailable");
            self.threadsLimit=pr;
        }
        if(pr>1){
            self.threadsLimit=pr;
        }
        if(self.threadsLimit<=1)
            self.threadsLimit=1;
        ASFKLog(@"ASFKGlobalThreadpool: Threads used: %lu",(unsigned long)self.threadsLimit);
        tpcfg.actualThreadsCount=self.threadsLimit;
        tpcfg.requiredThreadsCount=self.threadsLimit;
        tpcfg.residue=tpcfg.requiredThreadsCount%tpcfg.actualThreadsCount;
        tpcfg.share=tpcfg.requiredThreadsCount/tpcfg.actualThreadsCount;
        [self _engineDeploy];
    }
    return self;
}
-(std::uint64_t)runningSessionsCount{
    [lkMutexL1 lock];
    std::uint64_t cc=[runningSessions count];
    [lkMutexL1 unlock];
    return (cc);
}
-(std::uint64_t)pausedSessionsCount{
    [lkMutexL1 lock];
    std::uint64_t ac=[pausedSessions count];
    [lkMutexL1 unlock];
    return (ac);
}

-(BOOL) isPausedSession:(ASFK_IDENTITY_TYPE)sessionId{
    BOOL result=NO;
    if(sessionId){
        [lkMutexL1 lock];
        ASFKThreadpoolSession* ss=[allSessions objectForKey:sessionId];
        if(ss){
            result = ss->paused;
        }
        [lkMutexL1 unlock];
    }
    return result;
}
-(BOOL) isBusySession:(ASFK_IDENTITY_TYPE)sessionId{
    BOOL result=NO;
    if(sessionId){
        [lkMutexL1 lock];
        ASFKThreadpoolSession* ss=[allSessions objectForKey:sessionId];
        if(ss){
             result = [ss isBusy];
        }
        [lkMutexL1 unlock];
    }
    return result;
}
-(NSArray*) getThreadpoolSessionsList{
    [lkMutexL1 lock];
    NSArray* a=[allSessions allKeys];
    [lkMutexL1 unlock];
    return a;
}
-(std::uint64_t) totalSessionsCount{
    [lkMutexL1 lock];
    std::uint64_t c=[allSessions count];
    [lkMutexL1 unlock];
    return c;
}
-(std::uint64_t) itemsCountForSession:(ASFK_IDENTITY_TYPE)sessionId{
    std::uint64_t result=0;
    if(sessionId){
        [lkMutexL1 lock];
        ASFKThreadpoolSession* ss=[allSessions objectForKey:sessionId];
        if(ss){
            result= [ss getDataItemsCount];
        }

        [lkMutexL1 unlock];
    }
    return result;
}
-(void) flushSession:(ASFK_IDENTITY_TYPE)sessionId{
    ASFKLog(@"ASFKGlobalThreadpool: Flushing session with ID %@",sessionId);
    if(sessionId){
        [lkMutexL1 lock];
        ASFKThreadpoolSession* ss=[allSessions objectForKey:sessionId];
        if(ss){
            [ss flush];
        }

        [lkMutexL1 unlock];
    }
    ASFKLog(@"ASFKGlobalThreadpool: Session %@ flushed",sessionId);
}
-(void) flushAll{
    ASFKLog(@"ASFKGlobalThreadpool: Flushing all sessions");
    [lkMutexL1 lock];
    [allSessions enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        ASFKThreadpoolSession* ss=[allSessions objectForKey:obj];
        [ss flush];
        ss=nil;
    }];


    [lkMutexL1 unlock];
}
-(void) _cancelSessionInternally:(ASFK_IDENTITY_TYPE)sessionId{
    DASFKLog(@"ASFKGlobalThreadpool: Cancelling session with ID %@, internal trigger",sessionId);
    if(sessionId){
        [lkMutexL1 lock];
        ASFKThreadpoolSession* ss=[allSessions objectForKey:sessionId];
        if(ss){
            [runningSessions removeObjectForKey:sessionId];
            //[lkMutexL2 lock];
            
            onlineSessions=[runningSessions allValues];
            //[lkMutexL2 unlock];
            
            [allSessions removeObjectForKey:sessionId];
            [pausedSessions removeObjectForKey:sessionId];
            ss=nil;
        }
        [lkMutexL1 unlock];
    }
    DASFKLog(@"ASFKGlobalThreadpool: Session %@ should be cancelled",sessionId);
}
-(void) cancelSession:(ASFK_IDENTITY_TYPE)sessionId{
    DASFKLog(@"ASFKGlobalThreadpool: Cancelling session with ID %@",sessionId);
    if(sessionId){
        [lkMutexL1 lock];
        ASFKThreadpoolSession* ss=[allSessions objectForKey:sessionId];
        if(ss){
            [ss cancel];
            
            [runningSessions removeObjectForKey:sessionId];
            //[lkMutexL2 lock];

            onlineSessions=[runningSessions allValues];
            //[lkMutexL2 unlock];

            [allSessions removeObjectForKey:sessionId];
            [pausedSessions removeObjectForKey:sessionId];
            ss=nil;
        }
        [lkMutexL1 unlock];
    }
    DASFKLog(@"ASFKGlobalThreadpool: Session %@ should be cancelled",sessionId);
}
-(void) cancelAll{
    DASFKLog(@"ASFKGlobalThreadpool: Cancelling all sessions");
    [lkMutexL1 lock];

    [allSessions enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        ASFKThreadpoolSession* ss=[allSessions objectForKey:obj];
        [ss cancel];

        ss=nil;
    }];
    //[lkMutexL2 lock];
    tpcfg.actualThreadsCount=0;
    ThreadpoolConfig tpc=tpcfg;
    [self _reassignProcs:tpc];
    vectProc2Bounds.clear();
    vectProc2Bounds.resize(tpcfg.actualThreadsCount);
    onlineSessions = [NSArray new];
    
    //[lkMutexL2 unlock];
    runningSessions = [NSMutableDictionary new];
    pausedSessions = [NSMutableDictionary new];
    allSessions = [NSMutableDictionary new];
    [lkMutexL1 unlock];
    DASFKLog(@"ASFKGlobalThreadpool: All sessions should be cancelled");
}
-(void) pauseSession:(ASFK_IDENTITY_TYPE)sessionId{
    DASFKLog(@"ASFKGlobalThreadpool: Pausing session with ID %@",sessionId);
    if(sessionId){
        [lkMutexL1 lock];
        ASFKThreadpoolSession* ss=[runningSessions objectForKey:sessionId];
        if(ss){
            ss->paused=YES;
            [pausedSessions setObject:ss forKey:sessionId];
            [runningSessions removeObjectForKey:sessionId];
            //[lkMutexL2 lock];
            onlineSessions=[runningSessions allValues];
            //[lkMutexL2 unlock];
            if(ss->onPauseNotification){
                ss->onPauseNotification(sessionId,YES);
            }
            
        }
        [lkMutexL1 unlock];
    }
    DASFKLog(@"ASFKGlobalThreadpool: Session %@ paused",sessionId);
}
-(void) pauseAll{
    DASFKLog(@"ASFKGlobalThreadpool: Pausing all sessions");
    [lkMutexL1 lock];
    [pausedSessions addEntriesFromDictionary:runningSessions];
    runningSessions=[NSMutableDictionary new];
    [pausedSessions enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop){
        ASFKThreadpoolSession* ss=(ASFKThreadpoolSession*)obj;
        ss->paused=YES;
    }];
    //[lkMutexL2 lock];
    onlineSessions = [NSArray new];
    //[lkMutexL2 unlock];
    [lkMutexL1 unlock];
    DASFKLog(@"ASFKGlobalThreadpool: All sessions paused");
}
-(void) resumeSession:(ASFK_IDENTITY_TYPE)sessionId{
    DASFKLog(@"ASFKGlobalThreadpool: Resuming session with ID %@",sessionId);
    if(sessionId){
        [lkMutexL1 lock];
        ASFKThreadpoolSession* ss=[pausedSessions objectForKey:sessionId];
        if(ss){
            ss->paused=NO;
            [pausedSessions removeObjectForKey:sessionId];
            [runningSessions setObject:ss forKey:sessionId];
            //[lkMutexL2 lock];
            onlineSessions = [runningSessions allValues];
            //[lkMutexL2 unlock];
            if(ss->onPauseNotification){
                ss->onPauseNotification(sessionId,NO);
            }
        }
        [lkMutexL1 unlock];
        ss=nil;
    }
    DASFKLog(@"ASFKGlobalThreadpool: Session %@ resumed",sessionId);
}
-(void) resumeAll{
    DASFKLog(@"ASFKGlobalThreadpool: Resuming all sessions");
    [lkMutexL1 lock];

    [runningSessions addEntriesFromDictionary:pausedSessions];

    pausedSessions=[NSMutableDictionary new];
    //[lkMutexL2 lock];
    onlineSessions=[runningSessions allValues];
    //[lkMutexL2 unlock];
    [runningSessions enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop){
        ASFKThreadpoolSession* ss=(ASFKThreadpoolSession*)obj;
        ss->paused=NO;
    }];
    [lkMutexL1 unlock];
    DASFKLog(@"ASFKGlobalThreadpool: All sessions resumed");
}
-(BOOL) postDataAsDictionary:(NSDictionary*)data forSession:(ASFK_IDENTITY_TYPE)sessionId blocking:(BOOL)blk{
#ifdef __ASFK_DEBUG__
    if(blk){
        DASFKLog(@"Performing blocking call");
    }
    else{
        DASFKLog(@"Performing non-blocking call");
    }
#endif
    BOOL res=NO;
    [lkMutexL1 lock];
    ASFKThreadpoolSession* ss=[allSessions objectForKey:sessionId];
    [lkMutexL1 unlock];
    if(ss){
        if(ss->callMode == ASFK_BC_NO_BLOCK && blk){
            MASFKLog(ASFK_STR_MISCONFIG_OP);
        }
        else{
            res=[ss postDataItemsAsDictionary:data  blocking:blk];
        }
        
    }
    else{
        EASFKLog(@"ASFKGlobalThreadpool: Pipeline session %@ not found",sessionId);
    }
    return res;
}
-(BOOL) postDataAsArray:(NSArray*)data forSession:(ASFK_IDENTITY_TYPE)sessionId blocking:(BOOL)blk{
#ifdef __ASFK_DEBUG__
    if(blk){
        DASFKLog(@"Performing blocking call");
    }
    else{
        DASFKLog(@"Performing non-blocking call");
    }
#endif
    BOOL res=NO;
    [lkMutexL1 lock];
    ASFKThreadpoolSession* ss=[allSessions objectForKey:sessionId];
    [lkMutexL1 unlock];
    if(ss){
        if(ss->callMode == ASFK_BC_NO_BLOCK && blk){
            MASFKLog(ASFK_STR_MISCONFIG_OP);
        }
        else{
            res=[ss postDataItemsAsArray:data blocking:blk];
        }
    }
    else{
        EASFKLog(@"ASFKGlobalThreadpool: Pipeline session %@ not found",sessionId);
    }
    return res;
}
-(BOOL) postDataAsOrderedSet:(NSOrderedSet*)data forSession:(ASFK_IDENTITY_TYPE)sessionId blocking:(BOOL)blk{
#ifdef __ASFK_DEBUG__
    if(blk){
        DASFKLog(@"Performing blocking call");
    }
    else{
        DASFKLog(@"Performing non-blocking call");
    }
#endif
    BOOL res=NO;
    [lkMutexL1 lock];
    ASFKThreadpoolSession* ss=[allSessions objectForKey:sessionId];
    [lkMutexL1 unlock];
    if(ss){
        if(ss->callMode == ASFK_BC_NO_BLOCK && blk){
            MASFKLog(ASFK_STR_MISCONFIG_OP);
        }
        else{
            res=[ss postDataItemsAsOrderedSet:data  blocking:blk];
        }
    }
    else{
        EASFKLog(@"ASFKGlobalThreadpool: Pipeline session %@ not found",sessionId);
    }
    return res;
}
-(BOOL) postDataAsUnorderedSet:(NSSet*)data forSession:(ASFK_IDENTITY_TYPE)sessionId blocking:(BOOL)blk{
#ifdef __ASFK_DEBUG__
    if(blk){
        DASFKLog(@"Performing blocking call");
    }
    else{
        DASFKLog(@"Performing non-blocking call");
    }
#endif
    BOOL res=NO;
    [lkMutexL1 lock];
    ASFKThreadpoolSession* ss=[allSessions objectForKey:sessionId];
    [lkMutexL1 unlock];
    if(ss){
        if(ss->callMode == ASFK_BC_NO_BLOCK && blk){
            MASFKLog(ASFK_STR_MISCONFIG_OP);
        }
        else{
            res=[ss postDataItemsAsUnorderedSet:data blocking:blk];
        }
    }
    else{
        EASFKLog(@"ASFKGlobalThreadpool: Pipeline session %@ not found",sessionId);
    }
    return res;
}

-(BOOL) addSession:(ASFKThreadpoolSession*)aseq withId:(ASFK_IDENTITY_TYPE)identity{
    BOOL res=NO;
    [lkMutexL1 lock];
    if([allSessions objectForKey:identity]==nil){
        [runningSessions setObject:aseq forKey:identity];
        [allSessions setObject:aseq forKey:identity];
        //[lkMutexL2 lock];
        onlineSessions=[runningSessions allValues];
        //[lkMutexL2 unlock];
        res=YES;
    }
    
    [lkMutexL1 unlock];
    return res;
}
-(ASFKThreadpoolSession*) getThreadpoolSessionWithId:(ASFK_IDENTITY_TYPE)identity{
    [lkMutexL1 lock];
    ASFKThreadpoolSession* ss=[allSessions objectForKey:identity];
    [lkMutexL1 unlock];
    return ss;
}
-(void) _reassignProcs:(ThreadpoolConfig&)tpc{
    long proc=0;
    tpcfg.requiredThreadsCount=[onlineSessions count];
    tpc.actualThreadsCount=self.threadsLimit;
    
    ThreadpoolConfigRange tcr;
    if(tpc.requiredThreadsCount==0){
        for(proc=0;proc<tpc.actualThreadsCount;++proc){
            tcr.lowBound=0;
            tcr.length=0;
            vectProc2Bounds[proc]=tcr;
        }
        return;
    }
    
    if(tpc.requiredThreadsCount<tpc.actualThreadsCount){
        tpc.share=tpc.actualThreadsCount/tpc.requiredThreadsCount;
        tpc.residue=tpc.actualThreadsCount%tpc.requiredThreadsCount;

        for(proc=0;proc<tpc.actualThreadsCount;++proc){
            tcr=vectProc2Bounds[proc];
            tcr.length=1;
            tcr.lowBound=(proc) % tpc.requiredThreadsCount;
            vectProc2Bounds[proc]=tcr;
        }
    }
    else{
        tpc.share = tpc.requiredThreadsCount / tpc.actualThreadsCount;
        tpc.residue = tpc.requiredThreadsCount%tpc.actualThreadsCount;
        long residue=tpc.residue;
        long lb=0;
        for(proc=0;proc<tpc.actualThreadsCount;++proc){
            tcr.lowBound=lb;
            tcr.length=tpc.share;
            if(residue>0){
                tcr.length+=1;
                residue--;
            }
            lb+=tcr.length;

            vectProc2Bounds[proc]=tcr;
        }
    }
}

-(void) _engineDeploy{
    __block NSMutableArray* blocks=[NSMutableArray array];

    long i=0;
    for (i=0; i<tpcfg.actualThreadsCount;++i)
    {
        dispatch_block_t b0= ^{
            long ii=i;
            long selectedSlot=0;
            while(1)
            {
                ThreadpoolConfig tpc=tpcfg;
                ThreadpoolConfigRange tcr;
                [lkMutexL1 lock];

                ///-----Housekeeping-----
                ///
                if(vectProc2Bounds.size() != tpcfg.actualThreadsCount){
                    vectProc2Bounds.clear();
                    vectProc2Bounds.resize(tpcfg.actualThreadsCount);
                }
                
                [self _reassignProcs:tpc];
                tcr=vectProc2Bounds[ii];
                if(tcr.length==0 ||
                   [onlineSessions count]==0){
                    [lkMutexL1 unlock];
                    continue;
                }
                selectedSlot=(selectedSlot+1);
                if(tcr.lowBound<=selectedSlot &&
                   tcr.length+tcr.lowBound>selectedSlot){
                }
                else{
                    selectedSlot=tcr.lowBound;
                }
                if(selectedSlot >= [onlineSessions count]){
                    [lkMutexL1 unlock];
                    continue;
                }

                __block ASFKThreadpoolSession* ss=[onlineSessions objectAtIndex:selectedSlot];
                if(ss && [ss->cblk cancellationRequested]){
                    ThreadpoolConfig tpc1=tpcfg;
                    //[lkMutexL2 lock];
                   // @try{
                        //[lkMutexL1 lock];
                    onlineSessions=nil;
                    onlineSessions=[runningSessions allValues];
                        //[lkMutexL1 unlock];
                    //}
//                    @catch(NSException* exp){
//                        NSLog(@"Err 1: %@",exp);
//                        int x=0;
//                    }
//                    @finally{
//                        //NSLog(@"Finally");
//                    };
                    [self _reassignProcs:tpc1];
                    [lkMutexL1 unlock];
                    //[lkMutexL1 unlock];
                    continue;
                }

                [lkMutexL1 unlock];
                if(ss){
                    [ss select:ii routineCancel:^id(id identity) {
                        DASFKLog(@"Stopping session %@, selector %ld",identity,selectedSlot);
                        
                        [self _cancelSessionInternally:identity];
                        ThreadpoolConfig tpc1=tpcfg;
                        [lkMutexL1 lock];
                        [self _reassignProcs:tpc1];
                        [lkMutexL1 unlock];
                        //[lkMutexL1 unlock];
                        return nil;
                    }];
                }
            }
        };
        dispatch_block_t b1=dispatch_block_create(static_cast<dispatch_block_flags_t>(0), b0);
        [blocks addObject:b1];
    }

        id sumresult= [[ASFKGlobalQueue singleInstance]submitBlocks:blocks summary:(id)^{
            busyCount=0;
            return nil;
        }
        QoS: qos blocking:NO];

}
@end

