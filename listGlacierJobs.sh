#!/bin/bash

if [ ! "$1" ] || [ ! "$2" ]; then
	echo; echo;
	echo $0 [ Profile name ] [ Vault Name ]
	echo; echo;
	exit 1
fi

profile=$1
vaultName=$2

aws glacier list-jobs --profile $profile --account-id - --vault-name $vaultName
