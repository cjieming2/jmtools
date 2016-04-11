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

void addCNV(TString fileName     = "Fos_snps",
	    TString rootFileName = "NA12878_rd.root",
	    double mean = 89./100)
{
  ifstream in(fileName.Data());
  if (!in) {
    cerr<<"Can't open file '"<<fileName<<"'."<<endl;

  cout<<"JMJM"<<mean<<"\n";
    return;
  }

  TString *lines = new TString[10000000];
  int n_lines = 0;
  char buf[1024];
  while (!in.eof()) {
    in.getline(buf,1024);
    lines[n_lines] = buf;
    if (lines[n_lines].Length() > 0 && buf[0] != '#') n_lines++;
  }
  cout<<"Read "<<n_lines<<" lines."<<endl;

  TString outFileName = fileName;
  outFileName += ".cnv";
  ofstream out(outFileName.Data());
  if (!out) {
    cerr<<"Can't write to file '"<<outFileName<<"'."<<endl;
    return;
  }

  out<<"chrm\tsnppos\trd"<<endl;
  
  TFile file(rootFileName);
  TTree *tree = NULL,*tmp_tree = NULL;
  int position = -1; short rd_parity = 0;
  TString prev_chrom = "",chrom,tmp;
  for (int i = 0;i < n_lines;i++) {
    if ((i + 1)%100 == 0) cout<<(i + 1)<<endl;
    chrom = "";
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
    if (chrom !=  "1" && chrom !=  "2" && chrom !=  "3" &&
    	chrom !=  "4" && chrom !=  "5" && chrom !=  "6" &&
    	chrom !=  "7" && chrom !=  "8" && chrom !=  "9" &&
    	chrom != "10" && chrom != "11" && chrom != "12" &&
    	chrom != "13" && chrom != "14" && chrom != "15" &&
    	chrom != "16" && chrom != "17" && chrom != "18" &&
    	chrom != "19" && chrom != "20" && chrom != "21" &&
    	chrom != "22" && chrom !=  "X" && chrom != "Y") {
      cerr<<"Unknown chromosome '"<<chrom<<"'."<<endl;
      cerr<<"Skipping the following line:"<<endl;
      cerr<<lines[i]<<endl<<endl;
      continue;
    }
    int start = pos - range - 1;
    int end   = pos + range;
    TString name = "chr"; name += chrom;
    if (chrom != prev_chrom) {
      tree = (TTree*)file.Get(name);
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

    double rd = double(count)/mean/(2*range + 1);
    out<<chrom<<"\t"<<pos<<"\t"<<rd<<endl;

    prev_chrom = chrom;
  }
  out.close();
  file.Close();

  delete[] lines;
}

int main(int argc,char *argv[])
{
  for (int i = 1;i < argc;i++)
    addCNV(argv[i],"NA12878.HiSeq.root",89./100);
}
