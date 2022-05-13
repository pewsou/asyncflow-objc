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
#define ASFK_LOCAL_REPLACE 0
#define ASFK_LOCAL_ADD 1
#import "ASFKBase.h"
#import "ASFKBase+Internal.h"
#import "ASFKBase+Statistics.h"
#import "ASFKControlBlock+Internal.h"
#import "ASFKPipelineSession.h"
#import "ASFKExpirationCondition.h"
#import <atomic>
#import <queue>
struct sASFKPrioritizedQueueItem{
    long priority;
    long queueId;
};
class ASFKComparePriorities {
public:
    bool operator()(sASFKPrioritizedQueueItem& pq1, sASFKPrioritizedQueueItem& pq2)
    {
        if (pq1.priority <= pq2.priority) return true;
        return false;
    }
};
@interface ASFKPipelineSession()

@end
@implementation ASFKPipelineSession{
    std::atomic<BOOL> isStopped;
    ASFKExpirationCondition* excond;
    std::atomic<long> busyCount;
    NSMutableArray<ASFKThreadpoolQueue*>* dataQueues;
    ASFKThreadpoolQueue* queueZero;
    NSMutableArray<ASFKExecutableRoutine>* procs;
    NSMutableArray* intermediateProcs;
    ASFKExecutableRoutineSummary passSummary;
    ASFKExecutableRoutineSummary expirationSummary;
    ASFKProgressRoutine progressProc;
    ASFKCancellationRoutine cancellationHandler;
    NSLock* lock;
    NSRange execRange;
    std::priority_queue<sASFKPrioritizedQueueItem, std::vector<sASFKPrioritizedQueueItem>, ASFKComparePriorities> pq;
}
-(id)init{
    self=[super init];
    if(self){
        [self _PSinitWithSession:nil andSubsession:nil];
    }
    return self;
}
-(id)initWithSessionId:(ASFK_IDENTITY_TYPE)sessionId andSubsessionId:(ASFK_IDENTITY_TYPE)subId{
    self=[super init];
    if(self){
        [self _PSinitWithSession:sessionId andSubsession:subId];
    }
    return self;
}
-(void)_PSinitWithSession:(ASFK_IDENTITY_TYPE)sessionId andSubsession:(ASFK_IDENTITY_TYPE)subId{
    busyCount=0;
    lock=[NSLock new];
    procs=[NSMutableArray array];
    excond=[[ASFKExpirationCondition alloc]init];
    isStopped=NO;
    paused=NO;
    execRange=NSMakeRange(0, 1);
    dataQueues=[NSMutableArray array];
    queueZero=[[ASFKThreadpoolQueue alloc]init];
    if(sessionId){
        cblk= [self newSession:sessionId andSubsession:subId];// [ASFKControlBlock new];
    }else{
        cblk= [self newSession];// [ASFKControlBlock new];
    }
    
    self.sessionId=cblk.sessionId;

    intermediateProcs=[NSMutableArray array];
    passSummary=(id)^(id<ASFKControlCallback> controlBlock,NSDictionary* stats,id data){
        ASFKLog(@"ASFKPipelineSession: Stub summary");
        return data;
    };
    expirationSummary=(id)^(id<ASFKControlCallback> controlBlock,NSDictionary* stats,id data){
        ASFKLog(@"ASFKPipelineSession: Stub expiration summary");
        return data;
    };
    cancellationHandler=^id(id identity){
        return nil;
    };
}

-(ASFKControlBlock*) getControlBlock{
    return cblk;
}
-(void) setCancellationHandler:(ASFKCancellationRoutine)cru{
    if(cru){
        ASFKLog(@"ASFKPipelineSession: Setting Cancellation Routine Operator");
        [lock lock];

        cancellationHandler=nil;
        cancellationHandler=cru;

        [lock unlock];
    }
}

-(void) setExpirationCondition:(ASFKExpirationCondition*) trop{
    if(trop){
        ASFKLog(@"ASFKPipelineSession: Setting Expiration Operator");
        [lock lock];
        excond=nil;
        excond=trop;
        [lock unlock];
    }
}
-(void) setSummary:(ASFKExecutableRoutineSummary)sum{
    if(sum){
        [lock lock];

        passSummary=sum;

        [lock unlock];
    }else{
        WASFKLog(@"Pass Summary proc is undefined; not stored");
    }
}
-(void) setProgressRoutine:(ASFKProgressRoutine)progress{
    if(progress){
        [lock lock];

        [cblk setProgressRoutine:progress];

        [lock unlock];
    }
    else{
        WASFKLog(@"Progress proc is undefined; not stored");
    }
}
-(void) setExpirationSummary:(ASFKExecutableRoutineSummary)sum{
    if(sum){
        [lock lock];
        expirationSummary=sum;
        [lock unlock];
    }else{
        WASFKLog(@"Expiraion Summary proc is undefined; not stored");
    }
}

-(void) postDataItemsAsDictionary:(NSDictionary*)dict{
    [lock lock];
    if([dataQueues count]>0)
    {

        [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [[dataQueues objectAtIndex:0]queueFromItem:obj];
        }];
        sASFKPrioritizedQueueItem qin;
        qin.queueId=0;
        qin.priority=[[dataQueues objectAtIndex:0] count];
        pq.push(qin);
    }
    else{

        [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [queueZero queueFromItem:obj];
        }];

    }
    busyCount.fetch_add([dict count]);
    [lock unlock];
}
-(void) postDataItemsAsArray:(NSArray*)array{
    [lock lock];
    if([dataQueues count]>0){
        for (id item in array) {
            [[dataQueues objectAtIndex:0]queueFromItem:item];
        }
        sASFKPrioritizedQueueItem qin;
        qin.queueId=0;
        qin.priority=[[dataQueues objectAtIndex:0] count];
        pq.push(qin);
    }else{

        [queueZero queueFromArray:array];
    }
    busyCount.fetch_add([array count]);
    [lock unlock];

}
-(void) postDataItemsAsUnorderedSet:(NSSet*)set{
    [lock lock];
    if([dataQueues count]>0){
        for (id item in set) {
            [[dataQueues objectAtIndex:0]queueFromItem:item];
        }
        sASFKPrioritizedQueueItem qin;
        qin.queueId=0;
        qin.priority=[[dataQueues objectAtIndex:0] count];
        pq.push(qin);
    }else{

        for (id item in set) {
            [queueZero queueFromItem:item];
        }
    }
    busyCount.fetch_add([set count]);
    [lock unlock];
}
-(void) postDataItemsAsOrderedSet:(NSOrderedSet*)set{
    [lock lock];
    if([dataQueues count]>0){
        for (id item in set) {
            [[dataQueues objectAtIndex:0]queueFromItem:item];;
        }
        sASFKPrioritizedQueueItem qin;
        qin.queueId=0;
        qin.priority=[[dataQueues objectAtIndex:0] count];
        pq.push(qin);
    }
    else{

        for (id item in set) {
            [queueZero queueFromItem:item];
        }
    }
    busyCount.fetch_add([set count]);
    [lock unlock];
}
-(void) postDataItem:(id)dataItem{
    if(dataItem==nil)
        return;
    
    [lock lock];
    if([dataQueues count]>0){
        [[dataQueues objectAtIndex:0]queueFromItem:dataItem];
        busyCount.fetch_add(1);
        sASFKPrioritizedQueueItem qin;
        qin.queueId=0;
        qin.priority=[[dataQueues objectAtIndex:0] count];
        pq.push(qin);
    }else{

        [queueZero queueFromItem:dataItem];
        busyCount.fetch_add(1);
    }
    [lock unlock];

}
-(void) addRoutinesFromArray:(NSArray<ASFKExecutableRoutine>*)ps{
    if([ps count]>0){
        //ready=NO;
    [lock lock];
    [intermediateProcs addObject:@[@(ASFK_LOCAL_ADD),@([ps count]),ps]];
    [lock unlock];
    DASFKLog(@"Scheduled for addition %ld procs",[ps count]);

    }
}
-(void) replaceRoutinesWithArray:(NSArray<ASFKExecutableRoutine>*)ps{
    //ready=NO;
    [lock lock];
    long psc=[ps count];
    long procsc=[procs count];
    [intermediateProcs addObject:@[@(ASFK_LOCAL_REPLACE),@(procsc-psc),ps]];
    [lock unlock];

    DASFKLog(@"Scheduled for replacement %ld procs",[ps count]);

}
-(void)_updateRoutines{
    for (NSArray* ar in intermediateProcs)
    {
        if([[ar objectAtIndex:0]integerValue ]==ASFK_LOCAL_REPLACE){
            if([[ar objectAtIndex:2]count]>0)
            {
                long dqs=0;
                if(dataQueues){
                    if([dataQueues count]>0){
                        dqs=[dataQueues count];
                        ASFKLog(@"Removing %ld Routines",dqs);
                        ASFKThreadpoolQueue* q=[dataQueues objectAtIndex:0];
                        [dataQueues removeAllObjects];
                        [dataQueues addObject:q];
                        [q unoccupy];
                        [procs removeAllObjects];
                        [procs addObjectsFromArray:[ar objectAtIndex:2]];
                        dqs = [[ar objectAtIndex:2]count];
                        ASFKLog(@"Setting %ld Routines instead",dqs);
                        for (; dqs>1; --dqs) {
                            [dataQueues addObject:[ASFKThreadpoolQueue new]];
                        }
                    }else
                    {
                        [procs addObjectsFromArray:[ar objectAtIndex:2]];
                        dqs = [[ar objectAtIndex:2]count];
                        ASFKLog(@"Setting %ld Routines",dqs);
                        for (; dqs>0; --dqs) {
                            [dataQueues addObject:[ASFKThreadpoolQueue new]];
                        }
                    }
                    busyCount=0;
                }
            }else{
                ASFKLog(@"Removing all data queues and Routines");
                for (ASFKThreadpoolQueue* q in dataQueues) {
                    [q reset];
                }
                [dataQueues removeAllObjects];
                [procs removeAllObjects];
                busyCount=0;
            }
        }else{
            [procs addObjectsFromArray:[ar objectAtIndex:2]];
            long inc=[[ar objectAtIndex:1]integerValue ];
            ASFKLog(@"Adding %ld Routines",inc);
            for (long c=inc; c>0; --c) {
                [dataQueues addObject:[ASFKThreadpoolQueue new]];
            }
        }
        execRange=NSMakeRange(0, [dataQueues count]);
    }

    [self _resetPriorityQueue];
    [self _adoptDataFromZeroQueue];

    long c=0;
    for (ASFKThreadpoolQueue* q in dataQueues) {
        sASFKPrioritizedQueueItem qin;
        qin.queueId=c;
        qin.priority=[q count];
        if(qin.priority>0){
            pq.push(qin);
        }
        ++c;
    }

}

-(BOOL) hasSessionSummary{
    [lock lock];
    BOOL sp=passSummary?YES:NO;
    [lock unlock];
    return sp;
}
-(void) cancel{
    ASFKLog(@" Session %@ to be cancelled",self.sessionId);
    [cblk cancel];
    [self flush];

}
-(void) _resetQueues{
    for (ASFKThreadpoolQueue* q in dataQueues) {
        [q reset];
        [q unoccupy];
    }
}
-(void)flush{
    [lock lock];
    cblk->flushed=YES;
    [self _resetQueues];

    [queueZero reset];
    [lock unlock];
    busyCount=0;
}
-(void)pause{
    [lock lock];
    cblk->paused=YES;
    [lock unlock];

}
-(void)resume{
    [lock lock];
    cblk->paused=NO;
    [lock unlock];

}
-(void)reset{

}
-(long) procsCount{
    long c=0;
    [lock lock];
    c=[procs count];
    [lock unlock];
    return c;
}
-(long) itemsCount{
    return busyCount.load();
}
-(BOOL) isBusy{
    return busyCount.load()>0?YES:NO;
}

-(eASFKPipelineExecutionStatus) select:(long)selector routineCancel:(ASFKCancellationRoutine)cancel{

    [lock lock];
    [self _adoptDataFromZeroQueue];
    
    if([intermediateProcs count]>0){
        if( isStopped.load()){
            [self _updateRoutines];
            isStopped=NO;
            [intermediateProcs removeAllObjects];
            [lock unlock];
            return eASFK_ES_SKIPPED_MAINT;
        }else{
            isStopped=YES;
            [lock unlock];
            return eASFK_ES_SKIPPED_MAINT;
        }
    }
    if(isStopped.load()){
 
        [lock unlock];

        return eASFK_ES_WAS_CANCELLED;
    }
    if(
       ([cblk cancellationRequestedByCallback]
        || [cblk cancellationRequestedByStarter])

       ){
 
        [self _resetPriorityQueue];
        ASFKCancellationRoutine cru=cancellationHandler;
        [lock unlock];
        [self flush];
        cancel(self.sessionId);
        cru(self.sessionId);
        DASFKLog(@"Cancelling... Pt 0, session %@",self.sessionId);
        [self forgetAllSessions];
        return eASFK_ES_WAS_CANCELLED;
    }

    ASFKExecutableRoutineSummary summary;
    summary=passSummary;
    sASFKPrioritizedQueueItem qin;
    qin.queueId=-1;
    qin.priority=-1;
    if(pq.empty()){
        [lock unlock];

        return eASFK_ES_HAS_NONE;
    }else{
        qin= pq.top();
        pq.pop();
    }
    [lock unlock];
    long curpos=qin.queueId;
    long lastpos=curpos;
    while(1){
        if([cblk cancellationRequestedByCallback]||[cblk cancellationRequestedByStarter]){

                [lock lock];
                [self _resetPriorityQueue];
                ASFKCancellationRoutine cru=cancellationHandler;
                [lock unlock];
                [self flush];
                cancel(self.sessionId);
                cru(self.sessionId);
                [self forgetAllSessions];
                DASFKLog(@"Cancelling... Pt 1, session %@",self.sessionId);
                break;
        }
        
        [lock lock];
        if(curpos>=[dataQueues count]){
            [lock unlock];
            break;
        }
        ASFKExecutableRoutine eproc=[procs objectAtIndex:curpos];
        ASFKThreadpoolQueue* q=[dataQueues objectAtIndex:curpos];
        [lock unlock];
        BOOL empty;

        id result=[q pullAndOccupyWithId:selector empty:empty];
        if(result)
        {
            sASFKPrioritizedQueueItem sq0;
            [lock lock];
            ASFKExecutableRoutineSummary expirproc=expirationSummary;
            ASFKExpirationCondition* trp=excond;
            long long dqcount=[dataQueues count];
            if(curpos==dqcount-1)
            {
                [lock unlock];
                result=eproc(cblk,result);
                [lock lock];
                if([dataQueues count]>0){
                    sq0.queueId=0;
                    sq0.priority=[[dataQueues objectAtIndex:0] count];
                    pq.push(sq0);
                }
                [lock unlock];
                if([cblk cancellationRequestedByCallback]|| [cblk cancellationRequestedByStarter]){
 
                    [lock lock];
                    [self _resetPriorityQueue];
                    ASFKCancellationRoutine cru=cancellationHandler;
                    [lock unlock];
                    [self flush];
                    cancel(self.sessionId);
                    cru(self.sessionId);
                    [self forgetAllSessions];
                    DASFKLog(@"Cancelling... Pt 2, session %@",self.sessionId);
                    break;
                }
                busyCount.fetch_sub(1);
                if([cblk flushRequested]){
                    result=nil;
                }
                id res = result;
                if(summary){
                    res=summary(cblk,@{},result);
                }
                std::vector<long long> bc={busyCount.load()};
                if(trp && [trp isConditionMetForLonglongValues:bc data:result]){
                    ASFKLog(@"Expiring session %@",self.sessionId);

                    [self flush];
                    cancel(self.sessionId);
                    expirproc(cblk,@{},res);
                    break;
                }
            }
            else if(curpos<dqcount-1){
                [lock unlock];
                if([cblk flushRequested]){
                    [cblk flushRequested:NO];
                }
                else{
                    result=eproc(cblk,result);
                    if(!result){
                        result=[NSNull null];
                    }
                    if([cblk flushRequested]){
                        [cblk flushRequested:NO];
                    }else{
                        [lock lock];
                        long long dco=[dataQueues count];
                        long nextQ;
                        if(dco>0){
                            nextQ=(curpos+1)%dco;
                        }else{
                            [lock unlock];
                            break;
                        }
                        sq0.queueId=nextQ;
                        sq0.priority=[[dataQueues objectAtIndex:nextQ] count];
                        pq.push(sq0);
                        [[dataQueues objectAtIndex:nextQ]castObject:result session:nil exParam:nil];
                        [lock unlock];
                    }
                }
            }
            else{
                if(curpos<[dataQueues count]){
                    [[dataQueues objectAtIndex:curpos]unoccupyWithId:selector];
                }
                [lock unlock];
                break;
            }
        }
        else
        {
            if(empty){
            }
            else{
                sASFKPrioritizedQueueItem sq;
                sq.priority=[q count];
                if(sq.priority>0){
                    sq.queueId=curpos;
                    [lock lock];
                    pq.push(sq);
                    [lock unlock];
                }
            }
        }
        [lock lock];
        long long dco=[dataQueues count];
        [lock unlock];
        if(dco>0)
            curpos=(curpos+1)%dco;
        else
            curpos=lastpos;
        if(lastpos==curpos){
            break;
        }
    }
    
    return eASFK_ES_HAS_MORE;
}
-(void) _resetPriorityQueue{
    while (!pq.empty()) {
        pq.pop();
    }
}
-(void) _adoptDataFromZeroQueue{
    if(queueZero&&[queueZero count]>0&&[dataQueues count]>0){
        [[dataQueues objectAtIndex:0]queueFromQueue:queueZero];
        sASFKPrioritizedQueueItem qin;
        qin.queueId=0;
        qin.priority=[queueZero count];
        if(qin.priority>0){
            pq.push(qin);
        }
        [queueZero reset];
    }
}
@end
