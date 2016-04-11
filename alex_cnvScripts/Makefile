### usage make addRD or make addCNV
### addRD generates the script to generate the input for AlleleSeq
### addCNV adds the last column to the AlleleSeq output
ROOTFLAGS = 	-pthread -m64
ROOTLIBS  = 	-L$(ROOTSYS)/lib -lCore -lCint -lRIO -lNet -lHist -lGraf \
		-lGraf3d -lGpad -lTree -lRint -lPostscript -lMatrix \
		-lPhysics -lMathCore -lThread -lfreetype -pthread -lm -ldl

CXX	 = g++ $(ROOTFLAGS)
INC	 = -I$(ROOTSYS)/include

OBJDIR = obj
OBJS   = $(OBJDIR)/addRD.o \
	 $(OBJDIR)/addCNV.o

all: $1

addRD: $(OBJS)
	$(CXX) -o $@ $(OBJDIR)/$@.o $(ROOTLIBS)

addCNV: $(OBJS)
	$(CXX) -o $@ $(OBJDIR)/$@.o $(ROOTLIBS)

$(OBJDIR)/%.o: %.cpp
	@mkdir -p $(OBJDIR)
	$(CXX) $(INC) -c $< -o $@

clean:
	rm -f $(OBJS)
