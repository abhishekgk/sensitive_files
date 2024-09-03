#!/bin/bash

echo '---------------------------------------------------------';
echo '-------------------S3CURITYGUY---------------------------';
echo '---------------------------------------------------------';

echo 'enter the target name: '
read TARGET;
mkdir $TARGET;
cd $TARGET;

function subs() {
        /usr/bin/assetfinder --subs-only $TARGET | tee -a raw_subs.txt; /usr/bin/subfinder -d $TARGET | tee -a raw_subs.txt;
}

function amass() {
        /usr/bin/amass enum -d $TARGET -passive | tee -a amass_out.txt;
}

function amass_clean() {
        cat ./amass_out.txt | grep -oEi ".*.$TARGET" | grep -v 'record' | tee -a raw_subs.txt;
}

function harvester() {
        cat /opt/sources.txt |  while read source; do theHarvester -d "${TARGET}" -b $source -f "${source}_${TARGET}";done;
        cat *.json | jq -r '.hosts[]' 2>/dev/null | cut -d':' -f 1 | tee -a raw_subs.txt;
}

function crtsh() {
        curl -s "https://crt.sh/?q=${TARGET}&output=json" | jq -r '.[] | "\(.name_value)\n\(.common_name)"' | sort -u | tee -a raw_subs.txt
}       # Frpm crt.sh

function sorting_subs() {
        echo '--------------------------------------------------------------------'
        echo '--------------------------------------------------------------------'
        echo '-----------------------SORTING_SUBDOMAINS---------------------------'
        echo '--------------------------------------------------------------------'
        echo '--------------------------------------------------------------------'
        cat raw_subs.txt | sort -u | tee -a sorted_subs.txt;
}

function probe() {
        echo '--------------------------------------------------------------------'
        echo '--------------------FILTERING OUT VALID TARGETS---------------------'
        echo '--------------------------------------------------------------------'
        cat sorted_subs.txt | httprobe --prefer-https | tee -a probed_targets.txt;
}

function spider() {
        cat probed_targets.txt | hakrawler | tee -a spider.txt; cat probed_targets.txt | waybackurls | tee -a spider.txt; gospider -S probed_targets.txt -d 2 | tee -a spider.txt; katana -list probed_targets.txt -d 2 -jc | tee -a spider.txt; cat probed_targets.txt | gau | tee -a spider.txt
}

function scan_ports() {
        nmap -Pn -v $TARGET -v --max-retries=1 -oN nmap_out
}



function multiple_ip_scan() {
        echo ' provide file name or file path'
        read FILE;
        nmap -iL $FILE -v --max-retries=1 -Pn -oN nmap_out_all_ips
}

function sensitive_files() {
        echo '--------------ENTER YOUR URL BELOW---------------------------';
        read URL;
        echo '--------------SCANNING FOR SENSITIVE FILES--------------------';
        ffuf -w /opt/sensitive_files.txt -u $URL/FUZZ -v -rate 20 | tee -a fuzz_out.txt;
}

function small_files() {
        echo '---------------ENTER YOUR URL BELOW--------------------------';
        read URL;
        echo '===============scanning for files============================';
        ffuf -w /usr/share/seclists/Discovery/Web-Content/raft-small-files.txt -u $URL/FUZZ -v -rate 20 | tee -a small_files.txt;
}

function small_directories() {
        echo '----------------ENTER YOUR URL TO SCAN------------------------';
        read URL;
        echo '===============scanning for directories=======================';
        ffuf -w /usr/share/seclists/Discovery/Web-Content/raft-small-directories.txt -u $URL/FUZZ -v -rate 20 | tee -a small_directories.txt;
}

echo 'AVAILABLE TASKS';
echo '1. Get the subdomains and sort it out'
echo '2. Get valid subdomains'
echo '3. Get all possible urls and spider the application'
echo '4. Scan single for open ports'
echo '5. Scan multiple ips/hosts for open ports'
echo '6. Scan for sensitive files on url'
echo '7. Fuzz Files on url'
echo '8. Fuzz for Directories on url'
echo 'Exit'
echo 'WHAT TASK DO YOU WANNA DO?';
read TASK;

while [ "$TASK" != "Exit" ]; do
        if [ "$TASK" == "1" ]; then
                subs; amass; amass_clean;
                harvester; sorting_subs;
                echo 'ALL DONE ANYTHING ELSE?'

        elif [ "$TASK" == "2" ]; then
                probe;
                echo 'ALL DONE ANYTHING ELSE?'
        elif [ "$TASK" == '3' ]; then
                echo '---------------SPIDERING THE TARGET------------------';
                spider;
        elif [ "$TASK" == "4" ]; then
                echo 'scanning the target'
                scan_ports;
                echo 'output stored in nmap_out file'
        elif [ "$TASK" == "5" ]; then
                multiple_ip_scan;
                echo 'output stored in nmap_out_all_ips file';
        elif [ "$TASK" == "6" ]; then
                sensitive_files;
        elif [ "$TASK" == "7" ]; then
                small_files;
        elif [ "$TASK" == "8" ]; then
                small_directories;

        else
                echo 'THIS IS PLACEHOLDER WILL COME SOON'
        fi
        read TASK;
done;
