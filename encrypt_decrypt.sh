#!/bin/bash

PASSWORD=$2

encrypt_file() {
    local input_file=$1
    local output_file="${input_file}.enc"
    openssl enc -aes-256-cbc -salt -pbkdf2 -k "$PASSWORD" -in "$input_file" -out "$output_file" && rm "$input_file"
}

decrypt_file() {
    local input_file=$1
    local output_file=${input_file%.enc}

    # Attempt to decrypt the file
    if openssl enc -d -aes-256-cbc -pbkdf2 -k "$PASSWORD" -in "$input_file" -out "$output_file"; then
        echo "Decryption successful."

        # If the decrypted file is a zip, extract it
        if [[ $output_file == *.zip ]]; then
            unzip -j "$output_file" -d "${output_file%.zip}"
            rm "$output_file"
        fi

        # Delete the input file after successful decryption
        rm "$input_file"
    else
        echo "Decryption failed. Incorrect password or other error."
        # Remove the partially created output file if decryption fails
        [[ -f "$output_file" ]] && rm "$output_file"
        return 1
    fi
}



encrypt_folder() {
    local folder=$1
    local zip_file="${folder}.zip"
    zip -r "$zip_file" "$folder"
    encrypt_file "$zip_file" && rm -r "$folder"
}

decrypt_folder() {
    decrypt_file $1
}

if [[ $1 == "encrypt" && -d $3 ]]; then
    encrypt_folder $3
elif [[ $1 == "encrypt" && -f $3 ]]; then
    encrypt_file $3
elif [[ $1 == "decrypt" && -f $3 ]]; then
    decrypt_file $3
elif [[ $1 == "decrypt" && -d $3 ]]; then
    decrypt_folder $3
else
    echo "Usage: $0 <encrypt|decrypt> <password> <file|folder>"
fi
