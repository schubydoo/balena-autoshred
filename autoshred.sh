#!/bin/bash
# AUTHOR:   Phil Porada - philporada@gmail.com (autoshred) / Marcus Schubert - schuby@gmail.com (balena conversion)
# WHAT:     (Phil) Automatically runs shred on any block device plugged into the device aside from devices in the exclusion list
# NOTES:    (Phil) I do not own any rights to Shredder or shred.

BLD=$(tput bold)
RST=$(tput sgr0)
RED=$(tput setaf 1)
GRN=$(tput setaf 2)
YEL=$(tput setaf 3)
BLU=$(tput setaf 4)
DIR=$(dirname "$(readlink -f "$0")")

# Following code is borrowed from ketilmo from https://github.com/ketilmo/balena-ads-b/blob/master/planefinder/start.sh
missing_variables=true

echo "Validating variables..."
echo " "
sleep 2

while [ "$missing_variables" = true ]; do 
        missing_variables=false
        
        # Begin defining all the required configuration variables.

        [ -z "$EXCLUDE" ] && echo "Excluded devices are not defined" && missing_variables=true || echo "Excluded devices defined as: $EXCLUDE"
        [ -z "$ROUNDS" ] && echo "Number of wipes to perform is not defined" && missing_variables=true || echo "Number of wipe round wipes defines as: $ROUNDS"
        [ -z "$AUTOSTART" ] && echo "Autostart is not set" && missing_variables=true

        # End defining all the required configuration variables.

        echo " "
        
        if [ "$missing_variables" = true ]
        then
                echo "Settings missing, halting startup for 60 seconds..."
                echo " "
                sleep 60
        fi
done

echo "Settings verified, proceeding with startup."
echo " "

# Variables are verified – continue with startup procedure. (This ends the borrowed code)

function display_warning() {
    echo "${BLD}${RED}#####################################################################################${RST}"
    echo "${BLD}${RED}# WARNING: THIS SCRIPT WILL NUKE DATA IN ANY BLOCK DEVICE NOT IN THE EXCLUSION LIST #${RST}"
    echo "${BLD}${RED}#####################################################################################${RST}"
    echo
    echo "${BLD}Current exclusion list. Run \`lsblk\` to check mounted devices.${RST}"
    echo "${BLD}+--------------------+${RST}"
    for i in ${EXCLUSION[@]}; do
        echo "/dev/$i"
    done
	echo
	echo "${BLD}Current number of wipes set${RST}"
    echo "${BLD}+--------------------+${RST}"
	echo "Rounds: $ROUNDS"
    echo
    echo "${BLD}Important Read for Data Sanitization${RST}"
    echo "${BLD}+---------------------+${RST}"
    echo "http://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-88r1.pdf"
    echo
}


function shredder_ascii() {
    # Thanks to http://www.retrojunkie.com/asciiart/cartchar/turtles.htm
    cat <<- 'EOF'
                          .;iiiiii;;.
                      ;i!!!!!!!!!!!!!!!i.
                   .i!!!!!!!!!'`.......`''=
                  i!!!!!!!!' .:::::::::::::..
                 i!!!!!!!!' :::::::::::::::::::.
              ' i!!!!!!!!' :::::::::::::::::::::::.
             :  !!!!!!!!! ::::::::::::::::::::::::::.
            ::  !!!!!!!! ::::::::::::::::::::::::::::::
           ::: <!!!!!!!! ::::::::::::::::::::::::::::::: i!!!!>
          .::: <!!!!!!!> ::::::::::::::::::::::::::::'` i!!!!!'
          :::: <!!!!!!!> ::::::::::::::::::::::::'`  ,i!!!!!!'
          :::: `!!!!!!!> :::::::::::::::::::''`  ,i!!!!!!!!'..
         `::::  !!!!!!!!.`::::::::::::::'` .,;i!!!!!!!!!!' ::::.
          ::::  !!!!!!!!!, `''''```  .,;ii!!!!!!!!!!!'' .::::::::
      i!; `::' .!!!!!!!!!!!i;,;i!!!!!!!!!!!!!!!!!!' .::::::::::::::
     i!!!!i;,;i!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!''`  ::::::::::::::::::
     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'`..euJB$. ::::::::::::::::' ::.
      !!!!!!!!!!!!!!!!!!!!!!!!!!!''`,   $$$$$$$$$Fc :::::::::::::: .:::::
        `''''''''''''''''` ..z e$$$F   d$P"`""??<<3c :::::::::::' ::::::::.
           :::: ?Fx$b. "?$ $$$b($$"   dF   'ud$$$$$$c `:::::::' .:::::::::::
           `:::  $$$$$r-.  P9$$$?$bedE' .,d$$$$$$$P"   `::::' .:::::::::::::
            :::: `? =       """"   ""?????????""  .~~~.  :'.:::::::::::::::' ;
            :::::  $$$eeed" .~~~~~~~~~~~~~~~~~~~~~~~~~~~  ::::::::::::::::' i!
            :::::  $$$PF" .~~.$.~~~~~~~~~~~~~~~~~~~~~~~~.  :::::::::::::' ,!!!
             ::       .~~~~~~ ?$ ~~~~~~~~~~~~~~~~~~~~~~~~.  ::::::::::'  ;!!!!
              ::  ~~~~~~~~~~~.`$b ~~~~~~~~~~~~~~~~~~~~~~~~. `:::::::'  ;!!!!!'
             `:::  ~~~~~~~~~~~ `$L ~~~~~~~~~~~~~~~~~~~~~~~ .  `''`   ;!!!!!!
              ::::  ~~~~~~~~~~~ `$c'~~~~~~~~~~~~~~~~~~~~~ ~~ ,iiii! i!!!!!!  !
              :::::  ~~~~~~~~~~~ "$c`~~~~~~~~~~~~~~~~~~~ ~~ ;!!!!' i!!!!!!  i!
              `:::::  ~~~~~~~~~~~ `$.`~~~~~~~~~~~~~~~~  ~  <!!!!' ;!!!!!!'  !!
               :::'`   `~~~~~~~~~~ "$.`~~~~~~~~~~~~~~ .~ .!!!!!' ;!!!!!!!  i!!
                  ,i!    ~~~~~~~~~~ "$r'~~~~~~~~~~~~ '  ;!!!!!  ;!!!!!!!!  !!!
                 !!!!i !i. `~~~~~~~~ `$c ~~~~~~~~~~~~  <!!!!'  i!!!!!!!!!  !!!
                 :!!!!> !!!;  ~~~~~~~. "$. ~~~~~~~~ .;!!!!'  ;!!!!!!!';!!  `!!
                 `!!!!! `!!!!;.  ~~~~~~~~~~~~~~  .;i!!!!' .i!!!!!!' ,!!!!i  !!
                  !!!!!!; `!!!!!i;. ~~~~~~~ .;i!!!!''`.;i!!!!!!!'.;!!!!!!!>  !
              :!  !!!!!!!i `'!!!!!!!!!!!!!!!'''`.;ii!!!!!'`.'` ;!!!!!!!!!!   '
EOF
}


function display_header() {
    echo "                               ${BLD}${BLU}###########################################${RST}"
    echo "                               ${BLD}${BLU}#${RST}     ${YEL}Block Device Data Destroyer         ${BLD}${BLU}#${RST}"
    echo "                               ${BLD}${BLU}#${RST} ${YEL}==> Data today, /dev/null tomorrow  <== ${BLD}${BLU}#${RST}"
    echo "                               ${BLD}${BLU}###########################################${RST}"
}


function cleanup() {
    echo "${BLD}${YEL}[-]${RST} Any prior jobs running will continue running even after this script has exited."
    echo "${BLD}${YEL}[-]${RST} Exiting..."
}

function run_bddd() {
        clear
        display_header
        echo
        DETECTED=( $(lsblk -dnlo KNAME -e 11,1 | grep -v --color=auto ${EXCLUSION[@]/#/-e}) )

        echo "${BLD}+ Current list of detected devices +${RST}"
        echo "${BLD}+----------------------------------+${RST}"
        for i in ${DETECTED[@]}; do
            echo "/dev/$i"

            if [ -b "/dev/$i" ]; then
                if [ -z $(ps aux | grep " shred" | grep $i | egrep -v '(grep|defunct)' | awk '{print $16}' | sed 's|/dev/||g' | head -n1) ]; then
                    bash -c "shred --force --zero --iterations=$ROUNDS /dev/$i 2>/dev/null; if [ $? -eq 0 ]; then echo 1 > /sys/block/$i/device/delete; fi;" & &>/dev/null
                elif [ ! -z $(ps aux | grep " shred" | egrep -v "($i|grep|defunct)" | awk '{print $16}' | sed 's|/dev/||g' | head -n1) ]; then
                    continue
                fi
            fi
        done
        echo
        echo
        echo "${BLD}+ Current running jobs +${RST}"
        echo "${BLD}+----------------------+${RST}"
        ps aux | grep " shred" | egrep -v '(grep|delete)'
        sleep 1
    done

    # Resets the tty
    if [ -t 0 ]; then
        stty sane
    fi
}


### Order of operations
trap cleanup SIGINT SIGTERM SIGKILL SIGTSTP
clear
export -f shredder_ascii
shredder_ascii
display_header
sleep 5
run_bddd
