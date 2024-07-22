HOST_COMPILER = g++
NVCC = nvcc -ccbin $(HOST_COMPILER)

# select one of these for Debug vs. Release
#NVCC_DBG = -g -G
NVCC_DBG =

NVCCFLAGS = $(NVCC_DBG) -m64
GENCODE_FLAGS = -gencode arch=compute_86,code=sm_86

SRCS = main.cu
CC_SRCS = main.cc

GLFW_CFLAGS = $(shell pkg-config --cflags glfw3)
GLFW_LIBS = $(shell pkg-config --static --libs glfw3)
LIBS = $(GLFW_LIBS) -lGL -lGLEW

# Check if CUDA is available
ifeq ($(shell which nvcc),)
    USE_CUDA := 0
else
    USE_CUDA := 1
endif

# Rules for CUDA build
ifneq ($(USE_CUDA), 0)
all: cudart

cudart: cudart.o
	$(NVCC) $(NVCCFLAGS) $(GENCODE_FLAGS) -o cudart cudart.o $(LIBS)

cudart.o: $(SRCS)
	$(NVCC) $(NVCCFLAGS) $(GENCODE_FLAGS) $(GLFW_CFLAGS) -c main.cu -o cudart.o

out: cudart
	rm -f out.ppm
	./cudart

out.ppm: cudart
	rm -f out.ppm
	./cudart > out.ppm

out.jpg: out.ppm
	rm -f out.jpg
	ppmtojpeg out.ppm > out.jpg

profile_basic: cudart
	nvprof ./cudart > out.ppm

# use nvprof --query-metrics
profile_metrics: cudart
	nvprof --metrics achieved_occupancy,inst_executed,inst_fp_32,inst_fp_64,inst_integer ./cudart > out.ppm

else # Rules for non-CUDA build
all: cppart

cppart: $(CC_SRCS)
	$(HOST_COMPILER) -o cppart $(CC_SRCS) $(LIBS)

out: cppart
	rm -f out.ppm
	./cppart

out.ppm: cppart
	rm -f out.ppm
	./cppart > out.ppm

out.jpg: out.ppm
	rm -f out.jpg
	ppmtojpeg out.ppm > out.jpg
endif

clean:
	rm -f cudart cudart.o cppart out.ppm out.jpg
