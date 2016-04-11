#ifndef __CINT__

//--- C/C++ includes ---
#include <iostream>
#include <fstream>
#include <math.h>
using namespace std;

//--- ROOT includes ---
#include <TString.h>
#include <TROOT.h>
#include <TTree.h>
#include <TFile.h>

TROOT root("Rint","The ROOT Interactive Interface");

#endif

const static int range = 1000;

void addCNV(TString fileName     = "Fos_snps_10_1",
	    TString rootFileName = "NA12878_rd.root",
	    double mean = 78./100)
{
  ifstream in(fileName.Data());
  if (!in) {
    cerr<<"Can't open file '"<<fileName<<"'."<<endl;
    return;
  }

  TString lines[100000];
  int n_lines = 0;
  char buf[1024];
  while (!in.eof()) {
    in.getline(buf,1024);
    //lines[n_lines] = new TString(buf);
    lines[n_lines] = buf;
    if (lines[n_lines].Length() > 0) n_lines++;
  }
  cout<<"Read "<<n_lines<<" lines."<<endl;
  
  TString outFileName = fileName;
  outFileName += ".cnv";
  ofstream out(outFileName.Data());
  if (!out) {
    cerr<<"Can't write to file '"<<outFileName<<"'."<<endl;
    return;
  }
  
  TFile file(rootFileName);
  TTree *tree = NULL,*tmp_tree = NULL;
  int position = -1; short rd_parity = 0;
  TString prev_chrom = "",chrom,tmp;
  out<<lines[0]<<"\tcnv"<<endl;
  for (int i = 1;i < n_lines;i++) {
    if ((i + 1)%100 == 0) cout<<(i + 1)<<endl;
    chrom = "chr";
    tmp = "";
    int j = 0,n = lines[i].Length();
    while (j < n && lines[i][j] != '\t' && lines[i][j] != ' ')
      chrom += lines[i][j++];
    while (j < n && (lines[i][j] == '\t' || lines[i][j] == ' ')) j++;
    while (j < n && lines[i][j] != '\t' && lines[i][j] != ' ')
      tmp   += lines[i][j++];
    if (!tmp.IsDigit()) {
      cerr<<"Non-numerical position '"<<tmp<<"'."<<endl;
      cerr<<"Skipping the following line:"<<endl;
      cerr<<lines[i]<<endl<<endl;
      continue;
    }
    int pos = tmp.Atoi();
    //cout<<chrom<<" "<<pos<<endl;
    if (chrom !=  "chr1" && chrom !=  "chr2" && chrom !=  "chr3" &&
    	chrom !=  "chr4" && chrom !=  "chr5" && chrom !=  "chr6" &&
    	chrom !=  "chr7" && chrom !=  "chr8" &&	chrom !=  "chr9" &&
    	chrom != "chr10" && chrom != "chr11" && chrom != "chr12" &&
    	chrom != "chr13" && chrom != "chr14" && chrom != "chr15" &&
    	chrom != "chr16" && chrom != "chr17" && chrom != "chr18" &&
    	chrom != "chr19" && chrom != "chr20" &&	chrom != "chr21" &&
    	chrom != "chr22" && chrom !=  "chrX" && chrom != "chrY") {
      cerr<<"Unknown chromosome '"<<chrom<<"'."<<endl;
      cerr<<"Skipping the following line:"<<endl;
      cerr<<lines[i]<<endl<<endl;
      continue;
    }
    int start = pos - range - 1;
    int end   = pos + range;
    if (chrom != prev_chrom) {
      tree = (TTree*)file.Get(chrom);
      if (tree) {
	tree->SetBranchAddress("position", &position);
	tree->SetBranchAddress("rd_parity",&rd_parity);
      }
    }

    if (!tree) {
      cerr<<"Can't find tree for chromosome '"<<chrom<<"'."<<endl;
      cerr<<"Skipping the following line:"<<endl;
      cerr<<lines[i]<<endl<<endl;
      continue;
    }

    int n_ent = tree->GetEntries(),count = 0,index = 0;
    position = 0;
    int step = start/2;
    while (step > 1) {
      tree->GetEntry(index);
      while (index < n_ent && position < start) {
	index += step;
	tree->GetEntry(index);
      }
      index -= step;
      if (index < 0) index = 0;
      step /= 2;
    }

    //cout<<"Start index "<<index<<endl;
    position = 0;
    while (index < n_ent && position <= end) {
      tree->GetEntry(index++);
      if (position >= start && position <= end) count += rd_parity;
    }
    //cout<<"End index "<<index<<endl;

    lines[i] += '\t';
    lines[i] += double(count)/mean/(2*range + 1);

    out<<lines[i]<<endl;
    
    prev_chrom = chrom;
  }
  out.close();
  file.Close();
}

int main(int argc,char *argv[])
{
  for (int i = 1;i < argc;i++)
    addCNV(argv[i],"NA12878.HiSeq.root",89./100);
}
