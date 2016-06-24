#TG: setwd("C:/Users/Jieming/Documents/thesis/mark_work/allele_specificity/overdispersion_read depth")
#TG: library(VGAM)
library(VGAM, lib.loc="/gpfs/home/fas/gerstein/tg397/Rpackages")
#TG: sys args
args<-commandArgs(TRUE)


## weighted beta/binomial distribution
# d.combined collects all results and correspond it to an allelic ratio:
# col1=allelicRatio (based on binomial n=6, ar=0,1/6,2/6...)
# col2=corresponding weighted value in binomial distribution, i.e. pdf(n,k,p)*(num of empirical SNPs at n counts)
nulldistrib <- function(minN,maxN,p,w,binSize,yuplimit,distrib="binomial",b=0)
{
  d.combined = matrix(0,sum(seq(minN+1,maxN+1)),2)
  ptr = 1
  
  for (i in minN:maxN)
  {  
    ## doing the distribution
    k=seq(0,i)
    
    if(distrib == "binomial")
    {
      d = dbinom(k,i,p) ## binomial
    }
    else if(distrib == "betabinomial")
    {
      d = dbetabinom(k,i,p,b)
    }
    
    ## weight each with actual counts in empirical
    d.w = d*w[i,1]
    
    if(i == minN)
    {
      d.combined[ptr:length(k),1] = k/i
      d.combined[ptr:length(k),2] = d.w
      colnames(d.combined) = c('allelicRatio','wBinDist')
    }
    else
    {
      d.combined[ptr:(ptr+length(k)-1),1] = k/i
      d.combined[ptr:(ptr+length(k)-1),2] = d.w
    }
    
    ptr = ptr + length(k)
  }

  ## sort the d.combined distribution of all the n's
  d.combined.sorted = d.combined[ order(d.combined[,1],d.combined[,2]), ]
  
  ## bin it according to empirical distribution
  bins=pretty(0:1,binSize)
  start=0
  end=0
  
  d.combined.sorted.binned = matrix(0,length(bins)-1,2)
  
  for (z in 2:length(bins)) ##skip 0
  {
    start=bins[z-1]
    end=bins[z]
    
    row=z-1
    d.combined.sorted.binned[row,1] = (end-start)/2 +start ## equi of a $mid in hist
    
    d.combined.sorted.binned[row,2] = sum(d.combined.sorted[(d.combined.sorted[,1]<=end & 
                                                               d.combined.sorted[,1]>start),2])
    ## empirical right closed, left open ?hist; right=TRUE
    ## (range] so no double counts
    ## but zero gets excluded!!
    if(row==1)
    {
      d.combined.sorted.binned[row,2] = sum(d.combined.sorted[(d.combined.sorted[,1]<=end & 
                                                                 d.combined.sorted[,1]>=start),2])
    }
    
    ## empirical right closed, left open ?hist; right=TRUE
    ## (range] so no double counts
    ## but zero gets excluded!!
    if(row==1)
    {
      d.combined.sorted.binned[row,2] = sum(d.combined.sorted[(d.combined.sorted[,1]<=end & 
                                                                 d.combined.sorted[,1]>=start),2])
    }
    
  }
  
  ## change "counts" into density
  d.combined.sorted.binned[,2] = d.combined.sorted.binned[,2]/sum(d.combined.sorted.binned[,2])
  
  return(d.combined.sorted.binned)
}


#TG: RK's functions to calculate cALT and cREF (to use cALT instead of cA+cC+cG+cT):
##
## Compute alt/ref counts
##
iupac = matrix(c(c("R","A","G"), c("Y","C","T"), c("S","G","C"), c("W","A","T"), c("K","G","T"), c("M","A","C")), ncol=3,byrow=T)
getCounts = function(line, columnNames){
  bases = iupac[iupac[,1] %in% line[6], -1]
  ref = bases %in% line[3]
  ref.count = line[columnNames %in% paste("c",bases[ref],sep="")]
  alt.count = line[columnNames %in% paste("c",bases[!ref],sep="")]
  return(c(ref.count, alt.count))
}
countAllHets = function(input){
  hetCounts = data.matrix(as.data.frame(t(apply(input, 1, getCounts, colnames(input))), stringsAsFactors=F))
  colnames(hetCounts) = c("cREF","cALT")
  return(hetCounts)
}


################################## MAIN #######################################
### set parameters
# filename = "counts.peaks.min6.allelicRatio.mod.auto.NA12878.Sin3Ak.txt"
# filename = "counts.min6.allelicRatio.mod.auto.NA12878.rnaseq.txt"
#TG: filename = "counts.peaks.min6.allelicRatio.mod.auto.NA11830.PU1.txt"
#filename='counts.txt'
filename=args[1]
data = read.table(filename, header=T, stringsAsFactors=F)

#TG:
data<-data.frame("total"=countAllHets(data)[,1]+countAllHets(data)[,2], "allelicRatio"= countAllHets(data)[,1]/(countAllHets(data)[,1]+countAllHets(data)[,2]))


#TG: dir.create("betabinomial")
dir.create(args[2])
#TG: setwd("C:/Users/Jieming/Documents/thesis/mark_work/allele_specificity/overdispersion_read depth/betabinomial")
setwd(args[2])


colors <- c("green","orange","cyan","pink","purple",
            "brown","black","slategray1","violetred","tan","deeppink","darkgreen", 
            "orchid","darksalmon","antiquewhite3","magenta","darkblue","peru","slateblue",
            "thistle","tomato","rosybrown1","royalblue","olivedrab") ##Set of 26 colours (no red) to use for all plots

## binomial parameters
p=0.5               #null probability
minN=6             #min total num of reads (since it's left open right closed)
# maxN=max(data$total) #max total num of reads
if(max(data$total) < 2500){ maxN=max(data$total) }else { maxN=2500 }
apropor = length(data$total[data$total <= 2500]) / nrow(data)
yuplimit=0.15
binSize=40
bins=pretty(0:1,binSize)
r.min = 0
r.max = 1

## graded weights for SSE calculation
numzeros = 2
r = seq(r.min,r.max,(r.max - r.min)/((length(bins) - 1)/2))
r = r[2:length(r)]
if((length(bins)-1)%%2 != 0)
{ 
  print("HEY1")
  w.grad=c(r,sort(r[1:(length(r)-1)],decreasing=TRUE)) 
#   w.grad=c(0,0,0,0,0,matrix(1,40),0,0,0,0,0)
}else 
{ 
  w.grad=c(r,sort(r[1:length(r)],decreasing=TRUE)) 
  print("HEY2")
#   w.grad=c(0,0,0,0,0,matrix(1,40),0,0,0,0,0)
}



## empirical allelic Ratio
data.match=data[data$total <= maxN & data$total >= minN, ]
h = hist(data.match$allelicRatio, xlim=range(0,1),breaks=bins,right=TRUE)
# h = hist(data.match$allelicRatio, xlim=range(0,1),breaks=bins,right=FALSE)
# plot right closed interval left open (range] for x axis
# note that you have pseudozeroes as counts in your data so thats fine
empirical = h$counts/sum(h$counts)

### weighted expected binomial 
## plot the binomial distribution for each n
## dbinom(seq(0,500),n=500,p=0.5) gives the pdf of 0-500, at n=500, p=0.5 in binomial distrib
## weight each probability by the number of SNPs with n reads

# weight by empirical counts
t = as.data.frame(table(data$total), stringsAsFactors=F)
w = matrix(0,max(data$total),1)

for (jj in 1:nrow(t))
{
  w[as.integer(t[jj,1]),1] = t[jj,2]
}

d.combined.sorted.binned = nulldistrib(minN,maxN,p,w,binSize,yuplimit,distrib="binomial")

### weighted betabinomial distribution
# very naive way of automating the process of finding b parameter automatically
# using least sum of squares of errors (between the density plots of empirical and 
# the expected distributions)
r.sta = 0
r.end = 0.99
r.by  = 0.1
b.range = seq(r.sta,r.end,by=r.by)
labels = matrix(0,200,1)
ctr = 1
sse = sum((empirical-d.combined.sorted.binned[,2])^2)
b.choice = 0
b.and.sse = matrix(0,200,2)
colnames(b.and.sse) <- c('b','sse')

for (k in b.range)
{
  e.combined.sorted.binned = nulldistrib(minN,maxN,p,w,binSize,yuplimit,distrib="betabinomial",b=k)
#   par(new=TRUE)
#   plot(e.combined.sorted.binned,ylim=c(0,yuplimit),pch=16,type='b',col=colors[ctr],bty='n',ylab='',xlab='',yaxt='n',xaxt='n',yaxs="i")
  
  ## minimize sse for betabinomials
  if(b.choice==0){ b.and.sse[1,1]=b.choice; b.and.sse[1,2]=sse }
  se.bbin = (empirical-e.combined.sorted.binned[,2])^2
  sse.bbin = sum(w.grad*((empirical-e.combined.sorted.binned[,2])^2))
  b.and.sse[ctr+1,1] = k
  b.and.sse[ctr+1,2] = sse.bbin
  labels[ctr] = paste("betabin,b=",signif(k,2),"; SSE=",signif(sse.bbin,2))
  
  if(sse.bbin < sse){ sse = sse.bbin; b.choice = k }
  else if(sse.bbin > sse){ break }
  
  ctr = ctr + 1
}
# print(paste("b.chosen=",b.choice,", SSE.chosen=",sse))

# legend(0.01,0.14,c("empirical","binomial",
#                    labels[1:ctr]),
#        col=c("grey","red",colors[1:ctr]), cex=2, pt.cex=2,
#        text.col = "black", pch = 15, bg = 'white')

# dev.copy2pdf(file = paste("allele_readdepth_table_betabinomial_distribution_compare_NA10847_sa1",minN,"-",maxN,".pdf", sep=""))

##################################################################################
# sum of squares
# after picking b.choice with the sse, use a bisection idea to optimize 
# b.choice
ctr.ori = ctr             ##debug
b.and.sse.ori = b.and.sse ##debug

# x11()
# par(cex.axis=1.5, cex.lab=2, cex.main=2, mar=c(5,5,5,5))
# plot(b.and.sse[1:(ctr+1),],type='b',pch=16)

b.chosen = b.choice
sse.chosen = sse
flag = 3

if(b.chosen >= 0.9){flag = 0; newctr = ctr}
  
while(flag)
{
  r.sta = max(0,(b.choice - r.by/2))
  r.end = b.choice + r.by/2
  r.by  = r.by/4
  b.range = seq(r.sta,r.end,by=r.by)
  labels = matrix(0,200,1)
  newctr = 1
  sse = b.and.sse[1,2]
  b.choice = 0

  for (k in b.range)
  {
    e.combined.sorted.binned = nulldistrib(minN,maxN,p,w,binSize,yuplimit,distrib="betabinomial",b=k)
  
    ## minimize sse for betabinomials
    sse.bbin = sum(w.grad*((empirical-e.combined.sorted.binned[,2])^2))
    b.and.sse[(ctr+2),1] = k
    b.and.sse[(ctr+2),2] = sse.bbin
    labels[newctr] = paste("betabin,b=",signif(k,3),"; SSE=",signif(sse.bbin,3))
    
    if(sse.bbin < sse){ sse = sse.bbin; b.choice = k }
    else if(sse.bbin > sse){ break }
    
    ctr = ctr + 1
    newctr = newctr + 1
  }
  print(paste("b.chosen=",b.choice,", SSE.chosen=",sse))
  print(ctr) ## debug
  print(flag) ## debug
  
  labels = labels[1:(newctr+1),]
  
  if(signif(b.and.sse[ctr+2,2],3) == signif(b.and.sse[ctr+1,2],3)){ flag = 0 }
}


## print empirical, binomial and betabinomial fit
# x11(width=17, height=9)
pdf(paste(filename,"-checkgrad-",minN,"-",maxN,".pdf", sep=""),width=17, height=9)
par(cex.axis=1.5, cex.lab=2, cex.main=2, mar=c(5,5,5,5))
barplot(empirical, ylab='density', xlab='allelicRatio', 
        names.arg=h$mids, ylim=c(0,yuplimit), main=paste("n=",minN,'-',maxN))
par(new=TRUE)
plot(d.combined.sorted.binned,ylim=c(0,yuplimit),pch=16,type='b',col='red',
     bty='n',ylab='',xlab='',yaxt='n',xaxt='n',yaxs="i")
par(new=TRUE)
plot(e.combined.sorted.binned,ylim=c(0,yuplimit),pch=16,type='b',col='blue',
     bty='n',ylab='',xlab='',yaxt='n',xaxt='n',yaxs="i")

legend(0.01,0.14,c("empirical","binomial",
                   labels[1:(newctr-1)]),
       col=c("grey","red","blue"), cex=2, pt.cex=2,
       text.col = "black", pch = 15, bg = 'white')
# dev.copy2pdf(file = paste(filename,"-check-",minN,"-",maxN,".pdf", sep=""))
dev.off()

## print sse
# x11(width=10, height=7)
pdf(paste(filename,"-checksse.grad-",minN,"-",maxN,".pdf", sep=""), width=10, height=7)
par(cex.axis=1.5, cex.lab=2, cex.main=2, mar=c(5,5,5,5))
b.and.sse = b.and.sse[1:(ctr+2),]
plot(b.and.sse[order(b.and.sse[,1]),],type='b',
     pch=16,xlim=c(min(b.and.sse[,1]), max(b.and.sse[,1])),
     ylim=c(min(b.and.sse[,2]), max(b.and.sse[,2])))
par(new=TRUE)
par(cex.axis=1.5, cex.lab=2, cex.main=2, mar=c(5,5,5,5))
plot(b.choice,sse,bty='n',ylab='',xlab='',yaxt='n',xaxt='n',
     col='red',pch=8,xlim=c(min(b.and.sse[,1]), max(b.and.sse[,1])),
     ylim=c(min(b.and.sse[,2]), max(b.and.sse[,2])))
text(b.choice,sse+(r.by*2),paste("b.chosen=",signif(b.choice,3),"\nSSE.chosen=",signif(sse,3)),cex=1.5)
# dev.copy2pdf(file = paste(filename,"-checksse-",minN,"-",maxN,".pdf", sep=""))
dev.off()

## print to files 
write.table(b.and.sse,"b_and_sse.grad.txt", row.names=FALSE, sep="\t")
write.table(cbind(maxN,apropor),"percentageOfData.grad.txt", row.names=FALSE, sep="\t")
write.table(cbind(b.choice,sse),"b_chosen.grad.txt", row.names=FALSE,sep="\t")
