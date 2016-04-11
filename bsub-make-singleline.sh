echo "bsub -J $1 -q gerstein -W 1400 -o $1.log -e $1.err \"date; CMD; date\"" > bsub-script-$1.sh
chmod +x bsub-script-$1.sh
