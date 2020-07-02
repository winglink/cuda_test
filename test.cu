#include <cuda.h>
#include <iostream>
#include <algorithm>


const int N = 8; 
const int perthreads = 8;
const int blockspergrid =std::min(32, (N + perthreads - 1) / perthreads);

__global__ void addKernel(int *a,int *b, int *c)
{
	__shared__ int cache[perthreads];
	int index = threadIdx.x + blockIdx.x * blockDim.x ;
	//	printf("index=%d\n",index);
	int tmp(0);
	int cacheindex(threadIdx.x);

	while (index < N) {
		tmp += a[index] * b[index];
		index += blockDim.x * gridDim.x;
	}
	cache[cacheindex] = tmp;
		printf("tmp=%d cacheindex=%d\n",tmp,cacheindex);
	__syncthreads();// 每个block中thread数量大于cudacore才需要？
	int fg = perthreads / 2;
	while (fg > 0) {
		if (cacheindex < fg) {
			cache[cacheindex] += cache[cacheindex + fg];
			__syncthreads();
		}
			fg /= 2;
			printf("cache[0]=%d,fg=%d",cache[0],fg);
	}
		printf("end while");
		printf("cache[0]=%d",cache[0]);
		printf("cache[1]=%d",cache[1]);
	if (cacheindex == 0){
		c[blockIdx.x] = cache[cacheindex];
		printf("blockIdx=%d\n",blockIdx.x);
	}
}

int main()
{
	int a[N],b[N],c[blockspergrid];
	for (int i = 0; i < N; i++) {
		a[i] = i;
		b[i] = i;
	}
	std::cout << "11="  << std::endl;

	int* dev_a(0), * dev_b(0), * dev_c(0);
	cudaMalloc((void**) &dev_a,N * sizeof(int));
	cudaMalloc((void**) &dev_b,N * sizeof(int));
	cudaMalloc((void**) &dev_c,blockspergrid * sizeof(int));
	std::cout << "22="  << std::endl;
	
	cudaMemcpy(dev_a, a,N * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_b, b,N * sizeof(int), cudaMemcpyHostToDevice);

	addKernel << <blockspergrid, perthreads>> > (dev_a, dev_b, dev_c);
	std::cout << "33="  << std::endl;
		std::cout << "blockspergird=" << blockspergrid<< std::endl;
	cudaMemcpy(c, dev_c, blockspergrid * sizeof(int),cudaMemcpyDeviceToHost);
	int result(0);
	for (int i = 0; i < blockspergrid; i++) {
		std::cout << "result=" << result << std::endl;
		result += c[i];
	}
	std::cout << "result=" << result << std::endl;
	cudaFree(dev_a);
	cudaFree(dev_b);
	cudaFree(dev_c);
}
