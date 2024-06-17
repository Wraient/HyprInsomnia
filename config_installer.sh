tmp_dir=$(mktemp -d /tmp/config_installer.XXXXXXXXXX)
cd tmp_dir
git clone https://github.com/wraient/dotfiles.git

cd dotfiles

for file in *; do
  # Check if it's a directory (not a file or hidden directory)
  if [[ -d "$file" ]] && [[ ! "$file" =~ ^\..* ]]; then
    echo "Processing directory: $file"

    original_path=$(cat ./$file/.original_path)
    mkdir -p $original_path
    cp -r ./$file/* $original_path/

    echo Copied file from ./$file ---> $original_path

    # Change to the directory for further operations
    pushd "$file" > /dev/null
    # Your commands on the files in the directory go here
    popd > /dev/null
  fi
  if [ -f "$file" ]; then
    continue
  fi
done


