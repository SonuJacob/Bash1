
# Agency is the first argument or the script    
$AGENCY=$Args[0]
# Or it can be hard coded in the script if you just want to double click to start it
$AGENCY="DOH"
# Wait time between each script loop
$WAIT=60
# Initialisation of PREV_DATE variable
$PREV_DATE=0

# Rclone command
$RCLONE_START="rclone copy"
# Rclone parameters that will be used for all execution
$RCLONE_PARAM='--size-only --fast-list --exclude "/System Volume Information/**" --exclude "/$RECYCLE.BIN/**"'

# We are using a speficif Function RCLONE_RUN with 3 parameters : source folder, source s3, folder to excude
function RCLONE_RUN($SOURCE,$DESTINATION,$EXCLUDE)
{
    # We are creating the rclone command to run on the system by concatenating RCLONE_START and RCLONE_PARAM with the function parameters
    $RCLONE_CMD=$RCLONE_START+' "'+$SOURCE+'" "'+$DESTINATION+'" '+$RCLONE_PARAM+' --exclude "'+$EXCLUDE+'" '
    echo "Executing : RCLONE for $AGENCY from $SOURCE to $DESTINATION"
    # Rclone run
    Invoke-Expression $RCLONE_CMD
}

# Infite while lopp
while ($true)
{
    # Retrieving date, time, month, month in text format, day number, year
    $DATE=Get-Date -Format "yyyy.MM.dd"
    $TIME=Get-Date -Format "HH:mm:ss"
    $MONTH=Get-Date -Format "MM"
    $MONTH_TEXT=Get-Date -Format "MMM"
    $DAY=Get-Date -Format "dd"
    $YEAR=Get-Date -Format "yy"

    # If the previous loop and this lopp have the same date : we do nothing (ie. one execution per day )
    if ( $DATE -eq $PREV_DATE )
    {
        echo "DATE $DATE is the same as PREVIOUS DATE $PREV_DATE...waiting $WAIT seconds ( $TIME )"
    }
    else
    {
        # switch/Case based on the AGENCY
        # Then each agency have it's own day/month conditions to run
        switch ( $AGENCY )
        {
            "DOH"
            {
                if ( $DAY -eq "01" -And ( $MONTH -eq "03" -Or $MONTH -eq "06" -Or $MONTH -eq "09" -Or $MONTH -eq "12" ) )
                {
                    RCLONE_RUN "G:/EDO/OFO" "OFO:doh-ofo-qe-18mo/$MONTH_TEXT$YEAR" "/System Volume Information/**"
                    $EXEC="YES"
                }
                elseif ( ( $DAY -eq "31" -And ( $MONTH -eq "03" -Or $MONTH -eq "12" )) -Or ( $DAY -eq "30" -And ( $MONTH -eq "06" -Or $MONTH -eq "09" )) )
                {
                    RCLONE_RUN "J:/" "DMHF://dmhf-qe-1year/QE $MONTH_TEXT$YEAR" "/users/**"
                    RCLONE_RUN "E:/FTP" "DMHF://dmhf-qe-1year/QE $MONTH_TEXT$YEAR/FTP" "/NAOP/**"
                    $EXEC="YES"
                }
            }
            "OIG"
            {
                if ( ( $DAY -eq "31" -And ( $MONTH -eq "03" -Or $MONTH -eq "12" )) -Or ( $DAY -eq "30" -And ( $MONTH -eq "06" -Or $MONTH -eq "09" )) )
                {   
                    RCLONE_RUN "N:/" "oigarchive:das-oig-qe-1year/QE $MONTH_TEXT$YEAR" "/BMISuite3.2.1.1000/**"
                    $EXEC="YES"
                }
            }
            "DAF"
            {
                if ( $DAY -eq "30" -And $MONTH -eq "06" )
                {   
                    RCLONE_RUN "G:/" "DAF_AWS:daf-fye-5year/FYE$YEAR" "/System Volume Information/**"
                    $EXEC="YES"
                }
            }
        }

        # If no RCLONE Execution, then it means the date is not a match
        if ( $EXEC -ne "YES" )
        {
            echo "DATE $DATE is not a match for $AGENCY"
        }
    }

    # Storing PREV_DATE in DATE for later comparaison
    $PREV_DATE=$DATE

    # We are waiting a number of seconds equal to $WAIT
    Start-Sleep -Seconds $WAIT
}