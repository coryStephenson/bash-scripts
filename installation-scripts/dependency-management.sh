#! /usr/bin/env bash


<<sources

Original script written by Yordan Georgiev
Explanations by BeastOfCaerbannog
Yordan Georgiev's profile: https://askubuntu.com/users/251228/yordan-georgiev
BeastOfCaerbannog's profile: https://askubuntu.com/users/618353/beastofcaerbannog
Found script here: https://askubuntu.com/questions/519/how-do-i-write-a-shell-script-to-install-
a-list-of-applications

sources


# fail on error and report it, debug all lines
set -eu -o pipefail

:' 

   Run as a superuser and do not ask for a password.
   Exit status as successful.
   
   Ref: https://linux.die.net/man/8/sudo,
        https://linux.die.net/abs-guide/internal.html
'

sudo -n true

<<test

Test the last variable's exit code and see if it equals '0'. If not, 
exit with an error and print a given message to the terminal.


Ref: https://linuxhint.com/bash-test-command/,
     http://tldp.org/LDP/abs/html/exit-status.html#EXSREF,
     https://bash.cyberciti.biz/guide/Logical_OR,
     https://linuxize.com/post/bash-exit/

test


test $? -eq 0 || exit 1 "you should have sudo privilege to run this script"


<<prereq

Tell the user that it is going to install some pre-requisite packages 
before installing the actual program


Ref: https://linuxhint.com/bash_echo/

prereq


echo installing the necessary dependencies by reading them in via heredoc...


<<read

Read a given file line by line forever or until receiving a value of "false,"
then continue on to the proceeding command.


Ref: https://linuxize.com/post/bash-while-loop/,
     http://linuxcommand.org/lc3_man_pages/readh.html,
     https://linuxhint.com/while_read_line_bash/,
     https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_09_04_09

read


<<install

Install the list of packages as a superuser without prompting for confirmation to install.

Ref: https://itsfoss.com/apt-get-linux-guide/

install


<<heredoc

Read the list of packages and gather them as standard input. Redirect it to the read command,
which captures it as the p variable, and then sends it to $p, which allows it to get executed
by the install command, and when it reaches the EOF delimiter, redirect the output to done,
effectively ending the while read loop.


Ref: https://linuxhint.comcat-command-bash/,
     https://linuxhint.com/what-is-cat-eof-bash-script/

heredoc


while read -r p; do apt install -y $p ; done < <(cat << "EOF"
	perl
	zip unzip
	exuberant-ctags
	mutt
	libxml-atom-perl
	postgresql-9.6
	libdbd-pgsql
	curl
	wget
	libwww-curl-perl
EOF
)

echo "install the dependent package(s)..."
echo "you have 5 seconds to proceed..."
echo "or"
echo "hit Ctrl+C to quit"
echo -e "\n"
sleep 6

sudo apt install -y tig
