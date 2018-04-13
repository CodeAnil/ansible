#!/bin/bash
OUTPUT="/var/tmp/stash_logs/repo_branch_output"
FAILURE="/var/tmp/stash_logs/repo_failure"
DATE=$(date +"%Y%m%d%H%M")
OUTPUT+=$DATE
FAILURE+=$DATE

if [ ! -d /var/tmp/stash_logs ]; then
        mkdir -m 755 /var/tmp/stash_logs
else
        rm -rf /var/tmp/stash_logs/commitlist
        rm -rf /var/tmp/stash_logs/*_branch

fi
repofile="/var/tmp/repolist"

#ls -1 /data/bitbucket-home-5.4.0/shared/data/repositories >> $repofile

cat $repofile | while read repo
do
        OLD_CHECK="TRUE"
        NEW_CHECK="TRUE"
        reponame=$(echo $repo | awk -F"/" '{print $2}')
        old_repo="/var/tmp/stash_logs/"$reponame"_old"
        new_repo="/var/tmp/stash_logs/"$reponame"_new"
        old_clone="ssh://git@10.54.212.14:7888/"$repo".git"
#       old_clone="http://kszm146@10.54.212.14:7990/scm/"$repo".git"
        new_clone="ssh://git@bitbucket.astrazeneca.net:7999/"$repo".git"
        mkdir -m 755 $old_repo
        cd $old_repo
        git clone $old_clone   2> /dev/null
        if [ $? -ne 0 ]; then
                echo "old $repo is empty"
                OLD_CHECK="FALSE"
        fi
        mkdir -m 755 $new_repo
        cd $new_repo
        git clone $new_clone   2> /dev/null
        if [ $? -ne 0 ]; then
                echo "new $repo is empty"
                NEW_CHECK="FALSE"
        fi

        if [[ $OLD_CHECK = "TRUE" && $NEW_CHECK = "TRUE" ]]; then
                cd $old_repo/$reponame
                branchfile="/var/tmp/stash_logs/"$reponame"_branch"
                git branch -a | grep remotes | grep -vi head | cut -d'/' -f3- >> $branchfile
                cat $branchfile | while read branch
                do
                        cd $old_repo/$reponame
                        git checkout $branch
                        #git log --oneline  | head -1 >> /var/tmp/stash_logs/commitlist
                        sha=`git log --oneline  | head -1 | awk '{print $1}'`
                        #msg=${git log --oneline  | head -1}
                        #echo $repo";"$branch";"$msg >> /var/tmp/stash_logs/commitlist
                        cd $new_repo/$reponame
                        git checkout $branch
                        #if git cat-file -e $sha 2> /dev/null
                        if git log | grep $sha 2> /dev/null
                        then
                                echo $repo";"$branch";"success >> $OUTPUT
                        else
                                echo $repo";"$branch";"failure >> $OUTPUT
                        fi
                done
                rm -rf $branchfile
        else
                echo $repo";;"repofailure >> $FAILURE
        fi
        rm -rf $old_repo $new_repo
done
