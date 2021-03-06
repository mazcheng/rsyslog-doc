#!/bin/bash

# Do not allow use of unitilized variables
set -u

# Exit if any statement returns a non-true value
set -e

echo ""
echo "This script is intended to run with the clean repo version of the code."
echo "Run the sphinx-build command manually if you want to see your uncommited changes."
echo "If you run this script with uncommitted and un-pushed changes, YOU WILL LOSE THOSE CHANGES!"
echo ""
echo "Press Enter to continue or Ctrl-C to cancel...."
read -r REPLY


###############################################################
# Refresh local content (needs to run first)
##############################################################

echo "Fetching latest changes from origin ..."
git fetch origin --prune

# We need the tags also. The standard "git fetch origin" call does
# not appear to also grab the tags.
git fetch origin --tags


##############################################################
# Setup
##############################################################

# Formats that are built by default for new releases
declare -a formats
formats=(
  epub
  html
)

branches=($(git branch -a | grep remotes | grep origin | grep -v "HEAD" | sed -e 's/ //g' -e 's#remotes/origin/##g'))
latest_stable_branch=$(git branch -a | grep remotes | grep origin | grep -v "HEAD" | sed -e 's/ //g' -e 's#remotes/origin/##g' | grep -E 'v[0-9]+' | tail -n 1)
dev_branches=($(git branch -a | grep remotes | grep origin | grep -v "HEAD" | sed -e 's/ //g' -e 's#remotes/origin/##g' | grep -v "$latest_stable_branch"))

# Build release docs for latest official stable version
latest_stable_tag=$(git tag --list 'v*' | sort --version-sort | grep -Eo '^v[.0-9]+$' | tail -n 1)

# The latest stable tag, but without the leading 'v'
latest_stable_version=$(echo $latest_stable_tag | sed "s/[A-Za-z]//g")

# tarball representing the documentation for the latest stable release
doc_tarball="rsyslog-doc-${latest_stable_version}.tar.gz"


# Allow user to pass in the location for generated files
if [[ -z ${1+x} ]]; then
    output_dir="/tmp/rsyslog-doc-builds"
    echo -e "\nWARNING: Output directory not specified, falling back to default: $output_dir"
else
    output_dir=$1
    echo "Generated files will be placed in ${output_dir}"
    # otherwise if user didn't specify, go ahead and set a default

fi


##############################################################
# Functions
##############################################################

prep_branch_for_build() {

    branch=$1

    echo "Reset Branch $branch"
    git reset --hard

    echo "Tossing all non-committed changes"
    git clean --force -d

    echo "Checkout Branch $branch"
    git checkout origin/$branch ||
      { echo "[!] Checkout $branch failed... aborting"; exit 1; }

    echo "Pull Branch $branch"
    git pull origin $branch ||
      { echo "[!] Pull $branch failed... aborting"; exit 1; }

}


###############################################################
# Prep work
###############################################################

mkdir -p ${output_dir}



###############################################################
# Build formats for each dev branch
##############################################################

# Prep each branch for fresh build
for branch in "${dev_branches[@]}"
do
    prep_branch_for_build $branch

    for format in "${formats[@]}"
    do
        echo "Building $format for $branch branch"

        # Use values calculated by conf.py (geared towards dev builds) instead
        # of overriding them.
        sphinx-build -b $format source $output_dir/$branch ||
          { echo "[!] sphinx-build $format failed for $branch branch ... aborting"; exit 1; }

    done
done


###############################################################
# Build formats for stable branch
###############################################################

prep_branch_for_build $latest_stable_branch

for format in "${formats[@]}"
do
    echo "Building $format for $latest_stable_branch branch"

    # Override verbose release value calculated by conf.py that is intended
    # for dev builds (version, date, commit hash)
    sphinx-build -b $format source $output_dir/$latest_stable_branch -D release="$latest_stable_version" ||
      { echo "[!] sphinx-build $format failed for $latest_stable_branch branch ... aborting"; exit 1; }
done


###############################################################
# Build latest stable tag
###############################################################

git reset --hard
git clean --force -d
git checkout $latest_stable_tag

# Unless we override the "release" option, the default settings within
# the conf.py file will label generated content with specific date/commit
# info for easy visual reference
sphinx-build -b html source build -D release="$latest_stable_version" ||
    { echo echo "[!] sphinx-build failed for $latest_stable_tag tag ... aborting"; exit 1; }

tar -czf $output_dir/$doc_tarball source build LICENSE README.md build.sh ||
    { echo echo "[!] tarball creation failed for $latest_stable_tag tag ... aborting"; exit 1; }
