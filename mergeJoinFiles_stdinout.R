#!/usr/bin/env Rscript

## TO-DO: flags 1, 3, 4 need to be tested before using; especially the colnames are not hardcoded
## this script takes in 4 args: file1 , file2, a flag, and an output filename and does a join (merge) based on the flag
## all while PRESERVING the order of files 1 and 2 for one-sided joins (using keep_order = 1 or 2 respectively)
## and the merge.with.order function
## there is a similarly-named R script in R_codes repo used for testing locally
## NOTE that colnames are hardcoded!
## allows stdin using '-' when piping and stdout by putting 'stdout' in arg4
## flag - 
## 1: inner join
## 2: left outer join (file 1)
## 3: right outer join (file 2)
## 4: outer join (things not merge-able are placed NA)
## http://stackoverflow.com/questions/1299871/how-to-join-merge-data-frames-inner-outer-left-right

# this function works just like merge, only that it adds the option to return the merged data.frame ordered by x (1) or by y (2)
merge.with.order <- function(x,y, ..., sort = T, keep_order)
{
  add.id.column.to.data <- function(DATA)
  {
    data.frame(DATA, id... = seq_len(nrow(DATA)))
  }
  # add.id.column.to.data(data.frame(x = rnorm(5), x2 = rnorm(5)))
  order.by.id...and.remove.it <- function(DATA)
  {
    # gets in a data.frame with the "id..." column.  Orders by it and returns it
    if(!any(colnames(DATA)=="id...")) stop("The function order.by.id...and.remove.it only works with data.frame objects which includes the 'id...' order column")
    
    ss_r <- order(DATA$id...)
    ss_c <- colnames(DATA) != "id..."
    DATA[ss_r, ss_c]
  }
  
  # tmp <- function(x) x==1; 1	# why we must check what to do if it is missing or not...
  # tmp()
  
  if(!missing(keep_order))
  {
    if(keep_order == 1) return(order.by.id...and.remove.it(merge(x=add.id.column.to.data(x),y=y,..., sort = FALSE)))
    if(keep_order == 2) return(order.by.id...and.remove.it(merge(x=x,y=add.id.column.to.data(y),..., sort = FALSE)))
    # if you didn't get "return" by now - issue a warning.
    warning("The function merge.with.order only accepts NULL/1/2 values for the keep_order variable")
  } else {return(merge(x=x,y=y,..., sort = sort))}
}


args = commandArgs(trailingOnly=TRUE)

# test if number of arguments NOT 6: if not, return an error
if (length(args)!=4) {
  stop("Only four arguments can be supplied: file1 file2 flag outputname", call.=FALSE)
}

# can be used with standard input
if (args[1] == "-"){
	input = file('stdin','r')
} else
{
	input = args[1]
}

if (args[2] == "-"){
	input2 = file('stdin','r')
} else
{
	input2 = args[2]
}


# read file1 and file2
data1 = read.delim(input, header = T, sep = "\t", stringsAsFactors = FALSE, na.strings = "")
data2 = read.delim(input2, header = T, sep = "\t", stringsAsFactors = FALSE, na.strings = "")

# merge by flag
if (args[3] == 1)
{
	# inner join
	data12 = merge(data1, data2, by.x = args[2], by.y = args[4])
}else if (args[3] == 2)
{
	# left outer join
	data12 = merge.with.order(data1, data2, by.x = 'CHR.POS1', by.y = 'CHROM.POS', all.x = TRUE, keep_order = 1)
	data123 = merge.with.order(data12, data2, by.x = 'CHR.POS2', by.y = 'CHROM.POS', all.x = TRUE, keep_order = 1)
}else if (args[3] == 3)
{
	# right outer join
  data12 = merge.with.order(data1, data2, by.x = args[2], by.y = args[4], all.y = TRUE, keep_order = 2)
}else if (args[3] == 4)
{
	# outer join
  data12 = merge(data1, data2, by.x = args[2], by.y = args[4], all = TRUE)
}

# output
if(args[4] == "stdout")
{
	write.table(data123, file="", row.names=FALSE, sep = "\t", quote = FALSE)
} else
{
	write.table(data123, file=args[4], row.names=FALSE, sep = "\t", quote = FALSE)
}



