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

#import "ASFKBase+Statistics.h"

@implementation ASFKBase (Statistics)
-(void)addProcTimeInterval:(double)timeInterval {
    [lkNonLocal lock];
    totalProcs+=1;
    totalProcsTime+=timeInterval;
    [priv_statistics setValue:@(totalProcs) forKey:ASFK_STATS_KEY_COUNT_PROCS];
    [priv_statistics setValue:@(totalProcsTime) forKey:ASFK_STATS_KEY_TIME_PROCS];
    [lkNonLocal unlock];
}
-(void)addSessionTimeInterval:(double)timeInterval {
    [lkNonLocal lock];
    totalSessions+=1;
    totalSessionsTime+=timeInterval;
    [priv_statistics setValue:@(totalSessions) forKey:ASFK_STATS_KEY_COUNT_SESSIONS];
    [priv_statistics setValue:@(totalSessionsTime) forKey:ASFK_STATS_KEY_TIME_SESSIONS];
    [lkNonLocal unlock];
}
@end
