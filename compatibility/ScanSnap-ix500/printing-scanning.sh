#!/bin/bash
#Content of ~/scripts/gray_scan.sh

grayscan() {

if [[ $1 -eq 0 ]]
then
    OUT_DIR=/home/cory/bash-scripts
fi
fileNAME=scan_`date +%Y-%m-%d-%H%M%S`_

echo 'scanning...'
scanimage --verbose\
	  --page-width 221.121\
	  --page-height 876.695\
	  -l 0\
	  -t 0\
	  -x 221.121\
	  -y 876.695\
	  --ald=yes \
	  --overscan On \
	  --prepick=On \
	  --mode Gray \
	  --resolution 300 \
	  --format=png \
	  --source 'ADF Duplex' \
	  --swcrop=yes \
	  --buffermode On \
	  --swdespeck 2 \
	  --swdeskew=yes \
	  --swskip 20% \
 --device 'fujitsu:ScanSnap iX500:15419' \
	  --batch="$OUT_DIR/$fileNAME%03d.png"
 printf "Scanned document(s) to:\n\
	    $(ls --size --block-size=M $OUT_DIR/$fileNAME*)"

 echo -e "\n\nDesired filename for scanned document?(please use .png extension) "
 read file


 echo -e "\n\nScanned file is now called $file"
 
 echo -e "Converting $file to $(basename ${file} .png).pdf..."

 i=$(ls -r1) && declare -a PDF && PDF=($i); convert -density 300 ${PDF[@]} $(basename ${file} .png).pdf &> /dev/null 

 ls *.pdf

 echo -e "Removing original .png scans..."

 rm *.png

 xdg-open $(basename ${file} .png).pdf

}					 
					 

colorscan() {


if [[ $1 -eq 0 ]]
then
    OUT_DIR=/home/cory/bash-scripts
fi
fileNAME=scan_`date +%Y-%m-%d-%H%M%S`_

echo 'scanning...'
scanimage --verbose\
	  --page-width 221.121\
	  --page-height 876.695\
	  -l 0\
	  -t 0\
	  -x 221.121\
	  -y 876.695\
	  --ald=yes \
	  --overscan On \
	  --prepick=On \
	  --mode Color \
	  --resolution 300 \
	  --format=png \
	  --source 'ADF Duplex' \
	  --swcrop=yes \
	  --buffermode On \
	  --swdespeck 2 \
	  --swdeskew=yes \
	  --swskip 20% \
 --device 'fujitsu:ScanSnap iX500:15419' \
	  --batch="$OUT_DIR/$fileNAME%03d.png"
 printf "Scanned document(s) to:\n\
	    $(ls --size --block-size=M $OUT_DIR/$fileNAME*)"

 echo -e "\n\nDesired filename for scanned document?(please use .png extension) "
 read file


 echo -e "\n\nScanned file is now called $file"
 
 echo -e "Converting $file to $(basename ${file} .png).pdf..."

 i=$(ls -r1) && declare -a PDF && PDF=($i); convert -density 300 ${PDF[@]} $(basename ${file} .png).pdf &> /dev/null 

 ls *.pdf

 echo -e "Removing original .png scans..."

 rm *.png

 xdg-open $(basename ${file} .png).pdf

} 
 
mainmenu() {

PS3=$'\n\n'"What would you like to do? "
COLUMNS=1
main=("Scan something" "Print something" "Quit")
printing=("Print a file to the default printer" "List available printers" "Set the default printer" "More options")
while true
do
        echo -e "\nMAIN MENU\n\n"
	select a in "${main[@]}";
        do
	    
	    case $a in


		    "Scan something")


                                echo -e "\nSCAN MENU\n\n"
                                select ans in "Black and White" "Color" "Return to main menu" "Quit";
			        do	   
                                    case $ans in
                                          "Black and White")
                                                  grayscan
                                                  ;;
                                          "Color")
                                                  colorscan
                                                  ;;
				          "Return to main menu")
						  mainmenu
						  ;;
					  "Quit")
						  exit 0
						  ;;
					   *) echo -e "Invalid entry. Please try an option on display."
					      exit 1
				              ;;	      
                                    esac
                                done
                                ;;

		   "Print something")

                                echo -e "\nPRINT MENU\n\n"
				select b in "${printing[@]};
				do
				    case $b in
				          "Print a file to the default printer")
				 ;;

		   "Quit")
			   exit 0
			   ;;
		    *) echo -e "Invalid entry. Please try an option on display."
		       exit 1
	               ;;
           esac
      done

done      

}


mainmenu
