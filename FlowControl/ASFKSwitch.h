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
@interface ASFKSwitch : ASFKForkable
#pragma mark - Deferred Evaluation
-(void)addAction:(ASFKExecutableProcedure)theAction forStringCase:(NSString*)theCase;
-(void)addAction:(ASFKExecutableProcedure)theAction forRangeCase:(NSRange*)theCase;
-(void)addAction:(ASFKExecutableProcedure)theAction forNumberCase:(NSNumber*)theCase;
-(void)addAction:(ASFKExecutableProcedure)theAction forClassCase:(Class)theCase;

-(void)addDefaultAction:(ASFKExecutableProcedure)theAction;


-(void)match:(ASFKExecutableProcedure)pattern withNumber:(NSNumber*)n andTolerance:(double)tol;
-(void)match:(ASFKExecutableProcedure)theCase withString:(NSString*)s;
-(void)match:(ASFKExecutableProcedure)theCase withRange:(NSRange*)range;
//-(void)match:(ASFKExecutableProcedure)theCase withObject:(NSRange*)range;
-(void)matchAnyOfArray:(ASFKExecutableProcedureWithArray)pattern withObject:(NSRange*)range;
-(void)matchAnyOfDictionary:(ASFKExecutableProcedureWithDictionary)pattern withObject:(NSRange*)range;
@end
