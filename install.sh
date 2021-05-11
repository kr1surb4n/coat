
# install ubuntu packages
cat packages/apt_packages | xargs sudo apt -mfy install

# install python packages
pip3 install -r packages/python3_packages

# make folders
mkdir ~/archive ~/bin ~/docs ~/range ~/workshops ~/library ~/temp ~/Portal ~/sync ~/junkyard

# pull submodules
git submodule update --init

# run fzf install
sh lib/fzf/install

# add coat to .bashrc
echo "source ${PATH_TO_COAT}/coat.sh" >> ~/.bashrc
source ~/.bashrc

# create coat files
> $PATH_TO_COAT/storage/teleports
> $PATH_TO_COAT/storage/spot
> $PATH_TO_COAT/storage/bookmarks