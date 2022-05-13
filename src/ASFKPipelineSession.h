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

#ifndef ASFKPipelineSession_h
#define ASFKPipelineSession_h
#import "ASFKBase.h"
typedef enum enumASFKPipelineExecutionStatus{
    eASFK_ES_HAS_MORE=0,
    eASFK_ES_HAS_NONE,
    eASFK_ES_WAS_CANCELLED,
    //eASFK_ES_WAS_EXPIRED,
    eASFK_ES_SKIPPED_MAINT
} eASFKPipelineExecutionStatus;
@interface ASFKPipelineSession : ASFKBase{
    @public ASFKControlBlock* cblk;
    @public std::atomic<BOOL> paused;
}
@property  ASFK_IDENTITY_TYPE sessionId;
-(id)initWithSessionId:(ASFK_IDENTITY_TYPE)sessionId andSubsessionId:(ASFK_IDENTITY_TYPE)subId;
-(ASFKControlBlock*) getControlBlock;
-(void) flush;
-(void) cancel;
-(void) postDataItemsAsArray:(NSArray*)array;
-(void) postDataItemsAsOrderedSet:(NSOrderedSet*)set;
-(void) postDataItemsAsUnorderedSet:(NSSet*)set;
-(void) postDataItemsAsDictionary:(NSDictionary*)dict;
-(void) postDataItem:(id)dataItem;
-(void) addRoutinesFromArray:(NSArray<ASFKExecutableRoutine>*)procs;
-(void) replaceRoutinesWithArray:(NSArray<ASFKExecutableRoutine>*)procs;
-(void) setProgressRoutine:(ASFKProgressRoutine)progress;
-(void) setSummary:(ASFKExecutableRoutineSummary)sum;
-(void) setExpirationSummary:(ASFKExecutableRoutineSummary)sum;
-(eASFKPipelineExecutionStatus) select:(long)selector routineCancel:(ASFKCancellationRoutine)cancel;
-(void) setCancellationHandler:(ASFKCancellationRoutine)cru;
-(void) setExpirationCondition:(ASFKExpirationCondition*) trop;
-(BOOL) hasSessionSummary;

-(BOOL) isBusy;

-(long) procsCount;
-(long) itemsCount;
-(void) ping;
@end

#endif /* ASFKPipelineSession_h */
