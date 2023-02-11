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
//  Created by Boris Vigman on 15/02/2019.
//  Copyright © 2019-2023 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"

@interface ASFKParamSet:NSObject
@property (nonatomic) NSMutableArray<ASFKExecutableRoutine>* procs;
@property (nonatomic) NSMutableDictionary<id,ASFKExecutableRoutine>* namedprocs;
@property (nonatomic) ASFKExecutableRoutineSummary summary;
@property (nonatomic) ASFKProgressRoutine progress;
@property (nonatomic) ASFKCancellationRoutine cancProc;
@property (nonatomic) ASFKExpirationCondition* excond;
@property (nonatomic) ASFKOnPauseNotification onPause;
@property (nonatomic) id input;
@property (nonatomic) ASFK_IDENTITY_TYPE sessionId;
@property (nonatomic) eASFKBlockingCallMode bcallMode;
@property (nonatomic) ASFKReturnInfo* retInfo;
-(void) setupReturnInfo;
@end

@interface ASFKSessionalFlow (Internal)
-(NSDictionary*) _postUnorderedSet:(ASFKParamSet*) params blocking:(BOOL)blk;
-(NSDictionary*) _postOrderedSet:(ASFKParamSet*) params blocking:(BOOL)blk;
-(NSDictionary*) _postArray:(ASFKParamSet*) params blocking:(BOOL)blk;
-(NSDictionary*) _postDictionary:(ASFKParamSet*) params blocking:(BOOL)blk;
-(NSDictionary*) _callDictionary:(ASFKParamSet*) params;
-(ASFKParamSet*) _convertInputDictionary:(NSDictionary*) input to:(ASFKParamSet*)ps;
-(ASFKParamSet*) _convertInputArray:(NSArray*) input to:(ASFKParamSet*)ps;
-(ASFKParamSet*) _convertInputOrderedSet:(NSOrderedSet*) input to:(ASFKParamSet*)ps;
-(ASFKParamSet*) _convertInputUnorderedSet:(NSSet*) input to:(ASFKParamSet*)ps;
-(ASFKParamSet*) _convertInput:(id) input to:(ASFKParamSet*)ps;
-(ASFKParamSet*) _decodeSessionParams:(ASFKSessionConfigParams*)ex forSession:(id)sessionId;
-(ASFKParamSet*) _decodeExParams:(ASFKExecutionParams*)ex forSession:(id)sessionId;
@end
