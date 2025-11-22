#!/bin/bash
source ./automated-user.sh 

manual_user() {
while true; do
	echo "Please enter your first name"
	read user_first_name
	if [[ "$user_first_name" =~ ^[A-Za-z]+$ ]]; then
		break
	else
		echo "Try again with a string only letters."
	fi
done
while true; do
	echo "Please enter your last name"
	read user_last_name
	if [[ "$user_last_name" =~ ^[A-Za-z]+$ ]]; then
		break
	else
		echo "Try again with a string just letters"
		fi
done

generate_username(user_first_name, user_last_name)
generate_password(user_first_name, user_last_name)
}
