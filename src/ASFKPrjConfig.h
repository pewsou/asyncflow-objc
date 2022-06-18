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

#ifndef ASFKPrjConfig_h
#define ASFKPrjConfig_h

#define __ASFK_DEBUG__ 1
#define __ASFK_VERBOSE_PRINTING__ 1

#define ASFK_PRIVSYM_TP_LOAD_FACTOR 1
#define ASFK_PRIVSYM_QOS_CLASS QOS_CLASS_BACKGROUND
#define ASFK_PRIVSYM_MEM_PRESSURE_MSG_THRESHOLD 1000000
#define ASFK_PRIVSYM_MEM_PRESSURE_MLBX_THRESHOLD 1000000
#define ASFK_PRIVSYM_PER_MLBX_MAX_MSG_LIMIT 1000000
#define ASFK_PRIVSYM_MAX_MLBX_LIMIT 100000
#define ASFK_PRIVSYM_MSG_RELEASE_SAMPLE_SIZE 10000
#define ASFK_PRIVSYM_OBJ_RELEASE_SAMPLE_SIZE 10000
#define ASFK_CALC_ELAPSED_TIME(starttime, endtime) (endtime-starttime)/double(1e9)

#define ASFK_RC_DESCR_DONE @"OK"
#define ASFK_RC_DESCR_FAILURE @"Fail"
#define ASFK_RC_DESCR_CANCELED @"Canceled"
#define ASFK_RC_DESCR_DEFERRED @"Deferred"
#define ASFK_RC_DESCR_IMPROPER @"Improper"

#define ASFK_STR_INVALID_PARAM @"some of input parameters are invalid"


#endif
/* ASFKPrjConfig_h */
