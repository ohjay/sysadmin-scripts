#!/bin/bash
# automail
# An automatic email service. Allows the user to send routine (or non-routine) emails automatically
# and/or periodically, without need for a browser or a mail client GUI. 
#
# Usage description:
# The command takes arguments as follows:
# automail <subject> <from> <recipients> <txt file w/ msg content> <OPTIONAL: type> 
# <OPTIONAL: period length / day of month / date> <OPTIONAL: # of emails / time of day> 
# (in other words, 4-7 arguments, the first three of which are required). 
# - subject: the subject line
# - from: the email address from which the email is being sent
# - recipients: a list of recipients, separated by commas
# - txt file w/ msg content: a filepath pointing to the text file that contains the msg content
# - type: either QUANTITY or DATE or ONCE
#   - QUANTITY: this means that a certain number of emails will be sent off (starting immediately)
#   - DATE: this means that an email will be sent at a certain time/day of the month, every month
#   - ONCE: the email will be sent once, at the specified date
# - period length / day of month / date: if type == QUANTITY, this will be interpreted as "length (in sec)"
#   (the amount of time between emails); if type == DATE, this will mean "day of month"; 
#   if type == ONCE, this will be the date, in MM/DD/YYYY format (ex. 07/12/2017 would be July 12th, 2017)
# - # of emails / time of day: if type == QUANTITY, this will be interpreted as "# of emails";
#   if type == DATE or ONCE, this will mean "time of day"
# 
# Example usage:
# automail "A reminder from yourself" owen.jow01@gmail.com owenjow@berkeley.edu msgs/reminder.txt DATE 3 "3:00 PM"
# - this will send an email titled "A reminder from yourself" to owenjow@berkeley.edu every 3rd of the month at 3:00pm
#
# automail "What's up, future me?" sender@gmail.com receiver@gmail.com msgs/whatsup.txt ONCE "04/03/2018" "1:00 AM"
# - this will send one email, titled "What's up, future me?" to receiver@gmail.com on May 3rd, 2018 at 1:00am
# 
# automail "You should really get a life, bro" owenjow@berkeley.edu owenjow@berkeley.edu msgs/sad.txt
# - this will send the email "You should really get a life, bro" from owenjow@berkeley.edu to owenjow@berkeley.edu
# 
# Possible applications:
# - periodic reminder emails (ex. to pay for rent or internet service)
# - sending an email to yourself or someone else in the future
# - sending an email without opening a browser... just to be hipster
# - email lists (for variety, you can just edit the message in the file specified by <txt file w/ msg content>)
#
# Configuration: 
# - This script will require a small amount of setup and an OS X system.
# - Instructions for setup can be found here: http://hints.macworld.com/article.php?story=20081217161612647
#
# Questions/comments?
# If you have questions, comments, or concerns, feel free to 
# [use this script to] contact Owen Jow at owenjow@berkeley.edu.
# 
# $LastChangedDate: 2015-07-25 (Sat, 25 Jul 2015) $

# send <subject> <from> <recipients> <txt file w/ msg content>
# Sends an email in the most basic sense.
function send {
    { 
        printf "To: %s\nSubject: %s\n\n" "$3" "$1"
        if [ -e "$4" ]; then 
            echo "`cat "$4"`"
            echo `date`" | Sent the email \"$1\" to $3" >> "$log_file"
        else 
            echo "Error: the file $4 does not exist!" >> "$error_file"
        fi
    } | sendmail -f "$2" "$3"
}

# send_periodically_by_quantity <subject> <from> <recipients> <txt_file> <period_len IN SEC> <num_emails>
# Sends the email NUM_EMAILS times periodically, every PERIOD_LEN seconds.
# This function is not intended to be used for spam, as I do not endorse spam. 
# Please do not use this for spam.
function send_periodically_by_quantity {
    local subject="$1"
    local from="$2"
    local recipients="$3"
    local txt_file="$4"
    local period_len="$5"
    local num_emails="$6"
    
    # Make sure that PERIOD_LEN and NUM_EMAILS are positive numbers
    if ! [[ "$period_len" =~ ^[0-9]+$ ]]; then
        echo "Error: period_len (the # of seconds b/e emails) must be a positive integer!"
        exit 1
    elif ! [[ "$num_emails" =~ ^[0-9]+$ ]]; then
        echo "Error: num_emails must be a positive integer!"
        exit 1
    fi
    
    while (( $num_emails > 0 )); do
        send "$subject" "$from" "$recipients" "$txt_file"
        sleep $period_len
        let "num_emails -= 1"
    done
}

# send_periodically_by_date <subject> <from> <recipients> <txt_file> <day> <time_of_day>
# Sends the email on day of the month specified by DAY at TIME_OF_DAY.
# For example, if these values were 4 and 5:00 respectively, then every month the email 
# would be sent at 5am on the 5th. 
#
# [Realistically, however, this function will probably require your computer 
# to be up and running, which it may not be at 5am on the 5th.]
#
# Note: if you do not already have a crontab, this function may complain.
# On the other hand, it should still work as specified. And since it creates a crontab
# for you, all potential future complaints should be headed off.
function send_periodically_by_date {
    local subject="$1"
    local from="$2"
    local recipients="$3"
    local txt_file="$4"
    local day="$5"
    local time_of_day="$6"
    
    # Check arguments
    if (( $day < 1 )) || (( $day > 31 )); then
        echo "Error: day must be within the range 1-31!"
        exit 1
    elif ! [[ "$time_of_day" =~ ^[0-9]{1,2}:[0-9]{2}[[:space:]][AP]M$ ]]; then
        echo "Error: time must be formatted such as 3:00 PM or 12:00 AM!"
        exit 1
    fi
    
    # Parse arguments for desired data
    local minute=`echo "$time_of_day" | sed 's/.*:\([0-9]\{2\}\).*/\1/g'`
    local hour=`echo "$time_of_day" | sed 's/^\([0-9]\{1,2\}\):.*/\1/g'`
    
    # Add this email job to the crontab
    crontab -l > cronjobs
    echo "$minute $hour $day * * ./automail.sh ""$subject"" ""$from"" ""$recipients"" ""txt_file" >> cronjobs
    crontab cronjobs
    rm cronjobs
}

# send_once <subject> <from> <recipients> <txt_file> <date> <time_of_day>
# Sends the email once, on the given DATE at TIME_OF_DAY.
# If this time is in the past, an error messag will be displayed.
# 
# Note: this function requires thet use of the 'at' command, 
# which may not be installed on your system. If this turns out to be the case, 
# simply execute "sudo apt-get install at".
function send_once {
    local subject="$1"
    local from="$2"
    local recipients="$3"
    local txt_file="$4"
    local date="$5"
    local time_of_day="$6"
    
    if ! [[ "$date" =~ ^[0-9]{2}/[0-9]{2}/[0-9]{4}$ ]]; then
        echo "Error: date must be in the format MM/DD/YYYY!"
        exit 1
    elif ! [[ "$time_of_day" =~ ^[0-9]{1,2}:[0-9]{2}[[:space:]][AP]M$ ]]; then
        echo "Error: time must be formatted such as 3:00 PM or 12:00 AM!"
        exit 1
    fi
    
    send "$subject" "$from" "$recipients" "$txt_file" | at "$time_of_day" "$date"
}

### Main script ###
# Create the log and error files if they do not already exist
# Food for future thought: should the user be able to specify the path for log/error files?
# Log file
if [ -f "./logs/automail/log.txt" ]; then
    log_file="./logs/automail/log.txt"
elif [ -f "~/logs/automail/log.txt" ]; then
    log_file="~/logs/automail/log.txt"
else
    mkdir -p ~/logs/automail
    echo "" > ~/logs/automail/log.txt
    log_file="~/logs/automail/log.txt"
fi

# Error file
if [ -f "./logs/automail/error.txt" ]; then
    error_file="./logs/automail/error.txt"
elif [ -f "~/logs/automail/error.txt" ]; then
    error_file="~/logs/automail/error.txt"
else 
    mkdir -p ~/logs/automail
    echo "" > ~/logs/automail/error.txt
    error_file="~/logs/automail/error.txt"
fi

if [[ ${#} == 4 ]]; then
    # Send just the one email
    send "$1" "$2" "$3" "$4"
elif [[ ${#} == 7 ]]; then
    case "$5" in
        "QUANTITY" ) send_periodically_by_quantity "$1" "$2" "$3" "$4" "$6" "$7";;
        "DATE" ) send_periodically_by_date "$1" "$2" "$3" "$4" "$6" "$7";;
        "ONCE" ) send_once "$1" "$2" "$3" "$4" "$6" "$7";;
        # more options can easily be added here! For example, sending periodically WITHIN the month
        * ) echo "Error: the <type> argument must be either QUANTITY, DATE, or ONCE"; exit 1;;
    esac
else
    echo "$0: usage" >&2
    echo "$0 <subject> <from> <recipients> <txt file w/ msg content>"
    echo "    +OPTIONAL [all or none] <type> <period_len(sec)/day/date> <# of emails/time>" >&2
    exit 1
fi
