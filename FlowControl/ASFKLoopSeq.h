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
//  Created by Boris Vigman on 23/02/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
@interface ASFKLoopSeq : ASFKForkable
/**
 @param numberOfIterations
 N < 0 -> run at least N iterations before quitting while ignoring the result;
 N > 0 -> run maximum N iterations and quit after that;
 N = 0 -> ignore value of N;
 */
@property long long numberOfIterations;
#pragma mark - Deferred evaluation
-(void) storeExitCondition:(ASFKExecutableProcedureConditional)condProc;
-(void) storeBody:(ASFKExecutableProcedure)body;
-(void) storeSummary:(ASFKExecutableProcedureSummary)summary;
-(void) run;

#pragma mark - Immediate Evaluation
-(void) runWithExitCondition:(ASFKExecutableProcedureConditional)condBlock andBody:(ASFKExecutableProcedure)body andSummary:(ASFKExecutableProcedureSummary)summary;
@end
