package champaign.core.ansi;

enum abstract Colors( String ) to String {

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