#!/usr/bin/env /usr/local/cluster/software/builds/njc2/python/Python-2.7/Installation/bin/python

# args q, numProcs[.JobsPerProc], account, title, job file
import argparse, os, sys

qs = {
'def': ('general', '', 8),
'def4': ('general4core', '-W PARTITION:pe1955', 4),

'gen': ('general', '', 8),
'gen4': ('general4core', '-W PARTITION:pe1955', 4),

'sca': ('scavenge', '', 8),
'sca4': ('scavenge4core', '-W PARTITION:pe1955', 4),

'bre': ('breaker', '', 8),
'eph': ('eph', '', 4),
'ger': ('gerstein', '', 8),
'kle': ('kleinstein', '', 4),
'mol': ('molinaro', '', 4),
'sig': ('sigworth', '', 4),
'who': ('wang_hongwei', '', 4),
'wxi': ('wang_xiaojing', '', 8),
'wil': ('williams', '', 4),
'zhe': ('zhang_heping', '', 4),
'zhao': ('zhao', '', 8),
}
nns = qs.keys()
nns.sort()
nns = ', '.join(nns)

# map from a faux queue/partition name to the underlying queue name.
partitions = {
    'general4core': 'general',
    'scavenge4core': 'scavenge',
}

full2nn = dict((d[0], k) for k, d in qs.iteritems())

opts = argparse.ArgumentParser(usage='''%%(prog)s OPTIONS QueueName NumNodes[.MaxProcsPerNode] Account Title TaskFile

Generate a PBS submission script to run a job that works through the
simple queue of tasks given in the TaskFile. Each line of the file
defines a task in the form of a command (or sequence of commands) to
be executed. The job will distribute the tasks one by one to the
processors allocated by PBS, sending a new task to a processor when it
has completed a previous one. The task executes in a "bare"
environment (e.g., the settings in ~/.bashrc do not automatically
apply). If necessay, you can add adjustments to the environment at the
start of the command sequence for the task. Any output not explicitly
redirected by your task command sequence is collected into
per-execution-engine files. Index files are provided to enable
postprocessing to find uncaptured output for a particular task.

The job exits when all tasks have completed. Various logging files are
produced that contain information about the execution of individual
tasks and the overall state of the task processing. These file are
located in a subdirectory "SQ_Files_<PBSJOBID>" of the invocation
directory. Sibling files of TaskFile, with the suffices .REMAINING,
.ROGUES, .STATUS are all created. These contain information about the
jobs that had a suspicious return code, that may not have terminated
and an overall summary, respectively. Finally, PBS itself will
generate an output and error file in the submission directory.

NOTE: You must submit the generated script to PBS to actually run the job.

QueueName may be one of these abbreviations:

   %s

or the full name of a queue. 

If it is an unknown queue, then the CPU option must be given. This is the
physical number of cpus per node of the queue. If you don't know, it's
best not to guess. Check the HPC wiki for more info.

If not given, MaxProcsPerNode defaults to number of CPUs per node.'''%nns)

nnDesc = 'NumNodes[.MaxProcsPerNode]'
opts.add_argument('-W', '--Wopts', help='Set -W options.')
opts.add_argument('-C', '--Cores', help='Assumed number of cores per node of the queue.', type=int)
opts.add_argument('QueueName')
opts.add_argument(nnDesc)
opts.add_argument('Account')
opts.add_argument('Title')
opts.add_argument('TaskFile')

args = opts.parse_args()
# seems like should be able to do this directly in argparse...
args.NumProcs = getattr(args, nnDesc)
delattr(args, nnDesc)

queue, numProcs, account, title, jobFile = args.QueueName, args.NumProcs, args.Account, args.Title, args.TaskFile

ppn = args.Cores

if '.' in numProcs:
    if numProcs.count('.') > 1:
        opts.print_help(sys.stderr)
        sys.exit(1)

    numProcs, corelimit = [int(x) for x in numProcs.split('.')]
else:
    corelimit = None
    
if queue in qs or queue in full2nn:
    qnn = full2nn.get(queue, queue) # nicknames are the keys for the queue dictionary, map fullnames to nn
    queue, qwopts, qppn = qs[qnn] # now use the nn key to look up the queue data, including the fullname!
    queue = partitions.get(queue, queue) # finally, if a faux queue/partition, translate to the underlying queue.
    warn = []
    if args.Wopts and qwopts:
        warn.append('"%s" overrides internal value "%s".'%(args.Wopts, qwopts))
        qwopts = '-W '+args.Wopts
    if ppn and (qppn != ppn):
        warn.append(' Cores %d overrides internal value %d.'%(ppn, qppn))
        qppn = ppn

    if warn:
        print >>sys.stderr, '\n'.join(warn)
else:
    if ppn == None:
        print >>sys.stderr, 'Unrecognized queue "%s". Must specify the --Cores option.'%queue
        sys.exit(1)

if corelimit == None: corelimit = qppn

if queue == 'scavenge':
    print >>sys.stderr, '''\
Keep in mind when submitting to queue "scavenge" that jobs running on
this queue can be pre-empted.  An effort is made to clean up, but it
would be wise to check for run-away processes if this submission does
not run to completion.'''

# We assume that related script lives in the same directory as this script.
myDir = os.path.dirname(os.path.realpath(__file__))+os.path.sep
sqScript = myDir + 'SQDedDriver.py'

# hack to avoid changing template file
group = qwopts
PBSScript = open(myDir + 'SQDedPBSScriptTemplate.py').read()%locals()

print PBSScript
