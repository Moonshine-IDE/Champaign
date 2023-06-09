/*
 *  Copyright (C) 2016-present Prominic.NET, Inc.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the Server Side Public License, version 1,
 *  as published by MongoDB, Inc.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  Server Side Public License for more details.
 *
 *  You should have received a copy of the Server Side Public License
 *  along with this program. If not, see
 *
 *  http://www.mongodb.com/licensing/server-side-public-license
 *
 *  As a special exception, the copyright holders give permission to link the
 *  code of portions of this program with the OpenSSL library under certain
 *  conditions as described in each individual source file and distribute
 *  linked combinations including the program with the OpenSSL library. You
 *  must comply with the Server Side Public License in all respects for
 *  all of the code used other than as permitted herein. If you modify file(s)
 *  with this exception, you may extend this exception to your version of the
 *  file(s), but you are not obligated to do so. If you do not wish to do so,
 *  delete this exception statement from your version. If you delete this
 *  exception statement from all source files in the program, then also delete
 *  it in the license file.
 */

package champaign.core.ansi;

/**
 * This enum defines ANSI colors, usually used in console output
 */
enum abstract Color( String ) to String {

    // Reset
    var Color_Off='\033[0m';

    // Regular
    var Black='\033[0;30m';
    var Red='\033[0;31m';
    var Green='\033[0;32m';
    var Yellow='\033[0;33m';
    var Blue='\033[0;34m';
    var Purple='\033[0;35m';
    var Cyan='\033[0;36m';
    var White='\033[0;37m';

    // Bold
    var BBlack='\033[1;30m';
    var BRed='\033[1;31m';
    var BGreen='\033[1;32m';
    var BYellow='\033[1;33m';
    var BBlue='\033[1;34m';
    var BPurple='\033[1;35m';
    var BCyan='\033[1;36m';
    var BWhite='\033[1;37m';

    // Underline
    var UBlack='\033[4;30m';
    var URed='\033[4;31m';
    var UGreen='\033[4;32m';
    var UYellow='\033[4;33m';
    var UBlue='\033[4;34m';
    var UPurple='\033[4;35m';
    var UCyan='\033[4;36m';
    var UWhite='\033[4;37m';

    // Background
    var On_Black='\033[40m';
    var On_Red='\033[41m';
    var On_Green='\033[42m';
    var On_Yellow='\033[43m';
    var On_Blue='\033[44m';
    var On_Purple='\033[45m';
    var On_Cyan='\033[46m';
    var On_White='\033[47m';

    // High Intensity
    var IBlack='\033[0;90m';
    var IRed='\033[0;91m';
    var IGreen='\033[0;92m';
    var IYellow='\033[0;93m';
    var IBlue='\033[0;94m';
    var IPurple='\033[0;95m';
    var ICyan='\033[0;96m';
    var IWhite='\033[0;97m';

    // Bold High Intensity
    var BIBlack='\033[1;90m';
    var BIRed='\033[1;91m';
    var BIGreen='\033[1;92m';
    var BIYellow='\033[1;93m';
    var BIBlue='\033[1;94m';
    var BIPurple='\033[1;95m';
    var BICyan='\033[1;96m';
    var BIWhite='\033[1;97m';

    // High Intensity backgrounds
    var On_IBlack='\033[0;100m';
    var On_IRed='\033[0;101m';
    var On_IGreen='\033[0;102m';
    var On_IYellow='\033[0;103m';
    var On_IBlue='\033[0;104m';
    var On_IPurple='\033[0;105m';
    var On_ICyan='\033[0;106m';
    var On_IWhite='\033[0;107m';

}