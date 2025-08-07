## USAGE: print_addRDcpp.sh <1> <2>
## <1> = root file e.g. na12878.his.root
## <2> = average read depth per bin size e.g. 89./100

echo "#ifndef __CINT__" > addRD.cpp
echo "" >> addRD.cpp
echo "//--- C/C++ includes ---" >> addRD.cpp
echo "#include <iostream>" >> addRD.cpp
echo "#include <fstream>" >> addRD.cpp
echo "#include <math.h>" >> addRD.cpp
echo "using namespace std;" >> addRD.cpp
echo "" >> addRD.cpp
echo "//--- ROOT includes ---" >> addRD.cpp
echo "#include <TString.h>" >> addRD.cpp
echo "#include <TROOT.h>" >> addRD.cpp
echo "#include <TTree.h>" >> addRD.cpp
echo "#include <TFile.h>" >> addRD.cpp
echo "" >> addRD.cpp
echo "TROOT root(\"Rint\",\"The ROOT Interactive Interface\");" >> addRD.cpp
echo "" >> addRD.cpp
echo "#endif" >> addRD.cpp
echo "" >> addRD.cpp
echo "const static int range = 1000;" >> addRD.cpp
echo "" >> addRD.cpp
echo "void addCNV(TString fileName     = \"Fos_snps_10_1\"," >> addRD.cpp
echo "	    TString rootFileName = \"NA12878_rd.root\"," >> addRD.cpp
echo "	    double mean = 78./100)" >> addRD.cpp
echo "{" >> addRD.cpp
echo "  ifstream in(fileName.Data());" >> addRD.cpp
echo "  if (!in) {" >> addRD.cpp
echo "    cerr<<\"Can't open file '\"<<fileName<<\"'.\"<<endl;" >> addRD.cpp
echo "" >> addRD.cpp
echo "  cout<<\"JMJM\"<<mean<<\"\n\";" >> addRD.cpp
echo "    return;" >> addRD.cpp
echo "  }" >> addRD.cpp
echo "" >> addRD.cpp
echo "  TString *lines = new TString[10000000];" >> addRD.cpp
echo "  int n_lines = 0;" >> addRD.cpp
echo "  char buf[1024];" >> addRD.cpp
echo "  while (!in.eof()) {" >> addRD.cpp
echo "    in.getline(buf,1024);" >> addRD.cpp
echo "    lines[n_lines] = buf;" >> addRD.cpp
echo "    if (lines[n_lines].Length() > 0 && buf[0] != '#') n_lines++;" >> addRD.cpp
echo "  }" >> addRD.cpp
echo "  cout<<\"Read \"<<n_lines<<\" lines.\"<<endl;" >> addRD.cpp
echo "" >> addRD.cpp
echo "  TString outFileName = fileName;" >> addRD.cpp
echo "  outFileName += \".cnv\";" >> addRD.cpp
echo "  ofstream out(outFileName.Data());" >> addRD.cpp
echo "  if (!out) {" >> addRD.cpp
echo "    cerr<<\"Can't write to file '\"<<outFileName<<\"'.\"<<endl;" >> addRD.cpp
echo "    return;" >> addRD.cpp
echo "  }" >> addRD.cpp
echo "" >> addRD.cpp
echo "  out<<\"chrm\tsnppos\trd\"<<endl;" >> addRD.cpp
echo "  " >> addRD.cpp
echo "  TFile file(rootFileName);" >> addRD.cpp
echo "  TTree *tree = NULL,*tmp_tree = NULL;" >> addRD.cpp
echo "  int position = -1; short rd_parity = 0;" >> addRD.cpp
echo "  TString prev_chrom = \"\",chrom,tmp;" >> addRD.cpp
echo "  for (int i = 0;i < n_lines;i++) {" >> addRD.cpp
echo "    if ((i + 1)%100 == 0) cout<<(i + 1)<<endl;" >> addRD.cpp
echo "    chrom = \"\";" >> addRD.cpp
echo "    tmp = \"\";" >> addRD.cpp
echo "    int j = 0,n = lines[i].Length();" >> addRD.cpp
echo "    while (j < n && lines[i][j] != '\t' && lines[i][j] != ' ')" >> addRD.cpp
echo "      chrom += lines[i][j++];" >> addRD.cpp
echo "    while (j < n && (lines[i][j] == '\t' || lines[i][j] == ' ')) j++;" >> addRD.cpp
echo "    while (j < n && lines[i][j] != '\t' && lines[i][j] != ' ')" >> addRD.cpp
echo "      tmp   += lines[i][j++];" >> addRD.cpp
echo "    if (!tmp.IsDigit()) {" >> addRD.cpp
echo "      cerr<<\"Non-numerical position '\"<<tmp<<\"'.\"<<endl;" >> addRD.cpp
echo "      cerr<<\"Skipping the following line:\"<<endl;" >> addRD.cpp
echo "      cerr<<lines[i]<<endl<<endl;" >> addRD.cpp
echo "      continue;" >> addRD.cpp
echo "    }" >> addRD.cpp
echo "    int pos = tmp.Atoi();" >> addRD.cpp
echo "    //cout<<chrom<<\" \"<<pos<<endl;" >> addRD.cpp
echo "    if (chrom !=  \"1\" && chrom !=  \"2\" && chrom !=  \"3\" &&" >> addRD.cpp
echo "    	chrom !=  \"4\" && chrom !=  \"5\" && chrom !=  \"6\" &&" >> addRD.cpp
echo "    	chrom !=  \"7\" && chrom !=  \"8\" && chrom !=  \"9\" &&" >> addRD.cpp
echo "    	chrom != \"10\" && chrom != \"11\" && chrom != \"12\" &&" >> addRD.cpp
echo "    	chrom != \"13\" && chrom != \"14\" && chrom != \"15\" &&" >> addRD.cpp
echo "    	chrom != \"16\" && chrom != \"17\" && chrom != \"18\" &&" >> addRD.cpp
echo "    	chrom != \"19\" && chrom != \"20\" && chrom != \"21\" &&" >> addRD.cpp
echo "    	chrom != \"22\" && chrom !=  \"X\" && chrom != \"Y\") {" >> addRD.cpp
echo "      cerr<<\"Unknown chromosome '\"<<chrom<<\"'.\"<<endl;" >> addRD.cpp
echo "      cerr<<\"Skipping the following line:\"<<endl;" >> addRD.cpp
echo "      cerr<<lines[i]<<endl<<endl;" >> addRD.cpp
echo "      continue;" >> addRD.cpp
echo "    }" >> addRD.cpp
echo "    int start = pos - range - 1;" >> addRD.cpp
echo "    int end   = pos + range;" >> addRD.cpp
echo "    TString name = \"chr\"; name += chrom;" >> addRD.cpp
echo "    if (chrom != prev_chrom) {" >> addRD.cpp
echo "      tree = (TTree*)file.Get(name);" >> addRD.cpp
echo "      if (tree) {" >> addRD.cpp
echo "	tree->SetBranchAddress(\"position\", &position);" >> addRD.cpp
echo "	tree->SetBranchAddress(\"rd_parity\",&rd_parity);" >> addRD.cpp
echo "      }" >> addRD.cpp
echo "    }" >> addRD.cpp
echo "" >> addRD.cpp
echo "    if (!tree) {" >> addRD.cpp
echo "      cerr<<\"Can't find tree for chromosome '\"<<chrom<<\"'.\"<<endl;" >> addRD.cpp
echo "      cerr<<\"Skipping the following line:\"<<endl;" >> addRD.cpp
echo "      cerr<<lines[i]<<endl<<endl;" >> addRD.cpp
echo "      continue;" >> addRD.cpp
echo "    }" >> addRD.cpp
echo "" >> addRD.cpp
echo "    int n_ent = tree->GetEntries(),count = 0,index = 0;" >> addRD.cpp
echo "    position = 0;" >> addRD.cpp
echo "    int step = start/2;" >> addRD.cpp
echo "    while (step > 1) {" >> addRD.cpp
echo "      tree->GetEntry(index);" >> addRD.cpp
echo "      while (index < n_ent && position < start) {" >> addRD.cpp
echo "	index += step;" >> addRD.cpp
echo "	tree->GetEntry(index);" >> addRD.cpp
echo "      }" >> addRD.cpp
echo "      index -= step;" >> addRD.cpp
echo "      if (index < 0) index = 0;" >> addRD.cpp
echo "      step /= 2;" >> addRD.cpp
echo "    }" >> addRD.cpp
echo "" >> addRD.cpp
echo "    //cout<<\"Start index \"<<index<<endl;" >> addRD.cpp
echo "    position = 0;" >> addRD.cpp
echo "    while (index < n_ent && position <= end) {" >> addRD.cpp
echo "      tree->GetEntry(index++);" >> addRD.cpp
echo "      if (position >= start && position <= end) count += rd_parity;" >> addRD.cpp
echo "    }" >> addRD.cpp
echo "    //cout<<\"End index \"<<index<<endl;" >> addRD.cpp
echo "" >> addRD.cpp
echo "    double rd = double(count)/mean/(2*range + 1);" >> addRD.cpp
echo "    out<<chrom<<\"\t\"<<pos<<\"\t\"<<rd<<endl;" >> addRD.cpp
echo "" >> addRD.cpp
echo "    prev_chrom = chrom;" >> addRD.cpp
echo "  }" >> addRD.cpp
echo "  out.close();" >> addRD.cpp
echo "  file.Close();" >> addRD.cpp
echo "" >> addRD.cpp
echo "  delete[] lines;" >> addRD.cpp
echo "}" >> addRD.cpp
echo "" >> addRD.cpp
echo "int main(int argc,char *argv[])" >> addRD.cpp
echo "{" >> addRD.cpp
echo "  for (int i = 1;i < argc;i++)" >> addRD.cpp
echo "    addCNV(argv[i],\"$1\",$2);" >> addRD.cpp
echo "}" >> addRD.cpp
