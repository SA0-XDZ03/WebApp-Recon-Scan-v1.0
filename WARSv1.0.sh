#!/bin/bash

# Web Application Reconnaissance & Security Scanner v1.0 - WARSv1.0
# Author: SA0-XDZ03 / Beyond Beacon
# Version: 1.0

echo "--- Web Application Reconnaissance & Security Scanner v1.0 ---"

# Debug Log Function
logMessages() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Command Check Function
commandExists() {
    command -v "$1" >/dev/null 2>&1
}

# Ensure Script Runs As Root
if [[ $EUID -ne 0 ]]; then
    echo "Please Execute The Script As 'ROOT'"
    exit 1
fi

# Logging Information
logMessages "Updating System & Installing Required Packages ..."

# Updating System
sudo apt update && sudo apt upgrade -y && sudo apt clean && sudo apt autoremove && sudo apt clear

# Installing Tools
sudo apt install -y python3 python3-pip nmap git perl whois dnsrecon whatweb nikto

# Install Amass (better alternative to Sublist3r)
sudo apt install -y amass

# Creating Directories for Reports & Tools
mkdir -p ./Reports ./Tools

# Cloning: FinalRecon
if [ ! -d "./Tools/FinalRecon" ]; then
    logMessages "FinalRecon Not Found - Cloning FinalRecon ..."
    git clone https://github.com/thewhiteh4t/FinalRecon.git ./Tools/FinalRecon
    cd ./Tools/FinalRecon || exit
    pip3 install -r requirements.txt
    cd ../../
fi

# Cloning: Sublist3r
if [ ! -d "./Tools/Sublist3r" ]; then
    logMessages "Sublist3r Not Found - Cloning Sublist3r ..."
    git clone https://github.com/aboul3la/Sublist3r.git ./Tools/Sublist3r
    cd ./Tools/Sublist3r
    pip3 install --upgrade --force-reinstall .
    pip3 install -r requirements.txt
    cd ../../
fi

# Cloning: Nikto
if [ ! -d "./Tools/Nikto" ]; then
    logMessages "Nikto Not Found - Cloning Nikto ..."
    git clone https://github.com/sullo/nikto.git ./Tools/Nikto
fi

# Recon & Scanning Function
performScan() {
    local Domain=$1
    logMessages "Scanning $Domain"
    
    # Domain Reporting Directory
    mkdir -p "./Reports/$Domain"
    
    # FinalRecon - Full Scan
    logMessages "Running FinalRecon - Full Scan ..."
    FullDomain="https://"$Domain
    python3 ./Tools/FinalRecon/finalrecon.py --url "$FullDomain" --full | tee "./Reports/$Domain/FinalRecon.txt"
    
    # Sublist3r - Sub-Domain Enumeration
    logMessages "Running Sublist3r - Sub-Domain Enumeration ..."
    python3 ./Tools/Sublist3r/sublist3r.py -d "$Domain" -o "./Reports/$Domain/Sublist3r-SubDomains.txt"
    
    # Nmap - Port Scanning
    logMessages "Running Nmap - Port Scanning ..."
    nmap -sV -A -oN "./Reports/$Domain/Nmap.txt" "$Domain"
    
    # Nikto - Web Server Security Scanning
    logMessages "Running Nikto - Web Server Security Scan ..."
    perl ./Tools/Nikto/program/nikto.pl -h "$Domain" -output "./Reports/$Domain/Nikto.txt"

    # Amass - Sub-Domain Enumeration
    logMessages "Running Amass - Subdomain Enumeration ..."
    amass enum -d "$Domain" -o "./Reports/$Domain/Amass-SubDomains.txt"
    
    logMessages "$Domain - Successfully Scanned"
    logMessages "Reports Path: ./Reports/$Domain"
}

# Read Domains From Domains.txt & Initiate Scans
if [ -f "Domains.txt" ]; then
    while IFS= read -r Domain; do
        performScan "$Domain"
    done < Domains.txt
else
    logMessages "Domains.txt File Not Found. Please Create A File With A List Of Target Domains"
    exit 1
fi

logMessages "All Scans Completed Successfully"
