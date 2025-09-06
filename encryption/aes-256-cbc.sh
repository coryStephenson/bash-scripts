#!/usr/bin/env bash

set -euo pipefail
set -o errtrace


encrypt() {
  echo -e     "\n\n****************************************************************************************\n
Name of Script: encrypt.sh\n
Author: Cory Stephenson\n
View script for further description of tasks\n
Tasks:\n
1) Prompt user to enter a plaintext message\n
2) Message input validation\n
3) Prompt the user to enter a password for encryption\n
4) Password input validation\n
5) Encrypt the message with the given password and redirect the output to a file named message.enc\n
6) Use the openssl enc -aes-256-cbc command for Step 5\n
********************************************************************************************\n\n"


  read -p "Enter message to be encrypted: " plaintext_message

  if [[ -z "${plaintext_message}" ]]; then
          echo "The message variable is empty."
      else
          echo "You have entered this message: ${plaintext_message}"
          read -p "Do you want to continue? (y/n): " choice

            if [[ $choice != "y" ]]; then
                echo "Aborting..."
                exit 1
            fi
      fi


  read -sp "Enter password for encryption: " password

  if [[ -z "${password}" ]]; then
          echo "The password variable is empty."
      else
          read -sp "Retype password for matching: " password_test

          if [[ "${password}" != "${password_test}" ]]; then
                        echo "Password strings do not match. File may be altered or corrupted."
                  else
                        echo "Password strings match."
                        read -p "Do you want to continue the encryption process? (y/n): " choice

                          if [[ $choice != "y" ]]; then
                              echo "Aborting..."
                              exit 1
                          fi

                        echo "Encrypting the message with symmetric algorithm AES-256 CBC..."

                        openssl enc -aes-256-cbc "${plaintext_message}"


                        sleep 3

                  fi


      fi


  exit 0
}


decrypt() {
  echo -e "\n\n****************************************************************************************\n
Name of Script: decrypt.sh\n
Author: Cory Stephenson\n
View script for further description of tasks\n
Tasks:\n
1) Prompt user to enter the name of the encrypted file\n
2) Encrypted file name input validation\n
3) Prompt the user to enter the decryption password\n
4) Decryption password input validation\n
5) Decrypt the content and display the original message\n
6) Use the openssl enc -aes-256-cbc -d command for Step 5\n
7) Ensure that the decrypted message is only displayed if the password is correct\n
********************************************************************************************\n\n"

  read -p "Enter the name of the encrypted file: " encrypted_message

  if [[ ! -e "${encrypted_message}" ]]; then
          echo "The encrypted file cannot be found."
      else
          echo "This encrypted file was found: ${encrypted_message}"
          read -p "Do you want to continue? (y/n): " choice

            if [[ $choice != "y" ]]; then
                echo "Aborting..."
                exit 1
            fi
      fi

  read -sp "Enter the decryption password: " password

  if [[ -z "${password}" ]]; then
          echo "The password variable is empty."
      else
          read -sp "Retype password for matching: " password_test

          if [[ "${password}" != "${password_test}" ]]; then
                        echo "Password strings do not match. File may be altered or corrupted."
                  else
                        echo "Password strings match."
                        read -p "Do you want to continue the decryption process? (y/n): " choice

                          if [[ $choice != "y" ]]; then
                              echo "Aborting..."
                              exit 1
                          fi

                        echo "Decrypting the message with symmetric algorithm AES-256 CBC..."

                        openssl enc -aes-256-cbc -d "${encrypted_message}"


                        sleep 3
                  fi


      fi



  exit 0
}


mainmenu() {

PS3=$'\n\n'"What would you like to do? "
COLUMNS=1
main=("Encrypt message" "Decrypt message" "Return to main menu" "Quit")


while true
do
        echo -e "\nMAIN MENU\n\n"
	select a in "${main[@]}";
        do

	    case $a in


		    "Encrypt message")

                    encrypt
                    ;;


			"Decrypt message")

			        decrypt
				    ;;


			"Return to main menu")

				    mainmenu
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

