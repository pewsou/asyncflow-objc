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

#import "ASFKGlobalThreadpool.h"
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
    NSLock* lkMutexL2;

    NSCondition* lkCond;
    std::atomic<BOOL> shouldSleep;
    std::atomic<long> busyCount;
    std::atomic<long> qos;
    std::vector<ThreadpoolConfigRange> vectProc2Bounds;
}
#pragma mark Singleton Methods
+ (ASFKGlobalThreadpool *)sharedManager {
    static ASFKGlobalThreadpool *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        runningSessions=[NSMutableDictionary dictionary];
        onlineSessions=[NSMutableArray array];
        killedSessions=[NSMutableArray array];
        pausedSessions=[NSMutableDictionary new];
        allSessions=[NSMutableDictionary new];
        lkMutexL1=[NSLock new];
        lkMutexL2=[NSLock new];
        lkCond=[NSCondition new];
        self.threadsLimit=1;
        shouldSleep=YES;
        busyCount=0;
        qos=ASFK_PRIVSYM_QOS_CLASS;
        NSUInteger pr=[[NSProcessInfo processInfo] activeProcessorCount]*ASFK_TP_LOAD_FACTOR;
        if(self.threadsLimit<1||self.threadsLimit>pr ){
            ASFKLog(@"ASFKGlobalThreadpool: Requested number of threads is unavailable");
            self.threadsLimit=pr;
        }
        if(pr>1){
            self.threadsLimit=pr*ASFK_PRIVSYM_LOAD_FACTOR;
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
-(long long)runningSessionsCount{
    [lkMutexL1 lock];
    long long cc=[runningSessions count];
    [lkMutexL1 unlock];
    return (cc);
}
-(long long)pausedSessionsCount{
    [lkMutexL1 lock];
    long long ac=[pausedSessions count];
    [lkMutexL1 unlock];
    return (ac);
}
-(BOOL) isPausedSession:(ASFK_IDENTITY_TYPE)sessionId{
    BOOL result=NO;
    if(sessionId){
        [lkMutexL1 lock];
        ASFKPipelineSession* ss=[allSessions objectForKey:sessionId];
        result = ss->paused;
        [lkMutexL1 unlock];
    }
    return result;
}
-(BOOL) isBusySession:(ASFK_IDENTITY_TYPE)sessionId{
    BOOL result=NO;
    if(sessionId){
        [lkMutexL1 lock];
        ASFKPipelineSession* ss=[allSessions objectForKey:sessionId];
        result = [ss isBusy];
        [lkMutexL1 unlock];
    }
    return result;
}
-(NSArray*) getThreadpoolSessionsList{
    [lkMutexL1 lock];
    NSArray* a=[runningSessions allKeys];
    [lkMutexL1 unlock];
    return a;
}

-(long) itemsCountForSession:(ASFK_IDENTITY_TYPE)sessionId{
    long result=0;
    if(sessionId){
        [lkMutexL1 lock];
        ASFKPipelineSession* ss=[allSessions objectForKey:sessionId];
        if(ss){
            result= [ss itemsCount];
        }

        [lkMutexL1 unlock];
    }
    return result;
}
-(void) flushSession:(ASFK_IDENTITY_TYPE)sessionId{
    ASFKLog(@"ASFKGlobalThreadpool: Flushing session with ID %@",sessionId);
    if(sessionId){
        [lkMutexL1 lock];
        ASFKPipelineSession* ss=[allSessions objectForKey:sessionId];
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
        ASFKPipelineSession* ss=[allSessions objectForKey:obj];
        [ss flush];
        ss=nil;
    }];
    [lkMutexL1 unlock];
}
-(void) cancelSession:(ASFK_IDENTITY_TYPE)sessionId{
    DASFKLog(@"ASFKGlobalThreadpool: Cancelling session with ID %@",sessionId);
    if(sessionId){
        [lkMutexL1 lock];
        ASFKPipelineSession* ss=[allSessions objectForKey:sessionId];
        if(ss){
            [ss cancel];
            
            [runningSessions removeObjectForKey:sessionId];
            [lkMutexL2 lock];
            onlineSessions=[runningSessions allValues];
            [lkMutexL2 unlock];
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
        ASFKPipelineSession* ss=[allSessions objectForKey:obj];
        [ss cancel];

        ss=nil;
    }];
    [lkMutexL2 lock];
    tpcfg.actualThreadsCount=0;
    ThreadpoolConfig tpc=tpcfg;
    vectProc2Bounds.clear();
    vectProc2Bounds.resize(tpcfg.actualThreadsCount);
    onlineSessions = [NSArray new];
    [self _reassignProcs:tpc];
    [lkMutexL2 unlock];
    runningSessions = [NSMutableDictionary new];

    pausedSessions = [NSMutableDictionary new];
    allSessions = [NSMutableDictionary new];
    [lkMutexL1 unlock];
    DASFKLog(@"ASFKGlobalThreadpool: All sessions should be cancelled");
}

-(void) postDataAsDictionary:(NSDictionary*)data forSession:(ASFK_IDENTITY_TYPE)sessionId{
    [lkMutexL1 lock];
    ASFKPipelineSession* ss=[allSessions objectForKey:sessionId];
    [lkMutexL1 unlock];
    if(ss){
        [ss postDataItemsAsDictionary:data];
    }
    else{
        EASFKLog(@"ASFKGlobalThreadpool: Pipeline session %@ not found",sessionId);
    }
}
-(void) postDataAsArray:(NSArray*)data forSession:(ASFK_IDENTITY_TYPE)sessionId{
    [lkMutexL1 lock];
    ASFKPipelineSession* ss=[allSessions objectForKey:sessionId];
    [lkMutexL1 unlock];
    if(ss){
        [ss postDataItemsAsArray:data];
    }
    else{
        EASFKLog(@"ASFKGlobalThreadpool: Pipeline session %@ not found",sessionId);
    }
}
-(void) postDataAsOrderedSet:(NSOrderedSet*)data forSession:(ASFK_IDENTITY_TYPE)sessionId{
    [lkMutexL1 lock];
    ASFKPipelineSession* ss=[allSessions objectForKey:sessionId];
    [lkMutexL1 unlock];
    if(ss){
        [ss postDataItemsAsOrderedSet:data];
    }
    else{
        EASFKLog(@"ASFKGlobalThreadpool: Pipeline session %@ not found",sessionId);
    }
}
-(void) postDataAsUnorderedSet:(NSSet*)data forSession:(ASFK_IDENTITY_TYPE)sessionId{
    [lkMutexL1 lock];
    ASFKPipelineSession* ss=[allSessions objectForKey:sessionId];
    [lkMutexL1 unlock];
    if(ss){
        [ss postDataItemsAsUnorderedSet:data];
    }
    else{
        EASFKLog(@"ASFKGlobalThreadpool: Pipeline session %@ not found",sessionId);
    }
}

-(BOOL) addSession:(ASFKPipelineSession*)aseq withId:(ASFK_IDENTITY_TYPE)identity{
    BOOL res=NO;
    [lkMutexL1 lock];
    if([allSessions objectForKey:identity]==nil){
        [runningSessions setObject:aseq forKey:identity];
        [allSessions setObject:aseq forKey:identity];
        [lkMutexL2 lock];
        onlineSessions=[runningSessions allValues];
        [lkMutexL2 unlock];
        res=YES;
    }
    
    [lkMutexL1 unlock];
    return res;
}
-(ASFKPipelineSession*) getThreadpoolSessionWithId:(ASFK_IDENTITY_TYPE)identity{
    [lkMutexL1 lock];
    ASFKPipelineSession* ss=[runningSessions objectForKey:identity];
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
        long ind=0;
        long run=1;
        for(proc=0;proc<tpc.actualThreadsCount-tpc.residue;++proc){
            tcr.lowBound=ind;
            tcr.length=1;
            if(run==tpc.share){
                run=1;
                ++ind;
            }else{
                ++run;
            }
            vectProc2Bounds[proc]=tcr;
        }
        for(long r=tpc.residue;r>0;--r){
            tcr=vectProc2Bounds[tpc.actualThreadsCount-r];
            tcr.length=1;
            tcr.lowBound=r;
            vectProc2Bounds[tpc.actualThreadsCount-r]=tcr;
        }
    }else{
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
                [lkMutexL2 lock];

                ///-----Housekeeping-----
                ///
                vectProc2Bounds.clear();
                vectProc2Bounds.resize(tpcfg.actualThreadsCount);
                [self _reassignProcs:tpc];
                tcr=vectProc2Bounds[ii];
                if(tcr.length==0 ||
                   [onlineSessions count]==0){
                    [lkMutexL2 unlock];
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
                    [lkMutexL2 unlock];
                    continue;
                }

                __block ASFKPipelineSession* ss=[onlineSessions objectAtIndex:selectedSlot];
                if(ss && [ss->cblk cancellationRequested]){
                    ThreadpoolConfig tpc1=tpcfg;
                    onlineSessions=[runningSessions allValues];
                    [self _reassignProcs:tpc1];
                    [lkMutexL2 unlock];
                    continue;
                }

                [lkMutexL2 unlock];
                if(ss){
                    [ss select:ii routineCancel:^id(id identity) {
                        DASFKLog(@"Stopping session %@, selector %ld",identity,selectedSlot);
                        ThreadpoolConfig tpc1=tpcfg;
                        [lkMutexL2 lock];
                        onlineSessions=[runningSessions allValues];
                        [self _reassignProcs:tpc1];
                        [lkMutexL2 unlock];

                        return nil;
                    }];
                }
            }
        };
        dispatch_block_t b1=dispatch_block_create(static_cast<dispatch_block_flags_t>(0), b0);
        [blocks addObject:b1];
    }

        id sumresult= [[ASFKGlobalQueue sharedManager]submitBlocks:blocks summary:(id)^{
            busyCount=0;
            return nil;
        }
        QoS: qos blocking:NO];

}
@end

