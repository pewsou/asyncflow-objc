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

#import "ASFKComposeBase.h"

@implementation ASFKComposeBase
-(NSArray*) runOnArray:(NSArray*)array{
    return [self runOnArray:array withProcedures:self.procs withSummary:self.sumproc];
}
-(NSArray*) runOnArray:(NSArray*)array withSummary:(ASFKExecutableProcedureSummary)summary{
//    if(self.controlData.isBusy){
//        return array;
//    }
    return [self runOnArray:array withProcedures:self.procs withSummary:summary];
}
-(NSArray*) runOnArray:(NSArray*)array withProcedures:(NSArray<ASFKExecutableProcedure>*) procs{
    return [self runOnArray:array withProcedures:procs withSummary:self.sumproc];
}
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary{
    return [self runOnDictionary:dictionary withProcedures:self.procs withSummary:self.sumproc];
}
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs{
    return [self runOnDictionary:dictionary withProcedures:procs withSummary:self.sumproc];
}
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary withSummary:(ASFKExecutableProcedureSummary)summary{
    return [self runOnDictionary:dictionary withProcedures:self.procs withSummary:summary];
}
-(id) runOnUnspecified:(id)uns{

    return [self runOnUnspecified:uns withProcedures:self.procs withSummary:self.sumproc];
}
-(id) runOnUnspecified:(id)uns withSummary:(ASFKExecutableProcedureSummary)summary{

    return [self runOnUnspecified:uns withProcedures:self.procs withSummary:summary];
}
-(id) runOnUnspecified:(NSDictionary*)uns withProcedures:(NSArray<ASFKExecutableProcedure>*) procs{

    return [self runOnUnspecified:uns withProcedures:procs withSummary:self.sumproc];
}
-(id) runOnUnspecified:(id)uns withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary{

    return [self runOnUnspecified:uns withProcedures:procs withSummary:summary];
}

-(void*) runOnUnspecifiedC:(void*)uns {
    NSLog(@"Method is not implemented since this class should not be used directly but through its derivatives");
    return uns;
}

-(void*) runOnUnspecifiedC:(void*)uns withSummary:(ASFKExecutableProcedureSummaryCStyle)summary{
        NSLog(@"Method is not implemented since this class should not be used directly but through its derivatives");
    return uns;
}
-(NSArray*) runOnArray:(NSArray*)array withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary{
    NSLog(@"Method is not implemented since this class should not be used directly but through its derivatives");
    return nil;
}
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary{
    NSLog(@"Method is not implemented since this class should not be used directly but through its derivatives");
    return nil;
}
@end
