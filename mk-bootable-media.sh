#!/usr/bin/env bash

set -euo pipefail
set -o errtrace 

catch() {
  exit_code="${1}"
  line_number="${2}"
  iso_name="${ISO_NAME}"
  echo -e "ERROR: Exit code ${exit_code} at about line number ${line_number}.\n"
  echo -e "Removing ${iso_name}...\n"
  cd /home/cory/iso-files && rm -f ${ISO_NAME}*
  echo $?
  exit
}

argument=$(ls -1)
echo $argument

<<errors
By default, bash will continue after errors.
set -e stops the script on errors.
By default, unset variables don't error.
set -u stops the script on unset variables.
By default, a command failing doesn't fail the whole pipeline.
set -o pipefail prevents this.
Julia Evans @b0rk jvns.ca
errors

echo -e "\n\n****************************************************************************************\n
Name of Script: $0\n
Author: Cory Stephenson\n
View script for further description of tasks\n
Tasks:\n
1) Download .iso image\n
2) Paste corresponding .iso checksum upon prompt\n
3) Generate local checksum for verification\n
4) Compare and validate checksum\n
5) Create bootable media (case statement)\n
********************************************************************************************\n\n"

<<steps
1) Read user input for directory variable DESTINATION
2) Test directory variable non-existence && mkdir ~/iso-files
3) Read user input for .iso image URL variable ISO
4) Test image variable non-existence && download using wget inside while loop
5) Read user input for checksum corresponding to (3) and use case statement depending on checksum algorithm (MD5, SHA1, SHA256, etc.)
6) Generate local checksum using another case statement
7) Compare and validate checksums
8) Create bootable media
steps


# echo "number of seconds that the script has been running: ${SECONDS}" this prints a zero


generatechecksum() {


               # 6) Generate local checksum using another case statement
                   
	           echo -e "\nCHECKSUM GENERATOR"
		   
		   PS3=$'\n\n'"Using which algorithm? "
		   
		   select c in "${commands[@]}";
		   
		   do
		       
			 case $c in
			       
				"md5sum")
                                
                                : ' 
                                If md5sum is not found in the PATH variable, it may
                                already reside on the system. Try adding its filepath
                                to the PATH variable to see whether or not that solves 
                                the problem.
                                '

				echo -e "md5sum is located:\n\n"

                                echo -e "$(command -v md5sum)\n\n" 
				
				if [[ $? != 0 ]]; 
				
				then
				
				echo -e "\nThe command md5sum could not be found in the PATH variable.\n\n"
			        
				echo -e "$PATH\n\n"

			        echo -e "Would you prefer to\n"

				PS3=$'\n\n'"Please select one. "

				select add in "Prepend to PATH variable" "Append to PATH variable";
				do
					case $add in
						"Prepend to PATH variable")

							   echo -e "\n\nPrepending to PATH variable...\n\n"

							   PATH=$(command -v md5sum):$PATH

							   if [[ $? != 0 ]];
							   
							   then

							   echo -e "Error adding to PATH variable.\n\n"
                                                           
							   exit 1

							   fi

							   echo -e "Successfully added to PATH variable.\n\n"

							   echo "$PATH\n\n"

                                                           mainmenu
							   ;;

						"Append to PATH variable")
							   
							   echo -e "\n\nAppending to PATH variable...\n\n"

							   PATH=$PATH:$(command -v md5sum)

							   if [[ $? != 0 ]];

							   then

							   echo -e "Error adding to PATH variable.\n\n"

							   exit 1

							   fi

							   echo -e "Successfully added to PATH variable.\n\n"

							   echo -e "$PATH\n\n"

                                                           mainmenu
							   ;;
                                        
				        esac

                                done

				echo -e "Updating sources list...\n\n"
				
				apt update

				echo -e "\n\nInstalling software package md5sum...\n\n"
			        
			        apt -y install coreutils

				echo -e "\n\n"
			        
				fi
				
				LOCAL_MD5=$(md5sum ${ISO_NAME})
				
				echo -e "\n\nThe following checksum was generated
				
				\nwith md5sum for comparison purposes:\n\n $LOCAL_MD5\n\n"
				
				;;

		               "sha256sum")
				
                                : ' 
                                If sha256sum is not found in the PATH variable, it may
                                already reside on the system. Try adding its filepath
                                to the PATH variable to see whether or not that solves 
                                the problem.
                                '
                                echo -e "sha256sum is located:\n\n"

				echo -e "$(command -v sha256sum)\n\n" 

				if [[ $? != 0 ]]; 
				
				then
				
				echo -e "\nThe command sha256sum could not be found in the PATH variable.\n\n"
			       
				echo -e "$PATH\n\n"

			       	echo -e "Would you prefer to\n"

				PS3=$'\n\n'"Please select one. "

				select add in "Prepend to PATH variable" "Append to PATH variable";
				
				do
					case $add in
						"Prepend to PATH variable")

							   echo -e "Prepending to PATH variable...\n\n"

							   PATH=$(command -v sha256sum):$PATH

							   if [[ $? != 0 ]];
							   
							   then

							   echo -e "Error adding to PATH variable.\n\n"
                                                           
							   exit 1

							   fi

							   echo -e "Successfully added to PATH variable.\n\n"

							   echo -e "$PATH\n\n"

                                                           mainmenu
							   ;;

						"Append to PATH variable")
							   
							   echo -e "\n\nAppending to PATH variable...\n\n"

							   PATH=$PATH:$(command -v sha256sum)

							   if [[ $? != 0 ]];

							   then

							   echo -e "Error adding to PATH variable.\n\n"

							   exit 1

							   fi

							   echo -e "Successfully added to PATH variable.\n\n"

							   echo -e "$PATH\n\n"

                                                           mainmenu
							   ;;
                                        
				        esac

                                done

				echo -e "Updating sources list...\n\n"

				apt update

				echo -e "\n\nInstalling software package sha256sum...\n\n"

			        apt -y install coreutils

				echo -e "\n\n"

			        fi
                                
                 # Python program to find SHA256 hash string of a file
                 python3 /home/cory/iso-files/sha256hash.py
                 
		 echo -e "\n\n"
		 mainmenu
	                        ;;

                               "sha512sum")
			       
                                : ' 
                                If sha256sum is not found in the PATH variable, it may
                                already reside on the system. Try adding its filepath
                                to the PATH variable to see whether or not that solves 
                                the problem.
                                '

				echo -e "sha512sum is located:\n\n"

				echo -e "$(command -v sha512sum)\n\n"
				
				if [[ $? != 0 ]]; 
				
				then
					
				echo "\nThe command sha512sum could not be found in the PATH variable.\n\n"
                                
				echo -e "$PATH\n\n"

                                echo -e "Would you prefer to\n"

				PS3=$'\n\n'"Please select one. "
				
				select add in "Prepend to PATH variable" "Append to PATH variable";
				
				do
					case $add in
						"Prepend to PATH variable")

							   echo -e "\n\nPrepending to PATH variable...\n\n"

							   PATH=$(command -v sha512sum):$PATH

							   if [[ $? != 0 ]];
							   
							   then

							   echo -e "Error adding to PATH variable.\n\n"
                                                           
							   exit 1
							   
							   fi

							   echo -e "Successfully added to PATH variable.\n\n"

							   echo -e "$PATH\n\n"

                                                           mainmenu
							   ;;

						"Append to PATH variable")
							   
							   echo -e "\n\nAppending to PATH variable...\n\n"

							   PATH=$PATH:$(command -v sha512sum)

							   if [[ $? != 0 ]];

							   then

							   echo -e "Error adding to PATH variable.\n\n"
                                                           
							   exit 1

							   fi

							   echo -e "Successfully added to PATH variable.\n\n"

							   echo -e "$PATH\n\n"

                                                           mainmenu
							   ;;
                                        
				        esac

                                done
                                

				echo -e "Updating sources list..."

			        apt update

				echo -e "\n\nInstalling software package sha512sum...\n\n"

			        apt -y install coreutils

				echo -e "\n\n"
                                
				fi
			        
                                ;;
                                
                               "Return to main menu")
                                 
				       mainmenu
				   ;;
			      
			      *) echo -e "Invalid entry. Please try an option on display."
			          
				      exit 1
				      ;;
		        esac
              done
                                   
}

pastechecksum() {


# 5) Read user input for checksum corresponding to (3) and use case statement depending on checksum algorithm (MD5, SHA1, SHA256, etc.)

                    echo -e "\nPASTE CHECKSUM"
		    select b in "${crypt_algorithms[@]}";
		    do
			case $b in
				"MD5")
    			         read -p "MD5 checksum: " ISO_MD5
				 ;;
		                "SHA256")
		                 read -p "SHA256 checksum: " ISO_SHA256
	                         ;;
                                "SHA512")
                                 read -p "SHA512 checksum: " ISO_SHA512
				 ;;
                                "Return to main menu")
                                 
					mainmenu
			            ;;	 
			       *) echo -e "Invalid entry. Please try an option on display."
			            
				       exit 1
				    ;;
		        esac
                     done
                     
}


mainmenu() {

PS3=$'\n\n'"What would you like to do? "
COLUMNS=1
main=("Download .iso image(s)" "Paste corresponding .iso checksum(s) upon prompt" "Generate local checksum(s) for verification" "Quit")
crypt_algorithms=("MD5" "SHA256" "SHA512" "Return to main menu" "Quit")
commands=("md5sum" "sha256sum" "sha512sum" "Return to main menu")

while true
do
        echo -e "\nMAIN MENU\n\n"
	select a in "${main[@]}";
        do
	    
	    case $a in
		    
		    
		    "Download .iso image(s)")
                 
                                       # 1) Read user input for directory variable DESTINATION
	                                    echo "Desired .iso download directory? (Please enter absolute path) "

		                          # The -r option stipulates that backslash does not act as an escape character
		                            read -r DESTINATION

		                       # 2) Test directory variable non-existence && mkdir ~/iso-files
		
				            if [[ ! -d "${DESTINATION}" ]]; then
			                    
						    echo -e "\n\n${DESTINATION} not found. Making directory ${DESTINATION}..."
			                            mkdir "${DESTINATION}"
		
					       else
			          
						echo -e "\n\n${DESTINATION} already exists. The file will be placed in ${DESTINATION}."
		
					       fi

		                       # 3) Read user input for .iso image URL variable ISO

		                            echo -e "\n\nDesired .iso download URL? "
		                                 
					         read -r ISO_URL
		
					    echo -e "\n\nDesired filename for .iso download? "
		
					         read ISO_NAME


		                      # 4) Test image variable non-existence && download using wget inside while loop

					if [[ ! -e "${DESTINATION}/${ISO_NAME}" ]]; then
						exit_code="$?"
						line_number="$LINENO"
						iso_name="$ISO_NAME"
						trap "catch '${exit_code}' '${LINENO}'" ERR INT TERM EXIT
						echo -e "\n\n${ISO_NAME} not found. Starting download via wget..."
						axel -o "${DESTINATION}"/"${ISO_NAME}" "${ISO_URL}"
						echo -e "\n\nExit status (0 means success; 1 means error): $?"
					else
						echo -e "\n\n${ISO_NAME} already exists. The file resides 
							 in the following directory: ${DESTINATION}."
					fi

					   
					;;


		"Paste corresponding .iso checksum(s) upon prompt")
	             		 
                                pastechecksum
				;;


                
		       "Generate local checksum(s) for verification")

			        generatechecksum
				;;
	

                        "Quit") 
				
				echo -e "\n\nAre you sure you want to quit?\n"

                                select ans in "Yes" "No";
			        do	   
                                    case $ans in
                                          "Yes")
                                                  exit 0
                                                  ;;
                                          "No")
                                                  mainmenu
                                                  ;;
                                    esac
                                done
                       	        ;;

			       *) echo -e "\nInvalid entry. Please try an option on display."
			            
				       mainmenu
				    ;;
             esac
      done

done

}


mainmenu
